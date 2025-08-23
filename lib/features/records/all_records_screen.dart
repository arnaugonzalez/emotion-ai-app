import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:emotion_ai/data/models/breathing_session.dart';
import 'package:emotion_ai/data/models/emotional_record.dart';
import 'presentation/providers/all_records_provider.dart';
import 'package:emotion_ai/utils/color_utils.dart';

final logger = Logger();

// Provider moved to presentation/providers/all_records_provider.dart

class AllRecordsScreen extends ConsumerWidget {
  const AllRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(allRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(allRecordsProvider),
          ),
        ],
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final emotionalRecords =
              data['emotional_records'] as List<EmotionalRecord>;
          final breathingSessions =
              data['breathing_sessions'] as List<BreathingSessionData>;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allRecordsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emotional Records',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildEmotionalRecordsList(emotionalRecords),
                  const SizedBox(height: 32),
                  const Text(
                    'Breathing Sessions',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildBreathingSessionsList(breathingSessions),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmotionalRecordsList(List<EmotionalRecord> records) {
    if (records.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No emotional records found'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: ColorHelper.fromDatabaseColor(
                record.customEmotionColor ?? record.color,
              ),
              child:
                  record.customEmotionName != null
                      ? Text(
                        record.customEmotionName![0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                      : const Icon(Icons.emoji_emotions, color: Colors.white),
            ),
            title: Text(
              record.customEmotionName ?? record.emotion,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.description,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  'Source: ${record.source}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
            trailing: Text(
              '${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}',
              style: TextStyle(color: Colors.grey[700], fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreathingSessionsList(List<BreathingSessionData> sessions) {
    if (sessions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No breathing sessions found'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.lightBlue,
              child: Icon(Icons.air, color: Colors.white),
            ),
            title: Text(
              session.pattern,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating: ${session.rating}/10',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (session.comment != null && session.comment!.isNotEmpty)
                  Text(
                    'Comment: ${session.comment!}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
              ],
            ),
            trailing: Text(
              '${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year}',
              style: TextStyle(color: Colors.grey[700], fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
