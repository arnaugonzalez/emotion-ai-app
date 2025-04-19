import 'package:emotion_ai/shared/models/breathing_pattern.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class BreathingSessionScreen extends StatefulWidget {
  final BreathingPattern pattern;
  const BreathingSessionScreen({super.key, required this.pattern});

  @override
  State<BreathingSessionScreen> createState() => _BreathingSessionScreenState();
}

class _BreathingSessionScreenState extends State<BreathingSessionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  String _phase = "Inhale";
  int _phaseIndex = 0;
  List<int> _phases = [];

  @override
  void initState() {
    super.initState();
    _phases = [
      widget.pattern.inhaleSeconds,
      widget.pattern.holdSeconds,
      widget.pattern.exhaleSeconds,
    ];
    _startPhase();
  }

  void _startPhase() {
    final duration = Duration(seconds: _phases[_phaseIndex]);
    _phase = ["Inhale", "Hold", "Exhale"][_phaseIndex];
    _controller = AnimationController(vsync: this, duration: duration)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
    _timer = Timer(duration, _nextPhase);
  }

  void _nextPhase() {
    _controller.dispose();
    _phaseIndex = (_phaseIndex + 1) % _phases.length;
    _startPhase();
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
      appBar: AppBar(title: Text("Breathing Session")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_phase, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 40),
            CustomPaint(
              size: const Size(200, 200),
              painter: CircleBreathPainter(value: _controller.value),
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
