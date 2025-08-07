import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/sync_service.dart';
import '../../data/models/emotional_record.dart';

/// Provider for the sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

/// Provider for sync status
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStatusStream;
});

/// Provider for emotional records with offline support
final emotionalRecordsProvider = FutureProvider<List<EmotionalRecord>>((
  ref,
) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.getAllEmotionalRecords();
});

/// Provider for sync statistics
final syncStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.getSyncStats();
});

/// Provider for saving emotional records with automatic sync
final saveEmotionalRecordProvider =
    Provider<Future<EmotionalRecord> Function(EmotionalRecord)>((ref) {
      final syncService = ref.watch(syncServiceProvider);

      return (EmotionalRecord record) async {
        final savedRecord = await syncService.saveEmotionalRecord(record);

        // Refresh the emotional records list
        ref.invalidate(emotionalRecordsProvider);
        ref.invalidate(syncStatsProvider);

        return savedRecord;
      };
    });
