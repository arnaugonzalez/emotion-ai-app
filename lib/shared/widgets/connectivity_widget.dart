import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/offline_data_service.dart';

enum ConnectivityWidgetMode { banner, button, card, fullscreen }

class ConnectivityWidget extends StatefulWidget {
  final ConnectivityStatus status;
  final String? error;
  final DateTime? lastSync;
  final bool isFromCache;
  final VoidCallback? onRetry;
  final VoidCallback? onForceSync;
  final ConnectivityWidgetMode mode;
  final String? customMessage;
  final Widget? child;

  const ConnectivityWidget({
    super.key,
    required this.status,
    this.error,
    this.lastSync,
    this.isFromCache = false,
    this.onRetry,
    this.onForceSync,
    this.mode = ConnectivityWidgetMode.banner,
    this.customMessage,
    this.child,
  });

  @override
  State<ConnectivityWidget> createState() => _ConnectivityWidgetState();
}

class _ConnectivityWidgetState extends State<ConnectivityWidget> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (widget.onRetry == null) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      widget.onRetry!();
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  Future<void> _handleForceSync() async {
    if (widget.onForceSync == null) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      widget.onForceSync!();
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case ConnectivityStatus.online:
        return widget.isFromCache ? Colors.orange : Colors.green;
      case ConnectivityStatus.offline:
        return Colors.red;
      case ConnectivityStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case ConnectivityStatus.online:
        return widget.isFromCache ? Icons.cloud_off : Icons.cloud_done;
      case ConnectivityStatus.offline:
        return Icons.wifi_off;
      case ConnectivityStatus.unknown:
        return Icons.help_outline;
    }
  }

  String _getStatusMessage() {
    if (widget.customMessage != null) {
      return widget.customMessage!;
    }

    switch (widget.status) {
      case ConnectivityStatus.online:
        if (widget.isFromCache) {
          return 'Using offline data. Last sync: ${_formatLastSync()}';
        } else {
          return 'Connected to server';
        }
      case ConnectivityStatus.offline:
        return 'Working offline. Data will sync when connected.';
      case ConnectivityStatus.unknown:
        return 'Checking connection...';
    }
  }

  String _formatLastSync() {
    if (widget.lastSync == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(widget.lastSync!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat.MMMd().format(widget.lastSync!);
    }
  }

  Widget _buildBanner() {
    if (widget.status == ConnectivityStatus.online && !widget.isFromCache) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _getStatusColor().withOpacity(0.1),
      child: Row(
        children: [
          Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusMessage(),
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (widget.onRetry != null &&
              widget.status != ConnectivityStatus.online) ...[
            const SizedBox(width: 8),
            _isRetrying
                ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _getStatusColor(),
                  ),
                )
                : GestureDetector(
                  onTap: _handleRetry,
                  child: Icon(
                    Icons.refresh,
                    color: _getStatusColor(),
                    size: 20,
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildButton() {
    if (widget.status == ConnectivityStatus.online && !widget.isFromCache) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        onPressed: _isRetrying ? null : _handleRetry,
        icon:
            _isRetrying
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Icon(_getStatusIcon()),
        label: Text(
          widget.status == ConnectivityStatus.offline
              ? 'Retry Connection'
              : 'Refresh Data',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getStatusColor(),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_getStatusIcon(), color: _getStatusColor(), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getConnectionTitle(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                      Text(
                        _getStatusMessage(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Error: ${widget.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
            if (widget.onRetry != null || widget.onForceSync != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.onRetry != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRetrying ? null : _handleRetry,
                        icon:
                            _isRetrying
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ),
                  if (widget.onRetry != null && widget.onForceSync != null)
                    const SizedBox(width: 8),
                  if (widget.onForceSync != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isRetrying ? null : _handleForceSync,
                        icon: const Icon(Icons.sync),
                        label: const Text('Force Sync'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getStatusIcon(), size: 64, color: _getStatusColor()),
            const SizedBox(height: 16),
            Text(
              _getConnectionTitle(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusMessage(),
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: ${widget.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (widget.onRetry != null)
              ElevatedButton.icon(
                onPressed: _isRetrying ? null : _handleRetry,
                icon:
                    _isRetrying
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            if (widget.child != null) ...[
              const SizedBox(height: 24),
              widget.child!,
            ],
          ],
        ),
      ),
    );
  }

  String _getConnectionTitle() {
    switch (widget.status) {
      case ConnectivityStatus.online:
        return widget.isFromCache ? 'Using Cached Data' : 'Connected';
      case ConnectivityStatus.offline:
        return 'Working Offline';
      case ConnectivityStatus.unknown:
        return 'Checking Connection';
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.mode) {
      case ConnectivityWidgetMode.banner:
        return _buildBanner();
      case ConnectivityWidgetMode.button:
        return _buildButton();
      case ConnectivityWidgetMode.card:
        return _buildCard();
      case ConnectivityWidgetMode.fullscreen:
        return _buildFullscreen();
    }
  }
}

// Helper function to easily create a connectivity banner
Widget connectivityBanner({
  required ConnectivityStatus status,
  String? error,
  DateTime? lastSync,
  bool isFromCache = false,
  VoidCallback? onRetry,
}) {
  return ConnectivityWidget(
    status: status,
    error: error,
    lastSync: lastSync,
    isFromCache: isFromCache,
    onRetry: onRetry,
    mode: ConnectivityWidgetMode.banner,
  );
}

// Helper function to create a retry button
Widget retryButton({
  required ConnectivityStatus status,
  VoidCallback? onRetry,
  VoidCallback? onForceSync,
}) {
  return ConnectivityWidget(
    status: status,
    onRetry: onRetry,
    onForceSync: onForceSync,
    mode: ConnectivityWidgetMode.button,
  );
}

// Helper function to create a connectivity card
Widget connectivityCard({
  required ConnectivityStatus status,
  String? error,
  DateTime? lastSync,
  bool isFromCache = false,
  VoidCallback? onRetry,
  VoidCallback? onForceSync,
}) {
  return ConnectivityWidget(
    status: status,
    error: error,
    lastSync: lastSync,
    isFromCache: isFromCache,
    onRetry: onRetry,
    onForceSync: onForceSync,
    mode: ConnectivityWidgetMode.card,
  );
}
