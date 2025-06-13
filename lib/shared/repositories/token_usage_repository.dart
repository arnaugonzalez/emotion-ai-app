import '../models/token_usage.dart';

abstract class TokenUsageRepository {
  Future<void> saveTokenUsage(TokenUsage usage);
  Future<void> saveBatchTokenUsage(List<TokenUsage> usages);
  Future<List<TokenUsage>> getAllTokenUsage();
  Future<TokenUsage> getTotalUsage();
  Future<void> clearAllUsage();
  Future<double> getTotalCostInCents();
  Future<bool> hasReachedLimit(bool isUnlimited);
  Future<int> getTotalTokens();
  Future<int> getRemainingTokens(bool isUnlimited);
}
