import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../shared/models/custom_emotion.dart';

class CustomEmotionDialog extends StatefulWidget {
  final CustomEmotion? initialEmotion;

  const CustomEmotionDialog({super.key, this.initialEmotion});

  @override
  State<CustomEmotionDialog> createState() => _CustomEmotionDialogState();
}

class _CustomEmotionDialogState extends State<CustomEmotionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmotion != null) {
      _nameController.text = widget.initialEmotion!.name;
      _selectedColor = widget.initialEmotion!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialEmotion == null
            ? 'Add Custom Emotion'
            : 'Edit Custom Emotion',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Emotion Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an emotion name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Emotion Color:'),
              const SizedBox(height: 8),
              BlockPicker(
                pickerColor: _selectedColor,
                onColorChanged: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                availableColors: const [
                  Colors.red,
                  Colors.pink,
                  Colors.purple,
                  Colors.deepPurple,
                  Colors.indigo,
                  Colors.blue,
                  Colors.lightBlue,
                  Colors.cyan,
                  Colors.teal,
                  Colors.green,
                  Colors.lightGreen,
                  Colors.lime,
                  Colors.yellow,
                  Colors.amber,
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.brown,
                  Colors.grey,
                  Colors.blueGrey,
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final emotion = CustomEmotion(
                id: widget.initialEmotion?.id,
                name: _nameController.text,
                color: _selectedColor,
              );
              Navigator.of(context).pop(emotion);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
