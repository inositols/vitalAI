/// Representation of a local record.
class LocalRecord {
  final String id;
  final String content;
  final DateTime updatedAt;

  LocalRecord({required this.id, required this.content, required this.updatedAt});
}

/// Representation of a remote record.
class RemoteRecord {
  final String id;
  final String content;
  final DateTime updatedAt;

  RemoteRecord({required this.id, required this.content, required this.updatedAt});
}

/// Engine that handles merging local and remote entries.
class SyncEngine {
  /// Resolve conflict using "last-write-wins" strategy.
  dynamic resolveConflict(LocalRecord local, RemoteRecord remote) {
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return local; // Local is newer, push to cloud
    } else {
      return remote; // Remote is newer, pull to local database
    }
  }
}
