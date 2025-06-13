import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenUsageNotifier extends StateNotifier<int> {
  static const String _tokenUsageKey = 'token_usage';
  static const String _unlimitedTokensKey = 'unlimited_tokens';
  static const int _regularUserLimit = 300000;
  static const int _adminUserLimit = 2500000;

  TokenUsageNotifier() : super(0) {
    _loadTokenUsage();
  }

  Future<void> _loadTokenUsage() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_tokenUsageKey) ?? 0;
  }

  Future<void> addTokens(int tokens) async {
    final prefs = await SharedPreferences.getInstance();
    final isUnlimited = prefs.getBool(_unlimitedTokensKey) ?? false;
    final limit = isUnlimited ? _adminUserLimit : _regularUserLimit;

    if (state + tokens <= limit) {
      state += tokens;
      await prefs.setInt(_tokenUsageKey, state);
    } else {
      throw Exception('Token usage limit exceeded');
    }
  }

  Future<void> resetUsage() async {
    final prefs = await SharedPreferences.getInstance();
    state = 0;
    await prefs.setInt(_tokenUsageKey, 0);
  }

  bool get hasReachedLimit {
    return state >= _regularUserLimit;
  }

  int get remainingTokens {
    return _regularUserLimit - state;
  }
}

final tokenUsageProvider = StateNotifierProvider<TokenUsageNotifier, int>((
  ref,
) {
  return TokenUsageNotifier();
});
