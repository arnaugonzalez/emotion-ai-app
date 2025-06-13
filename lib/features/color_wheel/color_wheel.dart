import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../../shared/models/emotional_record.dart';
import '../../shared/models/custom_emotion.dart';
import '../../shared/services/sqlite_helper.dart';
import '../../features/custom_emotion/custom_emotion_dialog.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ColorWheelScreen extends StatefulWidget {
  const ColorWheelScreen({super.key});

  @override
  State<ColorWheelScreen> createState() => _ColorWheelScreenState();
}

class _ColorWheelScreenState extends State<ColorWheelScreen> {
  final List<Emotion> emotions = Emotion.values;
  final List<CustomEmotion> customEmotions = [];
  final List<CustomEmotion> shuffledCustomEmotions = [];
  final Random _random = Random();
  dynamic selectedEmotion;
  bool isCustomEmotion = false;

  @override
  void initState() {
    super.initState();
    selectedEmotion = Emotion.happy; // Default selection
    _loadCustomEmotions();
  }

  Future<void> _loadCustomEmotions() async {
    try {
      final sqliteHelper = SQLiteHelper();
      final emotions = await sqliteHelper.getCustomEmotions();

      // Create and shuffle a copy of the emotions list
      final shuffled = List<CustomEmotion>.from(emotions);
      _shuffleList(shuffled);

      setState(() {
        customEmotions.clear();
        customEmotions.addAll(emotions);
        shuffledCustomEmotions.clear();
        shuffledCustomEmotions.addAll(shuffled);
      });
    } catch (e) {
      logger.e('Failed to load custom emotions: $e');
    }
  }

  Future<void> _addCustomEmotion() async {
    final result = await showDialog<CustomEmotion>(
      context: context,
      builder: (context) => const CustomEmotionDialog(),
    );

    if (result != null) {
      final sqliteHelper = SQLiteHelper();
      await sqliteHelper.insertCustomEmotion(result);
      await _loadCustomEmotions();
      setState(() {
        isCustomEmotion = true;
        selectedEmotion = result;
      });
    }
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
    // Remove the shuffling here since we're now using the pre-shuffled list

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'How do you feel today?',
                style: TextStyle(fontSize: 28),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
              const SizedBox(height: 20),

              // Emotion type selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Standard'),
                      selected: !isCustomEmotion,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            isCustomEmotion = false;
                            selectedEmotion = Emotion.happy;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: isCustomEmotion,
                      onSelected: (selected) {
                        if (selected) {
                          if (customEmotions.isNotEmpty) {
                            setState(() {
                              isCustomEmotion = true;
                              selectedEmotion = customEmotions.first;
                            });
                          } else {
                            _addCustomEmotion();
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      tooltip: 'Add custom emotion',
                      onPressed: _addCustomEmotion,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Standard emotions wheel
              if (!isCustomEmotion)
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Wrap(
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
                              overflow: TextOverflow.visible,
                            ),
                            selected: isSelected,
                            selectedColor: emotion.color,
                            backgroundColor: emotion.color.withOpacity(0.8),
                            onSelected: (_) {
                              setState(() {
                                selectedEmotion = emotion;
                              });
                            },
                          );
                        }).toList(),
                  ),
                ),

              // Custom emotions wheel
              if (isCustomEmotion)
                customEmotions.isEmpty
                    ? const Text(
                      'No custom emotions yet. Add one using the + button above.',
                      textAlign: TextAlign.center,
                      softWrap: true,
                    )
                    : Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children:
                            customEmotions.map((emotion) {
                              final isSelected = selectedEmotion == emotion;
                              return ChoiceChip(
                                label: Text(
                                  emotion.name,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  overflow: TextOverflow.visible,
                                ),
                                selected: isSelected,
                                selectedColor: emotion.color,
                                backgroundColor: emotion.color.withOpacity(0.8),
                                onSelected: (_) {
                                  setState(() {
                                    selectedEmotion = emotion;
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      selectedEmotion != null
                          ? () async {
                            final now = DateTime.now();

                            if (isCustomEmotion) {
                              // For custom emotions
                              final customEmotion =
                                  selectedEmotion as CustomEmotion;
                              final record = EmotionalRecord(
                                date: now,
                                source: 'color_wheel',
                                description:
                                    'Selected custom emotion: ${customEmotion.name}',
                                emotion:
                                    Emotion.happy, // Default for compatibility
                                customEmotionName: customEmotion.name,
                                customEmotionColor: customEmotion.color.value,
                              );

                              try {
                                await saveEmotionalRecord(record);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Custom emotion saved: ${customEmotion.name}',
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
                            } else {
                              // For standard emotions
                              final stdEmotion = selectedEmotion as Emotion;
                              final record = EmotionalRecord(
                                date: now,
                                source: 'color_wheel',
                                description:
                                    'Selected directly from the color wheel',
                                emotion: stdEmotion,
                              );

                              try {
                                await saveEmotionalRecord(record);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Emotion saved: ${stdEmotion.name}',
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
                          }
                          : null,
                  child: const Text('Save Emotion'),
                ),
              ),

              // Display custom emotions in random order at bottom
              if (customEmotions.isNotEmpty) ...[
                const SizedBox(height: 40),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Your Custom Emotions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children:
                        shuffledCustomEmotions.map((e) {
                          return ActionChip(
                            avatar: CircleAvatar(
                              backgroundColor: e.color,
                              radius: 12,
                            ),
                            label: Text(e.name, overflow: TextOverflow.visible),
                            onPressed: () {
                              setState(() {
                                isCustomEmotion = true;
                                selectedEmotion = e;
                              });
                            },
                          );
                        }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
