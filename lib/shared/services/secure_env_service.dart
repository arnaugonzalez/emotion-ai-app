import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'encryption_service.dart';

final logger = Logger();

class SecureEnvService {
  static final SecureEnvService _instance = SecureEnvService._internal();
  factory SecureEnvService() => _instance;

  final EncryptionService _encryptionService = EncryptionService();
  bool _isInitialized = false;

  SecureEnvService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _encryptionService.initialize();
      await _secureEnvVariables();
      _isInitialized = true;
      logger.i('Secure environment service initialized');
    } catch (e) {
      logger.e('Failed to initialize secure environment service: $e');
      rethrow;
    }
  }

  Future<void> _secureEnvVariables() async {
    final envVars = {
      'OPENAI_API_KEY': dotenv.env['OPENAI_API_KEY'],
      'ADMIN_PIN': dotenv.env['ADMIN_PIN'],
    };

    for (final entry in envVars.entries) {
      if (entry.value != null && entry.value!.isNotEmpty) {
        await _encryptionService.securelyStoreKey(entry.key, entry.value!);
      }
    }
  }

  Future<String?> getSecureEnv(String key) async {
    if (!_isInitialized) {
      throw StateError('SecureEnvService not initialized');
    }

    try {
      return await _encryptionService.securelyRetrieveKey(key);
    } catch (e) {
      logger.e('Error retrieving secure environment variable: $e');
      rethrow;
    }
  }

  Future<void> clearSecureEnv() async {
    if (!_isInitialized) return;

    try {
      await _encryptionService.securelyDeleteKey('OPENAI_API_KEY');
      await _encryptionService.securelyDeleteKey('ADMIN_PIN');
    } catch (e) {
      logger.e('Error clearing secure environment variables: $e');
      rethrow;
    }
  }
}
