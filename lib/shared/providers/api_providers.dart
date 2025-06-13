import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/openai_service.dart';
import '../services/sqlite_token_usage_repository.dart';
import '../services/sqlite_ai_memory_repository.dart';
import '../services/sqlite_helper.dart';
import '../services/therapy_context_service.dart';
import '../services/token_usage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Provider for API key
final apiKeyProvider = Provider<String>((ref) {
  return dotenv.env['OPENAI_API_KEY'] ?? '';
});

// Provider for SQLiteHelper
final sqliteHelperProvider = Provider<SQLiteHelper>((ref) {
  return SQLiteHelper();
});

// Provider for TokenUsageRepository
final tokenUsageRepositoryProvider = Provider<SQLiteTokenUsageRepository>((
  ref,
) {
  return SQLiteTokenUsageRepository(ref.read(sqliteHelperProvider));
});

// Provider for AIMemoryRepository
final aiMemoryRepositoryProvider = Provider<SQLiteAIMemoryRepository>((ref) {
  return SQLiteAIMemoryRepository(
    ref.read(sqliteHelperProvider),
    ref.read(apiKeyProvider),
  );
});

// Provider for OpenAIService
final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService(
    ref.read(apiKeyProvider),
    ref.read(tokenUsageRepositoryProvider),
    ref.read(therapyContextServiceProvider),
    ref.read(tokenUsageServiceProvider),
  );
});
