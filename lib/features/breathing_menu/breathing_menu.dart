import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emotion_ai/data/models/breathing_pattern.dart';
import 'data/breathing_repository.dart';
import '../../shared/providers/app_providers.dart';
import 'create_pattern_dialog.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/gradient_app_bar.dart';
import '../../shared/widgets/themed_card.dart';

final breathingRepositoryProvider = Provider<BreathingRepository>((ref) {
  return BreathingRepository(ref.watch(apiServiceProvider));
});

final breathingPatternsProvider = FutureProvider<List<BreathingPattern>>((
  ref,
) async {
  final repo = ref.watch(breathingRepositoryProvider);
  return repo.getPatterns();
});

class BreathingMenuScreen extends ConsumerWidget {
  const BreathingMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsAsync = ref.watch(breathingPatternsProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              GradientAppBar(
                title: 'Breathing Menu',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add new pattern',
                    onPressed: () async {
                      final newPattern = await showDialog<BreathingPattern>(
                        context: context,
                        builder: (context) => const CreatePatternDialog(),
                      );
                      if (newPattern != null) {
                        final repo = ref.read(breathingRepositoryProvider);
                        await repo.createPattern(newPattern);
                        ref.invalidate(breathingPatternsProvider);
                      }
                    },
                  ),
                ],
              ),
              Expanded(
                child: patternsAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (err, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: $err',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  () =>
                                      ref.invalidate(breathingPatternsProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                  data: (patterns) {
                    if (patterns.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.air,
                              size: 64,
                              color: AppTheme.primaryViolet.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No breathing patterns yet',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: AppTheme.primaryViolet),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first pattern to start your breathing journey',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryViolet.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final newPattern =
                                    await showDialog<BreathingPattern>(
                                      context: context,
                                      builder:
                                          (context) =>
                                              const CreatePatternDialog(),
                                    );
                                if (newPattern != null) {
                                  final repo = ref.read(
                                    breathingRepositoryProvider,
                                  );
                                  await repo.createPattern(newPattern);
                                  ref.invalidate(breathingPatternsProvider);
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Pattern'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryViolet,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: patterns.length,
                        itemBuilder: (context, index) {
                          final pattern = patterns[index];
                          return _BreathingPatternCard(pattern: pattern);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathingPatternCard extends StatelessWidget {
  final BreathingPattern pattern;

  const _BreathingPatternCard({required this.pattern});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppTheme.primaryViolet,
      AppTheme.primaryPink,
      AppTheme.primaryRed,
      AppTheme.lightViolet,
      AppTheme.lightPink,
      AppTheme.accent,
    ];

    final cardColor = colors[pattern.name.hashCode % colors.length];

    return GestureDetector(
      onTap: () => context.go('/breathing_menu/session', extra: pattern),
      child: ThemedCard(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardColor.withOpacity(0.1), cardColor.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardColor.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.air, color: cardColor, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      '${pattern.cycles}x',
                      style: TextStyle(
                        color: cardColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  pattern.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _BreathingPhaseIndicator(
                      label: 'In',
                      seconds: pattern.inhaleSeconds,
                      color: cardColor,
                    ),
                    const SizedBox(width: 8),
                    _BreathingPhaseIndicator(
                      label: 'Hold',
                      seconds: pattern.holdSeconds,
                      color: cardColor,
                    ),
                    const SizedBox(width: 8),
                    _BreathingPhaseIndicator(
                      label: 'Out',
                      seconds: pattern.exhaleSeconds,
                      color: cardColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tap to start',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cardColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingPhaseIndicator extends StatelessWidget {
  final String label;
  final int seconds;
  final Color color;

  const _BreathingPhaseIndicator({
    required this.label,
    required this.seconds,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$seconds',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
