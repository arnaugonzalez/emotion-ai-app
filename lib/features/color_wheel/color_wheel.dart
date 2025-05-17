import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../shared/models/emotional_record.dart';
import '../../shared/services/sqlite_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ColorWheelScreen extends StatefulWidget {
  const ColorWheelScreen({super.key});

  @override
  State<ColorWheelScreen> createState() => _ColorWheelScreenState();
}

class _ColorWheelScreenState extends State<ColorWheelScreen> {
  final List<Emotion> emotions = Emotion.values;
  Emotion? selectedEmotion;

  Future<void> saveEmotionalRecord(EmotionalRecord record) async {
    final url = Uri.parse('http://10.0.2.2:8000/emotional_records/');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(record.toMap()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save to backend: ${response.statusCode}');
      }
      logger.i('Emotional record saved to backend successfully');
    } catch (e) {
      logger.w('Failed to save to backend, falling back to local storage: $e');
      try {
        final sqliteHelper = SQLiteHelper();
        await sqliteHelper.insertEmotionalRecord(record);
        logger.i('Emotional record saved locally successfully');
      } catch (e) {
        logger.e('Failed to save emotional record locally: $e');
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'How do you feel today?',
              style: TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children:
                  emotions.map((emotion) {
                    final isSelected = selectedEmotion == emotion;
                    return ChoiceChip(
                      label: Text(
                        emotion.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: emotion.color,
                      backgroundColor: emotion.color.withValues(alpha: 0.8),
                      onSelected: (_) {
                        setState(() {
                          selectedEmotion = emotion;
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed:
                  selectedEmotion != null
                      ? () async {
                        final now = DateTime.now();
                        final record = EmotionalRecord(
                          date: now,
                          source: 'color_wheel',
                          description: 'Selected directly from the color wheel',
                          emotion: selectedEmotion!,
                        );

                        try {
                          await saveEmotionalRecord(record);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Emotion saved: ${selectedEmotion!.name}',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save emotion'),
                            ),
                          );
                        }
                      }
                      : null,
              child: const Text('Save Emotion'),
            ),
          ],
        ),
      ),
    );
  }
}
