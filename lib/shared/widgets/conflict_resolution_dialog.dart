/// Conflict Resolution Dialog
///
/// Provides an interface for users to resolve sync conflicts by choosing
/// between local and remote versions, or merging them intelligently.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_providers.dart';
import '../../core/sync/conflict_resolver.dart';

class ConflictResolutionDialog extends ConsumerStatefulWidget {
  final List<SyncConflict> conflicts;

  const ConflictResolutionDialog({super.key, required this.conflicts});

  @override
  ConsumerState<ConflictResolutionDialog> createState() =>
      _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState
    extends ConsumerState<ConflictResolutionDialog> {
  int _currentConflictIndex = 0;
  bool _isResolving = false;
  final Map<String, ConflictResolution> _resolutions = {};

  SyncConflict get _currentConflict => widget.conflicts[_currentConflictIndex];
  bool get _hasNextConflict =>
      _currentConflictIndex < widget.conflicts.length - 1;
  bool get _hasPreviousConflict => _currentConflictIndex > 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildProgressIndicator(),
            const SizedBox(height: 16),
            Expanded(child: _buildConflictContent()),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.merge_type, color: Colors.orange.shade600, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resolve Sync Conflicts',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '${widget.conflicts.length} conflict(s) found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Conflict ${_currentConflictIndex + 1} of ${widget.conflicts.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Text(
              '${(_resolutions.length / widget.conflicts.length * 100).round()}% resolved',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentConflictIndex + 1) / widget.conflicts.length,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildConflictContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConflictInfo(),
          const SizedBox(height: 16),
          _buildDataComparison(),
          const SizedBox(height: 16),
          if (_currentConflict.canAutoResolve) _buildAutoResolveOption(),
        ],
      ),
    );
  }

  Widget _buildConflictInfo() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getItemTypeIcon(_currentConflict.itemType),
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getItemTypeDisplayName(_currentConflict.itemType),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentConflict.type.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currentConflict.description,
              style: TextStyle(color: Colors.orange.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              'Detected: ${_formatDateTime(_currentConflict.detectedAt)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataComparison() {
    return Row(
      children: [
        Expanded(
          child: _buildVersionCard(
            'Local Version',
            _currentConflict.localData,
            Icons.phone_android,
            Colors.blue,
            () => _selectResolution(ConflictResolution.keepLocal),
            _resolutions[_currentConflict.id] == ConflictResolution.keepLocal,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildVersionCard(
            'Remote Version',
            _currentConflict.remoteData,
            Icons.cloud,
            Colors.green,
            () => _selectResolution(ConflictResolution.keepRemote),
            _resolutions[_currentConflict.id] == ConflictResolution.keepRemote,
          ),
        ),
      ],
    );
  }

  Widget _buildVersionCard(
    String title,
    dynamic data,
    IconData icon,
    Color color,
    VoidCallback onSelect,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              _buildDataPreview(data),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataPreview(dynamic data) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formatDataPreview(data),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade700,
          fontFamily: 'monospace',
        ),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAutoResolveOption() {
    final isSelected =
        _resolutions[_currentConflict.id] == ConflictResolution.merge;

    return GestureDetector(
      onTap: () => _selectResolution(ConflictResolution.merge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.purple.withOpacity(0.1) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.auto_fix_high, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Merge (Recommended)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Automatically merge both versions intelligently',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: Colors.purple, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final hasResolution = _resolutions.containsKey(_currentConflict.id);

    return Column(
      children: [
        Row(
          children: [
            // Previous button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _hasPreviousConflict ? _goToPreviousConflict : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
            ),

            const SizedBox(width: 16),

            // Next/Apply button
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    hasResolution
                        ? (_hasNextConflict
                            ? _goToNextConflict
                            : _resolveAllConflicts)
                        : null,
                icon: Icon(
                  _hasNextConflict ? Icons.arrow_forward : Icons.check,
                ),
                label: Text(_hasNextConflict ? 'Next' : 'Resolve All'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Resolve all at once button
        if (_resolutions.length == widget.conflicts.length && !_isResolving)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resolveAllConflicts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.done_all),
              label: const Text('Apply All Resolutions'),
            ),
          ),

        // Resolving indicator
        if (_isResolving)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Resolving conflicts...'),
              ],
            ),
          ),
      ],
    );
  }

  void _selectResolution(ConflictResolution resolution) {
    setState(() {
      _resolutions[_currentConflict.id] = resolution;
    });
  }

  void _goToNextConflict() {
    if (_hasNextConflict) {
      setState(() {
        _currentConflictIndex++;
      });
    }
  }

  void _goToPreviousConflict() {
    if (_hasPreviousConflict) {
      setState(() {
        _currentConflictIndex--;
      });
    }
  }

  Future<void> _resolveAllConflicts() async {
    if (_resolutions.length != widget.conflicts.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please resolve all conflicts before continuing'),
        ),
      );
      return;
    }

    setState(() {
      _isResolving = true;
    });

    try {
      final syncManager = ref.read(syncManagerProvider);

      // Resolve each conflict
      for (final conflict in widget.conflicts) {
        final resolution = _resolutions[conflict.id]!;
        await syncManager.resolveConflict(conflict.id, resolution);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All conflicts resolved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve conflicts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
      }
    }
  }

  IconData _getItemTypeIcon(String itemType) {
    switch (itemType) {
      case 'emotional_record':
        return Icons.mood;
      case 'breathing_session':
        return Icons.air;
      case 'breathing_pattern':
        return Icons.pattern;
      case 'custom_emotion':
        return Icons.palette;
      default:
        return Icons.data_object;
    }
  }

  String _getItemTypeDisplayName(String itemType) {
    switch (itemType) {
      case 'emotional_record':
        return 'Emotional Record';
      case 'breathing_session':
        return 'Breathing Session';
      case 'breathing_pattern':
        return 'Breathing Pattern';
      case 'custom_emotion':
        return 'Custom Emotion';
      default:
        return itemType.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatDataPreview(dynamic data) {
    if (data == null) return 'No data';

    // This is a simplified preview - in a real implementation,
    // you'd want to format this based on the actual data type
    return data.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
