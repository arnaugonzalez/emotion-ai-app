import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/sync_service.dart';
import '../../core/theme/app_theme.dart';

/// Widget that displays the current sync status
class SyncStatusWidget extends ConsumerStatefulWidget {
  final bool showDetails;
  final EdgeInsets? padding;

  const SyncStatusWidget({super.key, this.showDetails = false, this.padding});

  @override
  ConsumerState<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends ConsumerState<SyncStatusWidget> {
  final SyncService _syncService = SyncService();
  SyncStatus? _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = _syncService.currentStatus;

    // Listen to sync status updates
    _syncService.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStatus == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child:
          widget.showDetails ? _buildDetailedStatus() : _buildCompactStatus(),
    );
  }

  Widget _buildCompactStatus() {
    final status = _currentStatus!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIcon(),
        const SizedBox(width: 8),
        Text(
          _getStatusText(),
          style: TextStyle(
            fontSize: 12,
            color: _getStatusColor(),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (status.pendingRecords > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${status.pendingRecords}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailedStatus() {
    final status = _currentStatus!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusDescription(),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (!status.isOnline || status.pendingRecords > 0)
                  IconButton(
                    onPressed: _handleSyncTap,
                    icon: Icon(Icons.sync, color: AppTheme.primaryViolet),
                    tooltip: 'Force sync',
                  ),
              ],
            ),
            if (status.pendingRecords > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: status.isSyncing ? null : 0.0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryViolet,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${status.pendingRecords} records pending sync',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (status.lastSyncTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last sync: ${_formatLastSyncTime(status.lastSyncTime!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    final status = _currentStatus!;

    if (status.isSyncing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
        ),
      );
    }

    IconData iconData;
    Color iconColor;

    if (!status.isOnline) {
      iconData = Icons.cloud_off;
      iconColor = Colors.red;
    } else if (status.pendingRecords > 0) {
      iconData = Icons.cloud_sync;
      iconColor = AppTheme.accent;
    } else {
      iconData = Icons.cloud_done;
      iconColor = Colors.green;
    }

    return Icon(iconData, size: 16, color: iconColor);
  }

  String _getStatusText() {
    final status = _currentStatus!;

    if (status.isSyncing) {
      return 'Syncing...';
    }

    if (!status.isOnline) {
      return 'Offline';
    }

    if (status.pendingRecords > 0) {
      return 'Pending';
    }

    return 'Synced';
  }

  String _getStatusTitle() {
    final status = _currentStatus!;

    if (status.isSyncing) {
      return 'Syncing Data';
    }

    if (!status.isOnline) {
      return 'Offline Mode';
    }

    if (status.pendingRecords > 0) {
      return 'Sync Pending';
    }

    return 'All Synced';
  }

  String _getStatusDescription() {
    final status = _currentStatus!;

    if (status.isSyncing) {
      return 'Uploading your data to the cloud...';
    }

    if (!status.isOnline) {
      return 'Your data is saved locally and will sync when online.';
    }

    if (status.pendingRecords > 0) {
      return 'Some data is waiting to be uploaded.';
    }

    return 'All your data is safely backed up.';
  }

  Color _getStatusColor() {
    final status = _currentStatus!;

    if (status.isSyncing) {
      return AppTheme.primaryViolet;
    }

    if (!status.isOnline) {
      return Colors.red;
    }

    if (status.pendingRecords > 0) {
      return AppTheme.accent;
    }

    return Colors.green;
  }

  String _formatLastSyncTime(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _handleSyncTap() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting sync...'),
          duration: Duration(seconds: 2),
        ),
      );

      await _syncService.forcSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
