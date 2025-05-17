import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '../../shared/models/breathing_pattern.dart';
import '../../shared/services/sqlite_helper.dart';

final logger = Logger();

class CreatePatternDialog extends StatefulWidget {
  final Function onPatternCreated;

  const CreatePatternDialog({super.key, required this.onPatternCreated});

  @override
  State<CreatePatternDialog> createState() => _CreatePatternDialogState();
}

class _CreatePatternDialogState extends State<CreatePatternDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _inhaleController = TextEditingController(text: '4');
  final _holdController = TextEditingController(text: '4');
  final _exhaleController = TextEditingController(text: '4');
  final _cyclesController = TextEditingController(text: '4');
  final _restController = TextEditingController(text: '2');

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _inhaleController.dispose();
    _holdController.dispose();
    _exhaleController.dispose();
    _cyclesController.dispose();
    _restController.dispose();
    super.dispose();
  }

  Future<void> _savePattern() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final pattern = BreathingPattern(
      name: _nameController.text,
      inhaleSeconds: int.parse(_inhaleController.text),
      holdSeconds: int.parse(_holdController.text),
      exhaleSeconds: int.parse(_exhaleController.text),
      cycles: int.parse(_cyclesController.text),
      restSeconds: int.parse(_restController.text),
    );

    try {
      // First try to save to backend
      await _saveToBackend(pattern);
      logger.i('Pattern saved to backend successfully');
    } catch (e) {
      logger.e('Failed to save to backend: $e');
      // If backend fails, save locally only
      await _saveToLocalStorage(pattern);
    }

    setState(() => _isSaving = false);
    if (mounted) {
      widget.onPatternCreated();
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveToBackend(BreathingPattern pattern) async {
    try {
      final url = Uri.parse('http://10.0.2.2:8000/breathing_patterns/');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(pattern.toMap()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save to backend: ${response.statusCode}');
      }

      // Also save locally for offline access
      await _saveToLocalStorage(pattern);
    } catch (e) {
      throw Exception('Backend connection failed: $e');
    }
  }

  Future<void> _saveToLocalStorage(BreathingPattern pattern) async {
    try {
      final sqliteHelper = SQLiteHelper();
      await sqliteHelper.insertBreathingPattern(pattern);
      logger.i('Pattern saved to local storage');
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save locally: $e');
      logger.e('Error saving to local storage: $e');
      throw Exception('Failed to save to local storage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Custom Breathing Pattern'),
      content:
          _isSaving
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Pattern Name',
                          hintText: 'e.g., Custom Relaxation',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _inhaleController,
                              decoration: const InputDecoration(
                                labelText: 'Inhale (seconds)',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num <= 0) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _holdController,
                              decoration: const InputDecoration(
                                labelText: 'Hold (seconds)',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num < 0) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _exhaleController,
                              decoration: const InputDecoration(
                                labelText: 'Exhale (seconds)',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num <= 0) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cyclesController,
                              decoration: const InputDecoration(
                                labelText: 'Cycles',
                                hintText: 'Number of repetitions',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num <= 0) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _restController,
                              decoration: const InputDecoration(
                                labelText: 'Rest (seconds)',
                                hintText: 'Between cycles',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num < 0) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _savePattern,
          child: const Text('Save Pattern'),
        ),
      ],
    );
  }
}
