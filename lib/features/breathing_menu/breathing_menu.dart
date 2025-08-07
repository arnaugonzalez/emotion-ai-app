import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emotion_ai/data/models/breathing_pattern.dart';
import 'package:emotion_ai/features/auth/auth_provider.dart';
import 'create_pattern_dialog.dart';

final breathingPatternsProvider = FutureProvider<List<BreathingPattern>>((
  ref,
) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getBreathingPatterns();
});

class BreathingMenuScreen extends ConsumerWidget {
  const BreathingMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsAsync = ref.watch(breathingPatternsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final newPattern = await showDialog<BreathingPattern>(
                context: context,
                builder: (context) => const CreatePatternDialog(),
              );
              if (newPattern != null) {
                final apiService = ref.read(apiServiceProvider);
                await apiService.createBreathingPattern(newPattern);
                ref.refresh(breathingPatternsProvider);
              }
            },
          ),
        ],
      ),
      body: patternsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (patterns) {
          if (patterns.isEmpty) {
            return const Center(
              child: Text(
                'No breathing patterns found. Add one to get started!',
              ),
            );
          }
          return ListView.builder(
            itemCount: patterns.length,
            itemBuilder: (context, index) {
              final pattern = patterns[index];
              return ListTile(
                title: Text(pattern.name),
                subtitle: Text(
                  '${pattern.inhaleSeconds}-${pattern.holdSeconds}-${pattern.exhaleSeconds} x${pattern.cycles}',
                ),
                onTap:
                    () => context.go('/breathing_menu/session', extra: pattern),
              );
            },
          );
        },
      ),
    );
  }
}
