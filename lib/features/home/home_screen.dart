import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../shared/models/emotional_record.dart';

final inputProvider = StateProvider<String>((ref) => '');
final emotionProvider = StateProvider<Emotion>((ref) => Emotion.happy);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(inputProvider);
    final emotion = ref.watch(emotionProvider);

    return SafeArea(
      // Wrap the layout in SafeArea
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escriu com et sents, algun pensament o quelcom que vulguis:',
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
                final value = ref.read(inputProvider);
                final selectedEmotion = ref.read(emotionProvider);
                final now = DateTime.now();
                final registro = EmotionalRecord(
                  fecha: now,
                  origen: 'home_input',
                  descripcion: value,
                  emocion: selectedEmotion,
                );
                final box = Hive.box<EmotionalRecord>('registers');
                await box.add(registro);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Registre guardat: $value - ${selectedEmotion.name}',
                    ),
                  ),
                );
              },
              child: const Text('Guardar registre emocional'),
            ),
          ],
        ),
      ),
    );
  }
}
