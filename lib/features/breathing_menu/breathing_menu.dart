import 'package:flutter/material.dart';
import '../../shared/models/breathing_pattern.dart';
import '../../shared/services/sqlite_helper.dart';
import '../../shared/widgets/breating_session.dart';

class BreathingMenuScreen extends StatelessWidget {
  const BreathingMenuScreen({super.key});

  Future<List<BreathingPattern>> _fetchBreathingPatterns() async {
    final sqliteHelper = SQLiteHelper();
    return await sqliteHelper.getBreathingPatterns();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Breathing Patterns')),
      body: FutureBuilder<List<BreathingPattern>>(
        future: _fetchBreathingPatterns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No breathing patterns available.'),
            );
          }

          final patterns = snapshot.data!;
          return ListView.builder(
            itemCount: patterns.length,
            itemBuilder: (context, index) {
              final pattern = patterns[index];
              return ListTile(
                title: Text(pattern.name),
                subtitle: Text(
                  "Inhale: ${pattern.inhaleSeconds}s, Hold: ${pattern.holdSeconds}s, "
                  "Exhale: ${pattern.exhaleSeconds}s, Cycles: ${pattern.cycles}, "
                  "Rest: ${pattern.restSeconds}s",
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
          );
        },
      ),
    );
  }
}
