import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/core/services/sync_engine.dart';

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
