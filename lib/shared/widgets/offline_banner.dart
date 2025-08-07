/// Offline Banner Widget
///
/// Displays a prominent banner when the app is offline, showing
/// offline mode status and providing context about available features.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_providers.dart';
import '../../core/sync/sync_manager.dart';

import 'conflict_resolution_dialog.dart';

class OfflineBanner extends ConsumerWidget {
  final bool showDismissButton;
  final VoidCallback? onDismiss;

  const OfflineBanner({
    super.key,
    this.showDismissButton = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncStateProvider);

    return syncStateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (syncState) {
        // Only show banner when offline or in failed state
        if (syncState.isOnline && syncState.status != SyncStatus.failed) {
          return const SizedBox.shrink();
        }

        return _buildOfflineBanner(context, ref, syncState);
      },
    );
  }

  Widget _buildOfflineBanner(
    BuildContext context,
    WidgetRef ref,
    SyncState syncState,
  ) {
    final bannerInfo = _getBannerInfo(syncState);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: bannerInfo.backgroundColor,
        elevation: 4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            child: Row(
              children: [
                // Status icon
                Icon(bannerInfo.icon, color: bannerInfo.iconColor, size: 20),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bannerInfo.title,
                        style: TextStyle(
                          color: bannerInfo.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (bannerInfo.subtitle != null)
                        Text(
                          bannerInfo.subtitle!,
                          style: TextStyle(
                            color: bannerInfo.textColor.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                // Pending items indicator
                if (syncState.pendingItems > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bannerInfo.badgeColor ?? Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${syncState.pendingItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Action button
                if (bannerInfo.showAction)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: TextButton(
                      onPressed: () => _performAction(context, ref, syncState),
                      style: TextButton.styleFrom(
                        foregroundColor: bannerInfo.textColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        bannerInfo.actionText!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Dismiss button
                if (showDismissButton)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close,
                      color: bannerInfo.textColor.withOpacity(0.7),
                      size: 18,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  OfflineBannerInfo _getBannerInfo(SyncState syncState) {
    switch (syncState.status) {
      case SyncStatus.offline:
        return OfflineBannerInfo(
          icon: Icons.cloud_off,
          iconColor: Colors.white,
          title: 'You\'re offline',
          subtitle:
              'Working offline • Changes will sync when connection returns',
          backgroundColor: Colors.grey.shade700,
          textColor: Colors.white,
          badgeColor: Colors.orange,
          showAction: true,
          actionText: 'Retry',
        );

      case SyncStatus.failed:
        return OfflineBannerInfo(
          icon: Icons.sync_problem,
          iconColor: Colors.white,
          title: 'Sync failed',
          subtitle: 'Unable to sync your data • Check your connection',
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
          badgeColor: Colors.red.shade800,
          showAction: true,
          actionText: 'Retry',
        );

      case SyncStatus.conflictDetected:
        return OfflineBannerInfo(
          icon: Icons.merge_type,
          iconColor: Colors.white,
          title: 'Conflicts detected',
          subtitle: '${syncState.conflicts.length} item(s) need your attention',
          backgroundColor: Colors.orange.shade600,
          textColor: Colors.white,
          badgeColor: Colors.orange.shade800,
          showAction: true,
          actionText: 'Resolve',
        );

      default:
        // For any other offline scenarios
        if (!syncState.isOnline) {
          return OfflineBannerInfo(
            icon: Icons.wifi_off,
            iconColor: Colors.white,
            title: 'No internet connection',
            subtitle: 'Some features may be limited',
            backgroundColor: Colors.grey.shade600,
            textColor: Colors.white,
            showAction: false,
          );
        }

        // This shouldn't be reached given our visibility logic
        return OfflineBannerInfo(
          icon: Icons.info,
          iconColor: Colors.white,
          title: 'Status unknown',
          backgroundColor: Colors.grey.shade500,
          textColor: Colors.white,
          showAction: false,
        );
    }
  }

  void _performAction(
    BuildContext context,
    WidgetRef ref,
    SyncState syncState,
  ) {
    final syncManager = ref.read(syncManagerProvider);

    switch (syncState.status) {
      case SyncStatus.offline:
      case SyncStatus.failed:
        // Retry sync
        syncManager.forceSync();
        break;

      case SyncStatus.conflictDetected:
        // Show conflict resolution
        if (syncState.conflicts.isNotEmpty) {
          showDialog(
            context: context,
            builder:
                (context) =>
                    ConflictResolutionDialog(conflicts: syncState.conflicts),
          );
        }
        break;

      default:
        break;
    }
  }
}

class OfflineBannerInfo {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color backgroundColor;
  final Color textColor;
  final Color? badgeColor;
  final bool showAction;
  final String? actionText;

  OfflineBannerInfo({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.backgroundColor,
    required this.textColor,
    this.badgeColor,
    this.showAction = false,
    this.actionText,
  });
}

/// Compact offline indicator for use in app bars or status bars
class OfflineIndicator extends ConsumerWidget {
  final double size;

  const OfflineIndicator({super.key, this.size = 16});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncStateProvider);

    return syncStateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (syncState) {
        if (syncState.isOnline && syncState.status != SyncStatus.failed) {
          return const SizedBox.shrink();
        }

        final color = _getIndicatorColor(syncState);
        final icon = _getIndicatorIcon(syncState);

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: size, color: color),
        );
      },
    );
  }

  Color _getIndicatorColor(SyncState syncState) {
    switch (syncState.status) {
      case SyncStatus.failed:
        return Colors.red;
      case SyncStatus.conflictDetected:
        return Colors.orange;
      case SyncStatus.offline:
      default:
        return Colors.grey;
    }
  }

  IconData _getIndicatorIcon(SyncState syncState) {
    switch (syncState.status) {
      case SyncStatus.failed:
        return Icons.sync_problem;
      case SyncStatus.conflictDetected:
        return Icons.merge_type;
      case SyncStatus.offline:
      default:
        return Icons.cloud_off;
    }
  }
}

/// Floating offline snackbar for temporary notifications
class OfflineSnackbar {
  static void show(BuildContext context, SyncState syncState) {
    final message = _getMessage(syncState);
    final color = _getColor(syncState);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIcon(syncState), color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: _getAction(context, syncState),
      ),
    );
  }

  static String _getMessage(SyncState syncState) {
    switch (syncState.status) {
      case SyncStatus.offline:
        return 'Connection lost. Working offline.';
      case SyncStatus.failed:
        return 'Sync failed. Check your connection.';
      case SyncStatus.conflictDetected:
        return '${syncState.conflicts.length} conflict(s) detected.';
      case SyncStatus.idle:
        if (syncState.isOnline) {
          return 'Connection restored. Syncing...';
        }
        return 'No internet connection.';
      default:
        return 'Connection issue detected.';
    }
  }

  static Color _getColor(SyncState syncState) {
    switch (syncState.status) {
      case SyncStatus.failed:
        return Colors.red.shade600;
      case SyncStatus.conflictDetected:
        return Colors.orange.shade600;
      case SyncStatus.idle:
        if (syncState.isOnline) {
          return Colors.green.shade600;
        }
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  static IconData _getIcon(SyncState syncState) {
    switch (syncState.status) {
      case SyncStatus.failed:
        return Icons.sync_problem;
      case SyncStatus.conflictDetected:
        return Icons.merge_type;
      case SyncStatus.idle:
        if (syncState.isOnline) {
          return Icons.cloud_done;
        }
        return Icons.cloud_off;
      default:
        return Icons.cloud_off;
    }
  }

  static SnackBarAction? _getAction(BuildContext context, SyncState syncState) {
    switch (syncState.status) {
      case SyncStatus.failed:
      case SyncStatus.offline:
        return SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // Trigger retry through sync manager
            // This would need access to WidgetRef, so in practice
            // you'd pass the sync manager as a parameter
          },
        );
      case SyncStatus.conflictDetected:
        return SnackBarAction(
          label: 'Resolve',
          textColor: Colors.white,
          onPressed: () {
            // Show conflict resolution dialog
            // Similar to above, would need proper context
          },
        );
      default:
        return null;
    }
  }
}
