import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../shared/models/emotional_record.dart';
import '../../shared/services/sqlite_helper.dart';

final inputProvider = StateProvider<String>((ref) => '');
final emotionProvider = StateProvider<Emotion>((ref) => Emotion.happy);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> saveEmotionalRecord(EmotionalRecord record) async {
    final url = Uri.parse('http://localhost:8000/emotional_records/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(record.toMap()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save emotional record');
      }
    } catch (e) {
      // Save the record locally if the HTTP call fails
      final sqliteHelper = SQLiteHelper();
      await sqliteHelper.insertEmotionalRecord(record);
      print('Saved emotional record locally due to error: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(inputProvider);
    final emotion = ref.watch(emotionProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Write how you feel, any thought, or something you want to share:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged:
                  (value) => ref.read(inputProvider.notifier).state = value,
            ),
            const SizedBox(height: 20),
            DropdownButton<Emotion>(
              value: emotion,
              onChanged: (value) {
                if (value != null) {
                  ref.read(emotionProvider.notifier).state = value;
                }
              },
              items:
                  Emotion.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name.toUpperCase()),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final now = DateTime.now();
                final record = EmotionalRecord(
                  date: now,
                  source: 'home_input',
                  description: input,
                  emotion: emotion,
                );

                try {
                  await saveEmotionalRecord(record);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Emotional record saved: $input - ${emotion.name}',
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save emotional record')),
                  );
                }
              },
              child: const Text('Save Emotional Record'),
            ),
          ],
        ),
      ),
    );
  }
}
