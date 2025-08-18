import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../records/data/records_repository.dart';
import '../../../../shared/providers/app_providers.dart';

final recordsRepositoryProvider = Provider<RecordsRepository>((ref) {
  return RecordsRepository(ref.watch(apiServiceProvider));
});

final allRecordsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(recordsRepositoryProvider);
  final emotionalRecords = await repo.getEmotionalRecords();
  final breathingSessions = await repo.getBreathingSessions();
  return {
    'emotional_records': emotionalRecords,
    'breathing_sessions': breathingSessions,
  };
});
