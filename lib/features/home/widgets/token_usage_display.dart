import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/daily_token_usage.dart';
import '../../../shared/services/token_usage_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class TokenUsageDisplay extends ConsumerWidget {
  const TokenUsageDisplay({super.key});

  Future<(DailyTokenUsage, int, bool, bool)> _loadTokenUsage(
    TokenUsageService service,
  ) async {
    try {
      logger.i('Loading token usage');
      final usage = await service.getCurrentDayUsage();
      final remainingTokens = await service.getRemainingTokens();
      final isAdmin = await service.isAdmin();
      final prefs = await SharedPreferences.getInstance();
      final isUnlimited = prefs.getBool('unlimited_tokens') ?? false;
      logger.i('Token usage loaded: $usage, unlimited: $isUnlimited');
      return (usage, remainingTokens, isAdmin, isUnlimited);
    } catch (e, stackTrace) {
      logger.e('Error loading token usage', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<(DailyTokenUsage, int, bool, bool)>(
      future: _loadTokenUsage(ref.watch(tokenUsageServiceProvider)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          logger.e('Error in token usage display: ${snapshot.error}');
          return SizedBox(
            height: 50,
            child: Center(
              child: Text(
                'Error loading token usage data',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          logger.w('No token usage data available');
          return const SizedBox(
            height: 50,
            child: Center(child: Text('No token usage data available')),
          );
        }

        final (usage, remainingTokens, isAdmin, isUnlimited) = snapshot.data!;
        final totalTokens = usage.totalTokens;
        final costInEuroCents = usage.costInCents;
        final limit = isUnlimited ? 2500000 : (isAdmin ? 25000000 : 200000);
        final usagePercentage = (totalTokens / limit * 100).clamp(0.0, 100.0);

        logger.i(
          'Displaying token usage - Total: $totalTokens, Cost: $costInEuroCents',
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily API Usage',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tokens Used Today',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        isUnlimited
                            ? '$totalTokens / Unlimited'
                            : '$totalTokens / $limit',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Cost Today',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '€${(costInEuroCents / 100).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!isUnlimited)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: usagePercentage / 100,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    color:
                        usagePercentage > 90
                            ? Theme.of(context).colorScheme.error
                            : usagePercentage > 75
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.primary,
                    minHeight: 8,
                  ),
                ),
              const SizedBox(height: 8),
              if (!isUnlimited)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining: $remainingTokens tokens',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${usagePercentage.toStringAsFixed(1)}% used',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            usagePercentage > 90
                                ? Theme.of(context).colorScheme.error
                                : usagePercentage > 75
                                ? Theme.of(context).colorScheme.errorContainer
                                : null,
                      ),
                    ),
                  ],
                ),
              if (isUnlimited)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Admin Account (Unlimited tokens)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              else if (isAdmin)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Admin Account (25M tokens/day)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
