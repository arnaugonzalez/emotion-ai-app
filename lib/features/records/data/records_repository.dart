import 'package:emotion_ai/data/api_service.dart';
import 'package:emotion_ai/data/models/emotional_record.dart';
import 'package:emotion_ai/data/models/breathing_session.dart';

class RecordsRepository {
  final ApiService _api;
  RecordsRepository(this._api);

  Future<List<EmotionalRecord>> getEmotionalRecords() {
    return _api.getEmotionalRecords();
  }

  Future<List<BreathingSessionData>> getBreathingSessions() {
    return _api.getBreathingSessions();
  }
}
