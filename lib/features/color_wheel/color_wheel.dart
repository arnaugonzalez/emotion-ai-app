import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../shared/models/emotional_record.dart';

class ColorWheelScreen extends StatefulWidget {
  const ColorWheelScreen({super.key});

  @override
  State<ColorWheelScreen> createState() => _ColorWheelScreenState();
}

class _ColorWheelScreenState extends State<ColorWheelScreen> {
  final List<Emotion> emociones = Emotion.values;
  Emotion? selectedEmotion;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Com et sents avui?', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children:
                  emociones.map((emotion) {
                    final isSelected = selectedEmotion == emotion;
                    return ChoiceChip(
                      label: Text(emotion.name.toUpperCase()),
                      selected: isSelected,
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
                        final registro = EmotionalRecord(
                          fecha: DateTime.now(),
                          origen: 'emotion_selector',
                          descripcion: 'Selecció directa des del color wheel',
                          emocion: selectedEmotion!,
                        );
                        final box = Hive.box<EmotionalRecord>('registers');
                        await box.add(registro);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Emoció guardada: ${selectedEmotion!.name}',
                            ),
                          ),
                        );
                      }
                      : null,
              child: const Text('Guardar emoció'),
            ),
          ],
        ),
      ),
    );
  }
}
