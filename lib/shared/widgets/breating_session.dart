import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_ai/shared/widgets/rating_modal.dart';
import 'dart:async';
import '../../shared/models/breathing_pattern.dart';
import '../../shared/notifiers/breathing_session_notifier.dart';

class BreathingSessionScreen extends ConsumerStatefulWidget {
  final BreathingPattern pattern;
  const BreathingSessionScreen({super.key, required this.pattern});

  @override
  ConsumerState<BreathingSessionScreen> createState() =>
      _BreathingSessionScreenState();
}

class _BreathingSessionScreenState extends ConsumerState<BreathingSessionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  String _phase = "Inhale";
  int _phaseIndex = 0;
  int _currentCycle = 1;
  List<int> _phases = [];
  bool _sessionCompleted = false;

  @override
  void initState() {
    super.initState();
    _phases = [
      widget.pattern.inhaleSeconds,
      widget.pattern.holdSeconds,
      widget.pattern.exhaleSeconds,
      widget.pattern.restSeconds,
    ];
    _startPhase();
  }

  void _startPhase() {
    if (_phaseIndex == 0 && _currentCycle > widget.pattern.cycles) {
      setState(() {
        _sessionCompleted = true;
      });
      _showRatingModal();
      return;
    }

    final duration = Duration(seconds: _phases[_phaseIndex]);
    _phase = ["Inhale", "Hold", "Exhale", "Rest"][_phaseIndex];
    _controller = AnimationController(vsync: this, duration: duration)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
    _timer = Timer(duration, _nextPhase);
  }

  void _nextPhase() {
    _controller.dispose();

    if (_phaseIndex == _phases.length - 1) {
      _currentCycle++;
      _phaseIndex = 0;
    } else {
      _phaseIndex++;
    }

    _startPhase();
  }

  void _showRatingModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return RatingModal(
          pattern: widget.pattern,
          onSave: (session) async {
            await ref
                .read(breathingSessionProvider.notifier)
                .saveSession(session);
            Navigator.pop(context); // Close the modal
            Navigator.pop(context); // Close the session screen
          },
          onCancel: () {
            Navigator.pop(context); // Close the modal
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Breathing Session")),
      body: Center(
        child:
            _sessionCompleted
                ? const Text("Session Completed!")
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _phase,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 40),
                    CustomPaint(
                      size: const Size(200, 200),
                      painter: CircleBreathPainter(value: _controller.value),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _timer.cancel();
                        _showRatingModal();
                      },
                      child: const Text("Cancel"),
                    ),
                  ],
                ),
      ),
    );
  }
}

class CircleBreathPainter extends CustomPainter {
  final double value;

  CircleBreathPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blueAccent
          ..style = PaintingStyle.fill;

    final radius = size.width / 2 * value;
    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
