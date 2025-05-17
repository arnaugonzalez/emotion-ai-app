import 'package:flutter/material.dart';
import '../../shared/models/breathing_pattern.dart';
import '../../shared/models/breathing_session_data.dart';

class RatingModal extends StatefulWidget {
  final BreathingPattern pattern;
  final void Function(BreathingSessionData session) onSave;
  final VoidCallback onCancel;

  const RatingModal({
    super.key,
    required this.pattern,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Rate Your Session"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _rating,
            min: 0,
            max: 10,
            divisions: 10,
            label: _rating.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _rating = value;
              });
            },
          ),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: "Add a comment",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _commentController.clear();
            widget.onCancel();
          },
          child: const Text("Don't Save"),
        ),
        ElevatedButton(
          onPressed: () {
            final session = BreathingSessionData(
              date: DateTime.now(),
              pattern: widget.pattern,
              rating: _rating,
              comment: _commentController.text.trim(),
            );
            widget.onSave(session);
          },
          child: const Text("Save Meditation"),
        ),
      ],
    );
  }
}
