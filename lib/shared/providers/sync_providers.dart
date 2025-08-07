import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_manager.dart';

/// Provider for the SyncManager singleton
final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager();
});

/// Provider for the sync state stream
final syncStateProvider = StreamProvider<SyncState>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.stateStream;
});

/// Provider for the current sync state (synchronous access)
final currentSyncStateProvider = Provider<SyncState>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.currentState;
});
