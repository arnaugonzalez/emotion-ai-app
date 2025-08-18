import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/themed_card.dart';
import '../../../data/models/therapy_context.dart';

class TherapyContextCard extends StatelessWidget {
  final TherapyContext therapyContext;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  const TherapyContextCard({
    super.key,
    required this.therapyContext,
    required this.onEdit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AI Therapy Context',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit context',
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => _showClearConfirmation(context),
                  tooltip: 'Clear context',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Context summary
            if (therapyContext.contextSummary != null) ...[
              _buildContextSection(
                context,
                'Summary',
                Text(therapyContext.contextSummary!),
                Icons.summarize,
                Colors.blue,
              ),
              const SizedBox(height: 16),
            ],

            // Therapy context details
            if (therapyContext.therapyContext != null &&
                therapyContext.therapyContext!.isNotEmpty) ...[
              _buildContextSection(
                context,
                'Therapy Context',
                _buildContextDetails(therapyContext.therapyContext!),
                Icons.psychology,
                Colors.purple,
              ),
              const SizedBox(height: 16),
            ],

            // AI insights
            if (therapyContext.aiInsights != null &&
                therapyContext.aiInsights!.isNotEmpty) ...[
              _buildContextSection(
                context,
                'AI Insights',
                _buildContextDetails(therapyContext.aiInsights!),
                Icons.insights,
                Colors.green,
              ),
              const SizedBox(height: 16),
            ],

            // Last updated
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Last updated: ${_formatDate(therapyContext.lastUpdated)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextSection(
    BuildContext context,
    String title,
    Widget content,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildContextDetails(Map<String, dynamic> contextData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          contextData.entries.map((entry) {
            final key = entry.key
                .replaceAll('_', ' ')
                .split(' ')
                .map(
                  (word) =>
                      word.isNotEmpty
                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                          : word,
                )
                .join(' ');
            final value = entry.value?.toString() ?? 'N/A';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Therapy Context'),
            content: const Text(
              'Are you sure you want to clear all therapy context and AI insights? '
              'This action cannot be undone and will reset what the AI knows about you.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onClear();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }
}
