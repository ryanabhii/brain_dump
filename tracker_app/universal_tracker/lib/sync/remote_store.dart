import 'dart:convert';

import 'merge.dart';

/// A collaborator's access level on a tab (mirrors Drive's reader/writer).
enum SyncRole { none, viewer, editor }

/// A person with access to a tab's file (one Drive permission).
class Collaborator {
  final String permissionId;
  final String email;
  final SyncRole role; // editor (writer) or viewer (reader)
  final bool isOwner; // the owner can't be re-roled or removed

  const Collaborator({
    required this.permissionId,
    required this.email,
    required this.role,
    this.isOwner = false,
  });
}

/// The transport behind sync: read/write a tab's collections and manage who can
/// see them. Drive is one implementation; [FakeRemoteStore] backs tests so the
/// whole pipeline is exercisable offline.
abstract class RemoteStore {
  /// Tabs this account can currently access, with the role it has on each.
  Future<Map<String, SyncRole>> accessibleTabs();

  /// Start syncing a tab you own: ensure its remote file exists (so it shows up
  /// in [accessibleTabs] as editor) without sharing it with anyone yet.
  Future<void> enable(String tabKey);

  /// Download a tab's collections, or null if no remote copy exists yet.
  Future<Map<String, List<Json>>?> download(String tabKey);

  /// Overwrite a tab's collections (caller must be an editor).
  Future<void> upload(String tabKey, Map<String, List<Json>> data);

  /// Grant [email] access to [tabKey] at [role] (Drive permissions). No-op for
  /// transports without an ACL.
  Future<void> share(String tabKey, String email, SyncRole role);

  /// Everyone with access to [tabKey]'s file (including the owner).
  Future<List<Collaborator>> collaborators(String tabKey);

  /// Change an existing collaborator's role (viewer ↔ editor).
  Future<void> setRole(String tabKey, String permissionId, SyncRole role);

  /// Remove a collaborator's access entirely.
  Future<void> revoke(String tabKey, String permissionId);
}

/// In-memory "cloud" shared by multiple [SyncEngine]s in tests — two engines
/// pointed at one instance behave like two devices syncing through Drive.
/// Stored as JSON strings so a round-trip can't accidentally share references.
class FakeRemoteStore implements RemoteStore {
  final Map<String, String> _files = {}; // tabKey -> JSON
  final Map<String, SyncRole> roles;
  final Map<String, List<Collaborator>> _perms = {}; // tabKey -> people

  FakeRemoteStore({Map<String, SyncRole>? roles}) : roles = roles ?? {};

  @override
  Future<Map<String, SyncRole>> accessibleTabs() async => roles;

  @override
  Future<void> enable(String tabKey) async {
    roles[tabKey] = SyncRole.editor;
    _files.putIfAbsent(tabKey, () => jsonEncode(<String, List<Json>>{}));
  }

  @override
  Future<Map<String, List<Json>>?> download(String tabKey) async {
    final raw = _files[tabKey];
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(k, (v as List).map((e) => e as Json).toList()),
    );
  }

  @override
  Future<void> upload(String tabKey, Map<String, List<Json>> data) async {
    _files[tabKey] = jsonEncode(data);
  }

  @override
  Future<void> share(String tabKey, String email, SyncRole role) async {
    final list = _perms[tabKey] ??= [];
    list.removeWhere((c) => c.email.toLowerCase() == email.toLowerCase());
    list.add(Collaborator(permissionId: email, email: email, role: role));
  }

  @override
  Future<List<Collaborator>> collaborators(String tabKey) async =>
      List.unmodifiable(_perms[tabKey] ?? const []);

  @override
  Future<void> setRole(
    String tabKey,
    String permissionId,
    SyncRole role,
  ) async {
    final list = _perms[tabKey];
    if (list == null) return;
    final i = list.indexWhere((c) => c.permissionId == permissionId);
    if (i >= 0) {
      list[i] = Collaborator(
        permissionId: permissionId,
        email: list[i].email,
        role: role,
      );
    }
  }

  @override
  Future<void> revoke(String tabKey, String permissionId) async {
    _perms[tabKey]?.removeWhere((c) => c.permissionId == permissionId);
  }
}
