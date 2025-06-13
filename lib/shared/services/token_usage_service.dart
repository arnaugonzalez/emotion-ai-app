import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_token_usage.dart';
import '../models/user_profile.dart';
import 'sqlite_helper.dart';
import 'user_profile_service.dart';

final logger = Logger();

class TokenUsageService {
  final SQLiteHelper _sqliteHelper;
  final UserProfileService _profileService;

  TokenUsageService(this._sqliteHelper, this._profileService);

  Future<bool> canMakeRequest(int estimatedTokens) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isUnlimited = prefs.getBool('unlimited_tokens') ?? false;

      if (isUnlimited) {
        logger.i('Unlimited tokens enabled - request allowed');
        return true;
      }

      final profile = await _profileService.getProfile();
      if (profile == null) {
        logger.w('No user profile found, using default token limit');
        return estimatedTokens <= UserProfile.getDailyTokenLimit('user');
      }

      final today = DateTime.now();
      final usage = await _sqliteHelper.getDailyTokenUsage(
        profile.name ?? 'default',
        today,
      );
      final dailyLimit = profile.dailyTokenLimit;

      final hasEnoughTokens = usage.totalTokens + estimatedTokens <= dailyLimit;
      if (!hasEnoughTokens) {
        logger.w(
          'Token limit exceeded - Daily limit: $dailyLimit, Current usage: ${usage.totalTokens}, Requested: $estimatedTokens',
        );
      }

      return hasEnoughTokens;
    } catch (e, stackTrace) {
      logger.e(
        'Error checking token usage limit',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> recordTokenUsage(
    int promptTokens,
    int completionTokens,
    double costInCents,
  ) async {
    try {
      final profile = await _profileService.getProfile();
      final userId = profile?.name ?? 'default';

      await _sqliteHelper.addTokenUsage(
        userId,
        promptTokens,
        completionTokens,
        costInCents,
      );

      logger.i(
        'Recorded token usage - User: $userId, Prompt: $promptTokens, Completion: $completionTokens, Cost: $costInCents',
      );
    } catch (e, stackTrace) {
      logger.e('Error recording token usage', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<DailyTokenUsage> getCurrentDayUsage() async {
    try {
      final profile = await _profileService.getProfile();
      final userId = profile?.name ?? 'default';
      final usage = await _sqliteHelper.getDailyTokenUsage(
        userId,
        DateTime.now(),
      );

      logger.i('Current day usage for $userId: ${usage.totalTokens} tokens');
      return usage;
    } catch (e, stackTrace) {
      logger.e(
        'Error getting current day usage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> cleanupOldData() async {
    try {
      // Keep last 30 days of data
      await _sqliteHelper.cleanupOldTokenUsage(30);
      logger.i('Cleaned up old token usage data');
    } catch (e, stackTrace) {
      logger.e(
        'Error cleaning up old token usage',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> isAdmin() async {
    final profile = await _profileService.getProfile();
    return profile?.role == 'admin';
  }

  Future<int> getRemainingTokens() async {
    final profile = await _profileService.getProfile();
    final usage = await getCurrentDayUsage();
    final limit =
        profile?.dailyTokenLimit ?? UserProfile.getDailyTokenLimit('user');
    return limit - usage.totalTokens;
  }
}

// Provider for TokenUsageService
final tokenUsageServiceProvider = Provider<TokenUsageService>((ref) {
  return TokenUsageService(
    SQLiteHelper(),
    ref.watch(userProfileServiceProvider),
  );
});
