import 'package:logger/logger.dart';

final logger = Logger();

class DataValidator {
  static Map<String, dynamic> validateApiResponse(
    Map<String, dynamic> json,
    String modelType,
  ) {
    try {
      switch (modelType) {
        case 'EmotionalRecord':
          return _validateEmotionalRecord(json);
        case 'BreathingSession':
          return _validateBreathingSession(json);
        case 'BreathingPattern':
          return _validateBreathingPattern(json);
        case 'CustomEmotion':
          return _validateCustomEmotion(json);
        default:
          return json;
      }
    } catch (e) {
      logger.e('Validation error for $modelType: $e');
      return _getDefaultData(modelType);
    }
  }

  static List<Map<String, dynamic>> validateApiResponseList(
    List<dynamic> jsonList,
    String modelType,
  ) {
    return jsonList.map((item) {
      if (item is Map<String, dynamic>) {
        return validateApiResponse(item, modelType);
      } else {
        logger.e('Invalid item in list for $modelType: $item');
        return _getDefaultData(modelType);
      }
    }).toList();
  }

  static Map<String, dynamic> _validateEmotionalRecord(
    Map<String, dynamic> json,
  ) {
    return {
      'id': _ensureString(json['id']),
      'source': _ensureString(json['source'], defaultValue: 'manual'),
      'description': _ensureString(json['description'], defaultValue: ''),
      'emotion': _ensureString(json['emotion'], defaultValue: 'neutral'),
      'color': _ensureInt(json['color'], defaultValue: 0xFF757575),
      'custom_emotion_name': json['custom_emotion_name'],
      'custom_emotion_color': json['custom_emotion_color'],
      'created_at': _ensureValidDateTime(json['created_at']),
      'intensity': _ensureInt(
        json['intensity'],
        min: 1,
        max: 10,
        defaultValue: 5,
      ),
    };
  }

  static Map<String, dynamic> _validateBreathingSession(
    Map<String, dynamic> json,
  ) {
    return {
      'id': _ensureString(json['id']),
      'pattern': _ensureString(
        json['pattern'],
        defaultValue: 'Basic Breathing',
      ),
      'rating': _ensureDouble(
        json['rating'],
        min: 1.0,
        max: 5.0,
        defaultValue: 3.0,
      ),
      'comment': json['comment'],
      'created_at': _ensureValidDateTime(json['created_at']),
    };
  }

  static Map<String, dynamic> _validateBreathingPattern(
    Map<String, dynamic> json,
  ) {
    return {
      'id': _ensureString(json['id']),
      'name': _ensureString(json['name'], defaultValue: 'Unnamed Pattern'),
      'inhale_seconds': _ensureInt(
        json['inhale_seconds'],
        min: 1,
        max: 30,
        defaultValue: 4,
      ),
      'hold_seconds': _ensureInt(
        json['hold_seconds'],
        min: 0,
        max: 30,
        defaultValue: 4,
      ),
      'exhale_seconds': _ensureInt(
        json['exhale_seconds'],
        min: 1,
        max: 30,
        defaultValue: 4,
      ),
      'cycles': _ensureInt(json['cycles'], min: 1, max: 20, defaultValue: 4),
      'rest_seconds': _ensureInt(
        json['rest_seconds'],
        min: 0,
        max: 10,
        defaultValue: 0,
      ),
    };
  }

  static Map<String, dynamic> _validateCustomEmotion(
    Map<String, dynamic> json,
  ) {
    return {
      'id': _ensureString(json['id']),
      'name': _ensureString(json['name'], defaultValue: 'Custom Emotion'),
      'color': _ensureInt(json['color'], defaultValue: 0xFF757575),
      'created_at': _ensureValidDateTime(json['created_at']),
    };
  }

  static String? _ensureString(dynamic value, {String? defaultValue}) {
    if (value == null) return defaultValue;
    if (value is String) return value.isNotEmpty ? value : defaultValue;
    try {
      return value.toString();
    } catch (e) {
      return defaultValue;
    }
  }

  static int _ensureInt(
    dynamic value, {
    int? min,
    int? max,
    required int defaultValue,
  }) {
    if (value == null) return defaultValue;

    int? result;
    if (value is int) {
      result = value;
    } else if (value is double) {
      result = value.round();
    } else {
      result = int.tryParse(value.toString());
    }

    if (result == null) return defaultValue;
    if (min != null && result < min) return min;
    if (max != null && result > max) return max;
    return result;
  }

  static double _ensureDouble(
    dynamic value, {
    double? min,
    double? max,
    required double defaultValue,
  }) {
    if (value == null) return defaultValue;

    double? result;
    if (value is double) {
      result = value;
    } else if (value is int) {
      result = value.toDouble();
    } else {
      result = double.tryParse(value.toString());
    }

    if (result == null) return defaultValue;
    if (min != null && result < min) return min;
    if (max != null && result > max) return max;
    return result;
  }

  static String _ensureValidDateTime(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    if (value is String) {
      try {
        DateTime.parse(value);
        return value;
      } catch (e) {
        return DateTime.now().toIso8601String();
      }
    }
    return DateTime.now().toIso8601String();
  }

  static Map<String, dynamic> _getDefaultData(String modelType) {
    final now = DateTime.now().toIso8601String();

    switch (modelType) {
      case 'EmotionalRecord':
        return {
          'id': 'default_${DateTime.now().millisecondsSinceEpoch}',
          'source': 'manual',
          'description': 'Default emotional record',
          'emotion': 'neutral',
          'color': 0xFF757575,
          'custom_emotion_name': null,
          'custom_emotion_color': null,
          'created_at': now,
          'intensity': 5,
        };
      case 'BreathingSession':
        return {
          'id': 'default_${DateTime.now().millisecondsSinceEpoch}',
          'pattern': 'Basic Breathing',
          'rating': 3.0,
          'comment': null,
          'created_at': now,
        };
      case 'BreathingPattern':
        return {
          'id': 'default_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Default Pattern',
          'inhale_seconds': 4,
          'hold_seconds': 4,
          'exhale_seconds': 4,
          'cycles': 4,
          'rest_seconds': 0,
        };
      case 'CustomEmotion':
        return {
          'id': 'default_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Default Emotion',
          'color': 0xFF757575,
          'created_at': now,
        };
      default:
        return {};
    }
  }
}
