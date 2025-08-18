import 'package:emotion_ai/data/api_service.dart';
import 'package:emotion_ai/data/models/breathing_pattern.dart';

class BreathingRepository {
  final ApiService _api;
  BreathingRepository(this._api);

  Future<List<BreathingPattern>> getPatterns() {
    return _api.getBreathingPatterns();
  }

  Future<BreathingPattern> createPattern(BreathingPattern pattern) {
    return _api.createBreathingPattern(pattern);
  }
}
