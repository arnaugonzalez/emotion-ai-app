import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:emotion_ai/data/models/breathing_session.dart';
import 'package:emotion_ai/data/models/emotional_record.dart';
import 'package:emotion_ai/features/auth/auth_provider.dart';

final logger = Logger();

final allRecordsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final emotionalRecords = await apiService.getEmotionalRecords();
  final breathingSessions = await apiService.getBreathingSessions();
  return {
    'emotional_records': emotionalRecords,
    'breathing_sessions': breathingSessions,
  };
});

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
              ref.refresh(allRecordsProvider);
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
              backgroundColor:
                  record.customEmotionColor != null
                      ? Color(record.customEmotionColor!)
                      : Color(record.color),
              child:
                  record.customEmotionName != null
                      ? Text(
                        record.customEmotionName![0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                      : const Icon(Icons.emoji_emotions, color: Colors.white),
            ),
            title: Text(record.customEmotionName ?? record.emotion),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.description),
                const SizedBox(height: 4),
                Text(
                  'Source: ${record.source}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Text(
              '${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}',
              style: TextStyle(color: Colors.grey[700]),
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
            title: Text(session.pattern),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rating: ${session.rating}/10'),
                if (session.comment != null && session.comment!.isNotEmpty)
                  Text('Comment: ${session.comment!}'),
              ],
            ),
            trailing: Text(
              '${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        );
      },
    );
  }
}
