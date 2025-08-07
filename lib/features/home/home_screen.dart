import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_ai/data/models/custom_emotion.dart';
import 'package:emotion_ai/data/models/emotional_record.dart';
import 'package:emotion_ai/features/auth/auth_provider.dart';
import '../../features/custom_emotion/custom_emotion_dialog.dart';
import 'widgets/token_usage_display.dart';
import '../../shared/widgets/validation_error_widget.dart';
import '../../utils/color_utils.dart';

// --- State Providers ---

final inputProvider = StateProvider<String>((ref) => '');
final emotionProvider = StateProvider<dynamic>((ref) => 'Happy');
final isCustomEmotionProvider = StateProvider<bool>((ref) => false);

// --- Data Providers ---

final customEmotionsProvider = FutureProvider<List<CustomEmotion>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCustomEmotions();
});

// --- Standard Emotions ---

class StandardEmotion {
  final String name;
  final Color color;
  StandardEmotion(this.name, this.color);
}

final standardEmotions = [
  StandardEmotion('Happy', Colors.yellow),
  StandardEmotion('Excited', Colors.orange),
  StandardEmotion('Tender', Colors.pink),
  StandardEmotion('Scared', Colors.purple),
  StandardEmotion('Angry', Colors.red),
  StandardEmotion('Sad', Colors.blue),
  StandardEmotion('Anxious', Colors.teal),
];

// --- HomeScreen Widget ---

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initial data fetch
    Future.microtask(() => ref.invalidate(customEmotionsProvider));
  }

  Future<void> _addCustomEmotion() async {
    final result = await showDialog<CustomEmotion>(
      context: context,
      builder: (context) => const CustomEmotionDialog(),
    );

    if (result != null) {
      try {
        final apiService = ref.read(apiServiceProvider);
        // We need to create a version of the object for the API without the ID and created_at
        final newEmotion = CustomEmotion(
          name: result.name,
          color: result.color,
          createdAt:
              DateTime.now(), // This will be ignored by the backend but required by the model
        );
        await apiService.createCustomEmotion(newEmotion);
        ref.invalidate(customEmotionsProvider);
        if (!mounted) return;
        ValidationHelper.showSuccessSnackBar(
          context,
          'Custom emotion "${result.name}" created successfully!',
        );
      } catch (e) {
        if (!mounted) return;
        ValidationHelper.showApiErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _saveRecord() async {
    final input = ref.read(inputProvider).trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text before saving.')),
      );
      return;
    }

    final emotionValue = ref.read(emotionProvider);
    final isCustom = ref.read(isCustomEmotionProvider);
    final apiService = ref.read(apiServiceProvider);

    late EmotionalRecord record;

    if (isCustom) {
      final customEmotion = emotionValue as CustomEmotion;
      record = EmotionalRecord(
        source: 'home_input',
        description: input,
        emotion: customEmotion.name,
        color: customEmotion.color,
        customEmotionName: customEmotion.name,
        customEmotionColor: customEmotion.color,
        createdAt: DateTime.now(),
      );
    } else {
      final standardEmotion = standardEmotions.firstWhere(
        (e) => e.name == emotionValue,
      );
      record = EmotionalRecord(
        source: 'home_input',
        description: input,
        emotion: standardEmotion.name,
        color: standardEmotion.color.toARGB32(),
        createdAt: DateTime.now(),
      );
    }

    try {
      await apiService.createEmotionalRecord(record);
      if (!mounted) return;
      ValidationHelper.showSuccessSnackBar(
        context,
        'Record saved: ${record.emotion}',
      );
      // Clear form
      ref.read(inputProvider.notifier).state = '';
    } catch (e) {
      if (!mounted) return;
      ValidationHelper.showApiErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customEmotionsAsync = ref.watch(customEmotionsProvider);
    final isCustom = ref.watch(isCustomEmotionProvider);
    final selectedEmotion = ref.watch(emotionProvider);

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

                    // Emotion Type Selector
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Standard'),
                            selected: !isCustom,
                            onSelected: (selected) {
                              if (selected) {
                                ref
                                    .read(isCustomEmotionProvider.notifier)
                                    .state = false;
                                ref.read(emotionProvider.notifier).state =
                                    standardEmotions.first.name;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Custom'),
                            selected: isCustom,
                            onSelected: (selected) {
                              if (selected) {
                                customEmotionsAsync.when(
                                  data: (customEmotions) {
                                    if (customEmotions.isNotEmpty) {
                                      ref
                                          .read(
                                            isCustomEmotionProvider.notifier,
                                          )
                                          .state = true;
                                      ref.read(emotionProvider.notifier).state =
                                          customEmotions.first;
                                    } else {
                                      _addCustomEmotion();
                                    }
                                  },
                                  loading: () {},
                                  error: (e, s) {},
                                );
                              }
                            },
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

                    // Emotion Dropdowns
                    if (isCustom)
                      customEmotionsAsync.when(
                        data: (customEmotions) {
                          if (customEmotions.isEmpty) {
                            return const Text(
                              'No custom emotions yet. Add one!',
                            );
                          }
                          return DropdownButtonFormField<CustomEmotion>(
                            value:
                                selectedEmotion is CustomEmotion
                                    ? selectedEmotion
                                    : customEmotions.first,
                            items:
                                customEmotions
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(emotionProvider.notifier).state =
                                    value;
                              }
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error:
                            (e, s) => Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Could not load custom emotions',
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                                TextButton(
                                  onPressed:
                                      () => ref.invalidate(
                                        customEmotionsProvider,
                                      ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedEmotion as String,
                        items:
                            standardEmotions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.name,
                                    child: Text(e.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(emotionProvider.notifier).state = value;
                          }
                        },
                      ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveRecord,
                        child: const Text('Save'),
                      ),
                    ),
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
