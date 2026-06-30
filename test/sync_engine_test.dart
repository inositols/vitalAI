import 'package:flutter_test/flutter_test.dart';

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

void main() {
  late SyncEngine syncEngine;

  setUp(() {
    syncEngine = SyncEngine();
  });

  group('SyncEngine Conflict Resolution Tests', () {
    test('prefers local record if it is newer', () {
      final local = LocalRecord(
        id: 'rec_1',
        content: 'Local Change (120/80)',
        updatedAt: DateTime(2026, 6, 30, 15, 0),
      );
      final remote = RemoteRecord(
        id: 'rec_1',
        content: 'Remote Stale (118/78)',
        updatedAt: DateTime(2026, 6, 30, 14, 0),
      );

      final result = syncEngine.resolveConflict(local, remote);
      expect(result, isA<LocalRecord>());
      expect(result.content, equals('Local Change (120/80)'));
    });

    test('prefers remote record if it is newer', () {
      final local = LocalRecord(
        id: 'rec_2',
        content: 'Local Stale (95 mg/dL)',
        updatedAt: DateTime(2026, 6, 30, 14, 0),
      );
      final remote = RemoteRecord(
        id: 'rec_2',
        content: 'Remote Change (110 mg/dL)',
        updatedAt: DateTime(2026, 6, 30, 15, 0),
      );

      final result = syncEngine.resolveConflict(local, remote);
      expect(result, isA<RemoteRecord>());
      expect(result.content, equals('Remote Change (110 mg/dL)'));
    });
  });
}
