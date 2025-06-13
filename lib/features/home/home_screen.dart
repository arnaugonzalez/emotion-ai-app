import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../../shared/models/emotional_record.dart';
import '../../shared/models/custom_emotion.dart';
import '../../shared/services/sqlite_helper.dart';
import '../../features/custom_emotion/custom_emotion_dialog.dart';
import 'widgets/token_usage_display.dart';

final inputProvider = StateProvider<String>((ref) => '');
final emotionProvider = StateProvider<dynamic>((ref) => Emotion.happy);
final customEmotionsProvider = StateProvider<List<CustomEmotion>>((ref) => []);
final shuffledCustomEmotionsProvider = StateProvider<List<CustomEmotion>>(
  (ref) => [],
);
final isCustomEmotionProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadCustomEmotions();
  }

  void _shuffleList<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      int j = _random.nextInt(i + 1);
      // Swap elements
      T temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  Future<void> _loadCustomEmotions() async {
    final sqliteHelper = SQLiteHelper();
    final customEmotions = await sqliteHelper.getCustomEmotions();
    ref.read(customEmotionsProvider.notifier).state = customEmotions;

    // Create and store shuffled list
    final shuffledList = List<CustomEmotion>.from(customEmotions);
    _shuffleList(shuffledList);
    ref.read(shuffledCustomEmotionsProvider.notifier).state = shuffledList;
  }

  Future<void> _addCustomEmotion() async {
    final result = await showDialog<CustomEmotion>(
      context: context,
      builder: (context) => const CustomEmotionDialog(),
    );

    if (result != null) {
      final sqliteHelper = SQLiteHelper();
      await sqliteHelper.insertCustomEmotion(result);
      _loadCustomEmotions();
    }
  }

  Future<void> saveEmotionalRecord(
    BuildContext context,
    EmotionalRecord record,
  ) async {
    final url = Uri.parse(
      'http://10.0.2.2:8000/emotional_records/',
    ); // Use 10.0.2.2 for emulator
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
      //logger.i('Saved emotional record locally due to error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No connection to backend. Saved locally.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(inputProvider);
    final emotion = ref.watch(emotionProvider);
    final isCustomEmotion = ref.watch(isCustomEmotionProvider);
    final customEmotions = ref.watch(customEmotionsProvider);
    final shuffledCustomEmotions = ref.watch(shuffledCustomEmotionsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Write how you feel, any thought, or something you want to share:',
                      style: TextStyle(fontSize: 20),
                      softWrap: true,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      initialValue: ref.watch(inputProvider),
                      onChanged:
                          (value) =>
                              ref.read(inputProvider.notifier).state = value,
                      maxLines: null,
                      minLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),

                    // Emotion type selector
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select emotion type:',
                                softWrap: true,
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Standard'),
                                      selected: !isCustomEmotion,
                                      onSelected: (selected) {
                                        if (selected) {
                                          ref
                                              .read(
                                                isCustomEmotionProvider
                                                    .notifier,
                                              )
                                              .state = false;
                                          ref
                                              .read(emotionProvider.notifier)
                                              .state = Emotion.happy;
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('Custom'),
                                      selected: isCustomEmotion,
                                      onSelected: (selected) {
                                        if (selected &&
                                            customEmotions.isNotEmpty) {
                                          ref
                                              .read(
                                                isCustomEmotionProvider
                                                    .notifier,
                                              )
                                              .state = true;
                                          ref
                                              .read(emotionProvider.notifier)
                                              .state = customEmotions.first;
                                        } else if (selected) {
                                          _addCustomEmotion();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          tooltip: 'Add custom emotion',
                          onPressed: _addCustomEmotion,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Standard emotions dropdown
                    if (!isCustomEmotion) ...[
                      const Text('Select your emotion:', softWrap: true),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Emotion>(
                        value: emotion as Emotion,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
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
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: e.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            e.name.toUpperCase(),
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],

                    // Custom emotions dropdown
                    if (isCustomEmotion) ...[
                      const Text('Select your custom emotion:', softWrap: true),
                      const SizedBox(height: 8),
                      if (customEmotions.isEmpty)
                        const Text(
                          'No custom emotions yet. Add one by clicking the + button.',
                          softWrap: true,
                        )
                      else
                        DropdownButtonFormField<CustomEmotion>(
                          value: emotion as CustomEmotion,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(emotionProvider.notifier).state = value;
                            }
                          },
                          items:
                              customEmotions
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: e.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              e.name,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final input = ref.read(inputProvider);
                          // Check if input is empty
                          if (input.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter some text before saving.',
                                ),
                              ),
                            );
                            return;
                          }

                          final now = DateTime.now();
                          final emotion = ref.read(emotionProvider);
                          final isCustomEmotion = ref.read(
                            isCustomEmotionProvider,
                          );

                          try {
                            // Handle both standard and custom emotions
                            if (isCustomEmotion) {
                              final customEmotion = emotion as CustomEmotion;
                              final record = EmotionalRecord(
                                date: now,
                                source: 'home_input',
                                description: input,
                                emotion:
                                    Emotion.happy, // Default for compatibility
                                customEmotionName: customEmotion.name,
                                customEmotionColor: customEmotion.color.value,
                              );

                              await saveEmotionalRecord(context, record);
                              if (!context.mounted) return;

                              // Clear form after successful save
                              ref.read(inputProvider.notifier).state = '';
                              ref.read(isCustomEmotionProvider.notifier).state =
                                  false;
                              ref.read(emotionProvider.notifier).state =
                                  Emotion.happy;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Custom emotion record saved: $input - ${customEmotion.name}',
                                  ),
                                ),
                              );
                            } else {
                              // Standard emotion flow
                              final stdEmotion = emotion as Emotion;
                              final record = EmotionalRecord(
                                date: now,
                                source: 'home_input',
                                description: input,
                                emotion: stdEmotion,
                              );

                              await saveEmotionalRecord(context, record);
                              if (!context.mounted) return;

                              // Clear form after successful save
                              ref.read(inputProvider.notifier).state = '';
                              ref.read(emotionProvider.notifier).state =
                                  Emotion.happy;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Emotion record saved: $input - ${stdEmotion.name}',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to save emotional record: $e',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),

                    // Display custom emotions in random order
                    if (customEmotions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Your Custom Emotions:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            shuffledCustomEmotions.map((e) {
                              return ActionChip(
                                avatar: CircleAvatar(
                                  backgroundColor: e.color,
                                  radius: 12,
                                ),
                                label: Text(
                                  e.name,
                                  overflow: TextOverflow.visible,
                                ),
                                onPressed: () {
                                  ref
                                      .read(isCustomEmotionProvider.notifier)
                                      .state = true;
                                  ref.read(emotionProvider.notifier).state = e;
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const TokenUsageDisplay(),
          ],
        ),
      ),
    );
  }
}
