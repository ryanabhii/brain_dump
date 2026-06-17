import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;

import 'merge.dart';
import 'remote_store.dart';
import 'sync_tabs.dart';

/// Thrown when an upload races another device: the remote file's
/// `headRevisionId` changed between download and upload, so this side's merge
/// would clobber a concurrent write. The engine catches this so the next sync
/// pass re-downloads + re-merges instead of overwriting.
class ConcurrentModificationError implements Exception {
  final String tabKey;
  ConcurrentModificationError(this.tabKey);
  @override
  String toString() =>
      'ConcurrentModificationError: remote changed for tab "$tabKey" — '
      'will retry on next sync';
}

/// Backend-free multi-user sync over Google Drive: one JSON file per tab,
/// tagged with an `appProperties` marker, living in the user's normal Drive so
/// it can be shared. Sharing a tab = a Drive permission on its file (reader →
/// viewer, writer → editor) — Drive's own ACL is our per-tab/per-person model.
///
/// Needs the full `drive` scope (a file shared *to* you isn't visible under the
/// narrow `drive.file` scope). Fine in an OAuth app kept in Testing mode.
class DriveRemoteStore implements RemoteStore {
  static const _propKey = 'utrackerTab'; // appProperties marker → tab key

  /// Supplies an authorized Drive client (null when signed out).
  final Future<drive.DriveApi?> Function() _apiProvider;

  /// Last `headRevisionId` observed for each tab's file (set by [download],
  /// checked by [upload]). Lets us detect another device writing between our
  /// download → merge → upload window — see [ConcurrentModificationError].
  final Map<String, String> _lastSeenRevision = {};

  DriveRemoteStore(this._apiProvider);

  String _fileName(String tab) => 'tracker_$tab.json';

  /// Find this tab's file. If multiple devices first-synced concurrently they
  /// can each create one — keep the most recently modified and trash the rest
  /// so subsequent calls are deterministic.
  Future<drive.File?> _find(drive.DriveApi api, String tab) async {
    final res = await api.files.list(
      q: "appProperties has { key='$_propKey' and value='$tab' } and trashed=false",
      $fields:
          'files(id,modifiedTime,headRevisionId,capabilities(canEdit))',
      orderBy: 'modifiedTime desc',
      spaces: 'drive',
    );
    final files = res.files;
    if (files == null || files.isEmpty) return null;
    if (files.length > 1) {
      // Trash the duplicates (keep [0] — the newest by modifiedTime). Best
      // effort: failing to trash one shouldn't block the sync.
      for (final dup in files.skip(1)) {
        if (dup.id == null) continue;
        try {
          await api.files.update(
            drive.File()..trashed = true,
            dup.id!,
          );
        } catch (_) {
          // ignore — another device may already be deleting it.
        }
      }
    }
    return files.first;
  }

  Future<drive.File> _ensure(drive.DriveApi api, String tab) async {
    final existing = await _find(api, tab);
    if (existing != null) return existing;
    final bytes = utf8.encode(jsonEncode(<String, List<Json>>{}));
    final file = drive.File()
      ..name = _fileName(tab)
      ..appProperties = {_propKey: tab};
    final created = await api.files.create(
      file,
      uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
      $fields: 'id,headRevisionId,capabilities(canEdit)',
    );
    // A concurrent first-sync on another device may have created its own
    // file between our `_find` and `create`. Re-find now that the dust has
    // settled so the dedupe in [_find] picks one canonical winner.
    return await _find(api, tab) ?? created;
  }

  @override
  Future<Map<String, SyncRole>> accessibleTabs() async {
    final api = await _apiProvider();
    if (api == null) return const {};
    // Drive API requires both key AND value in appProperties queries — querying
    // by key alone is not supported and returns 400 Invalid Value. We query
    // each tab declared in [kSyncTabs] individually and merge the results so
    // the source of truth lives in one place (sync_tabs.dart).
    final out = <String, SyncRole>{};
    for (final tab in kSyncTabs) {
      final res = await api.files.list(
        q: "appProperties has { key='$_propKey' and value='${tab.key}' } and trashed=false",
        $fields: 'files(id,appProperties,capabilities(canEdit))',
        spaces: 'drive',
      );
      for (final f in res.files ?? const <drive.File>[]) {
        final t = f.appProperties?[_propKey];
        if (t == null) continue;
        out[t] = (f.capabilities?.canEdit ?? false)
            ? SyncRole.editor
            : SyncRole.viewer;
      }
    }
    return out;
  }

  @override
  Future<void> enable(String tabKey) async {
    final api = await _apiProvider();
    if (api == null) throw StateError('Not signed in');
    await _ensure(api, tabKey);
  }

