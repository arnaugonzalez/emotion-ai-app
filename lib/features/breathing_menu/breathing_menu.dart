import 'package:emotion_ai/shared/models/breathing_pattern.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:emotion_ai/shared/widgets/breating_session.dart';

class BreathingMenuScreen extends StatelessWidget {
  const BreathingMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<BreathingPattern>('patterns');

    return Scaffold(
      appBar: AppBar(title: const Text('Breathing Patterns')),
      body: ListView.builder(
        itemCount: box.length,
        itemBuilder: (context, index) {
          final pattern = box.getAt(index)!;
          return ListTile(
            title: Text(pattern.name),
            subtitle: Text(
              "Inhale: ${pattern.inhaleSeconds}s, Hold: ${pattern.holdSeconds}s, Exhale: ${pattern.exhaleSeconds}s",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BreathingSessionScreen(pattern: pattern),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
