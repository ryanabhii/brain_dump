import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;

import 'merge.dart';
import 'remote_store.dart';

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

  DriveRemoteStore(this._apiProvider);

  String _fileName(String tab) => 'tracker_$tab.json';

  Future<drive.File?> _find(drive.DriveApi api, String tab) async {
    final res = await api.files.list(
      q: "appProperties has { key='$_propKey' and value='$tab' } and trashed=false",
      $fields: 'files(id,capabilities/canEdit)',
      spaces: 'drive',
    );
    final files = res.files;
    return (files != null && files.isNotEmpty) ? files.first : null;
  }

  Future<drive.File> _ensure(drive.DriveApi api, String tab) async {
    final existing = await _find(api, tab);
    if (existing != null) return existing;
    final bytes = utf8.encode(jsonEncode(<String, List<Json>>{}));
    final file = drive.File()
      ..name = _fileName(tab)
      ..appProperties = {_propKey: tab};
    return api.files.create(
      file,
      uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
      $fields: 'id,capabilities/canEdit',
    );
  }

  @override
  Future<Map<String, SyncRole>> accessibleTabs() async {
    final api = await _apiProvider();
    if (api == null) return const {};
    final res = await api.files.list(
      q: "appProperties has { key='$_propKey' } and trashed=false",
      $fields: 'files(id,appProperties,capabilities/canEdit)',
      spaces: 'drive',
    );
    final out = <String, SyncRole>{};
    for (final f in res.files ?? const <drive.File>[]) {
      final tab = f.appProperties?[_propKey];
      if (tab == null) continue;
      out[tab] = (f.capabilities?.canEdit ?? false)
          ? SyncRole.editor
          : SyncRole.viewer;
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
    if (id == null) return null;
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
      final file = drive.File()
        ..name = _fileName(tabKey)
        ..appProperties = {_propKey: tabKey};
      await api.files.create(file, uploadMedia: media);
    } else {
      await api.files.update(drive.File(), id, uploadMedia: media);
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
