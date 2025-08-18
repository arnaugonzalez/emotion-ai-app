/// Global Sync Overlay
///
/// A global overlay widget that displays sync status and offline banners
/// throughout the app. This should be added to the main scaffold or app-level
/// widget tree to provide consistent sync status indication.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_providers.dart';

import 'sync_status_widget.dart';
import 'offline_banner.dart';
import '../../core/sync/sync_manager.dart';

class GlobalSyncOverlay extends ConsumerWidget {
  final Widget child;

  const GlobalSyncOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Main app content
          child,

          // Top offline banner (when needed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: OfflineBanner()),
          ),

          // Bottom sync status indicator
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: syncStateAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
                data: (syncState) {
                  // Only show if there's something important to communicate
                  if (syncState.status == SyncStatus.idle &&
                      syncState.isOnline &&
                      syncState.pendingItems == 0 &&
                      !syncState.hasConflicts) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: const EdgeInsets.all(16),
                    child: const SyncStatusWidget(showDetails: false),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating sync status widget for pages that need minimal UI
class FloatingSyncStatus extends ConsumerWidget {
  const FloatingSyncStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncStateProvider);

    return syncStateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (syncState) {
        // Show floating status for important states
        if (syncState.status == SyncStatus.syncing ||
            syncState.status == SyncStatus.failed ||
            syncState.hasConflicts ||
            !syncState.isOnline) {
          return Positioned(
            top: kToolbarHeight + 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).cardColor,
                ),
                child: const SyncStatusWidget(showDetails: false),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Sync progress indicator for use in app bars
class SyncAppBarIndicator extends ConsumerWidget {
  const SyncAppBarIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncStateProvider);

    return syncStateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (syncState) {
        if (syncState.status == SyncStatus.syncing ||
            syncState.status == SyncStatus.syncingBackground) {
          return Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 8),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        if (!syncState.isOnline) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: const Icon(Icons.cloud_off, color: Colors.white70, size: 20),
          );
        }

        if (syncState.hasConflicts) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                const Icon(Icons.cloud_sync, color: Colors.white70, size: 20),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Simple sync status text for use in drawers or settings
class SyncStatusText extends ConsumerWidget {
  const SyncStatusText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncStateProvider);

    return syncStateAsync.when(
      loading: () => const Text('Initializing sync...'),
      error: (error, stack) => const Text('Sync unavailable'),
      data: (syncState) {
        String statusText = 'Unknown';
        Color? textColor;

        switch (syncState.status) {
          case SyncStatus.idle:
            if (syncState.isOnline) {
              statusText = 'Synced';
              textColor = Colors.green;
            } else {
              statusText = 'Offline';
              textColor = Colors.grey;
            }
            break;
          case SyncStatus.syncing:
            statusText = 'Syncing...';
            textColor = Colors.blue;
            break;
          case SyncStatus.syncingBackground:
            statusText = 'Background sync';
            textColor = Colors.blue;
            break;
          case SyncStatus.conflictDetected:
            statusText = '${syncState.conflicts.length} conflict(s)';
            textColor = Colors.orange;
            break;
          case SyncStatus.failed:
            statusText = 'Sync failed';
            textColor = Colors.red;
            break;
          case SyncStatus.offline:
            statusText = 'Working offline';
            textColor = Colors.grey;
            break;
        }

        if (syncState.pendingItems > 0) {
          statusText += ' (${syncState.pendingItems} pending)';
        }

        return Text(
          statusText,
          style: TextStyle(color: textColor, fontSize: 12),
        );
      },
    );
  }
}