  @override
  Future<Map<String, List<Json>>?> download(String tabKey) async {
    final api = await _apiProvider();
    if (api == null) return null;
    final f = await _find(api, tabKey);
    final id = f?.id;
    if (id == null) {
      _lastSeenRevision.remove(tabKey);
      return null;
    }
    // Stash the revision we're about to base our merge on so [upload] can
    // detect a concurrent write from another device.
    if (f?.headRevisionId != null) {
      _lastSeenRevision[tabKey] = f!.headRevisionId!;
    } else {
      _lastSeenRevision.remove(tabKey);
    }
    final media =
        await api.files.get(
              id,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    if (bytes.isEmpty) return <String, List<Json>>{};
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(k, (v as List).map((e) => e as Json).toList()),
    );
  }

  @override
  Future<void> upload(String tabKey, Map<String, List<Json>> data) async {
    final api = await _apiProvider();
    if (api == null) throw StateError('Not signed in');
    final bytes = utf8.encode(jsonEncode(data));
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final existing = await _find(api, tabKey);
    final id = existing?.id;
    if (id == null) {
      // First write: create the file. Concurrent first-sync on two devices is
      // handled by [_ensure]'s post-create dedupe, but [upload] takes the
      // simple path here — `accessibleTabs` is what users go through to bring
      // a tab online, and it routes through [enable] / [_ensure].
      final file = drive.File()
        ..name = _fileName(tabKey)
        ..appProperties = {_propKey: tabKey};
      final created = await api.files.create(
        file,
        uploadMedia: media,
        $fields: 'id,headRevisionId',
      );
      if (created.headRevisionId != null) {
        _lastSeenRevision[tabKey] = created.headRevisionId!;
      }
      return;
    }
    // Optimistic concurrency: refuse the overwrite if the file's
    // `headRevisionId` no longer matches what we saw at download time.
    // Narrows (doesn't eliminate) the TOCTOU window — combined with the
    // sync engine's backoff + re-merge, the next pass will reconcile.
    final expected = _lastSeenRevision[tabKey];
    if (expected != null && existing!.headRevisionId != null &&
        existing.headRevisionId != expected) {
      throw ConcurrentModificationError(tabKey);
    }
    final updated = await api.files.update(
      drive.File(),
      id,
      uploadMedia: media,
      $fields: 'id,headRevisionId',
    );
    if (updated.headRevisionId != null) {
      _lastSeenRevision[tabKey] = updated.headRevisionId!;
    }
  }

  @override
  Future<void> share(String tabKey, String email, SyncRole role) async {
    if (role == SyncRole.none) return;
    final api = await _apiProvider();
    if (api == null) throw StateError('Not signed in');
    final file = await _ensure(api, tabKey);
    final perm = drive.Permission()
      ..type = 'user'
      ..role = role == SyncRole.editor ? 'writer' : 'reader'
      ..emailAddress = email;
    await api.permissions.create(perm, file.id!, sendNotificationEmail: true);
  }

  @override
  Future<List<Collaborator>> collaborators(String tabKey) async {
    final api = await _apiProvider();
    if (api == null) return const [];
    final f = await _find(api, tabKey);
    final id = f?.id;
    if (id == null) return const [];
    final res = await api.permissions.list(
      id,
      $fields: 'permissions(id,emailAddress,role,type)',
    );
    final out = <Collaborator>[];
    for (final p in res.permissions ?? const <drive.Permission>[]) {
      if (p.type != 'user' || p.id == null) continue;
      final isOwner = p.role == 'owner';
      out.add(
        Collaborator(
          permissionId: p.id!,
          email: p.emailAddress ?? '(unknown)',
          role: p.role == 'writer' || isOwner
              ? SyncRole.editor
              : SyncRole.viewer,
          isOwner: isOwner,
        ),
      );
    }
    return out;
  }

  @override
  Future<void> setRole(
    String tabKey,
    String permissionId,
    SyncRole role,
  ) async {
    final api = await _apiProvider();
    if (api == null) throw StateError('Not signed in');
    final f = await _find(api, tabKey);
    if (f?.id == null) return;
    final perm = drive.Permission()
      ..role = role == SyncRole.editor ? 'writer' : 'reader';
    await api.permissions.update(perm, f!.id!, permissionId);
  }

  @override
  Future<void> revoke(String tabKey, String permissionId) async {
    final api = await _apiProvider();
    if (api == null) throw StateError('Not signed in');
    final f = await _find(api, tabKey);
    if (f?.id == null) return;
    await api.permissions.delete(f!.id!, permissionId);
  }
}
