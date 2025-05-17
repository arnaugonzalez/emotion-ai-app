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
    with TickerProviderStateMixin {
  AnimationController? _controller;
  Timer? _timer;
  String _phase = "Inhale";
  int _phaseIndex = 0;
  int _currentCycle = 1;
  List<int> _phases = [];
  bool _sessionCompleted = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _phases = [
      widget.pattern.inhaleSeconds,
      widget.pattern.holdSeconds,
      widget.pattern.exhaleSeconds,
      widget.pattern.restSeconds,
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _startPhase();
      }
    });
  }

  void _startPhase() {
    if (_isDisposed) return;

    if (_phaseIndex == 0 && _currentCycle > widget.pattern.cycles) {
      setState(() {
        _sessionCompleted = true;
      });
      _showRatingModal();
      return;
    }

    // Dispose of previous controller if exists
    _controller?.dispose();

    final duration = Duration(seconds: _phases[_phaseIndex]);
    _phase = ["Inhale", "Hold", "Exhale", "Rest"][_phaseIndex];

    // Create new controller
    _controller = AnimationController(vsync: this, duration: duration)
      ..addListener(() {
        if (!_isDisposed && mounted) {
          setState(() {});
        }
      });

    if (!_isDisposed) {
      _controller!.forward();

      // Cancel previous timer if exists
      _timer?.cancel();
      _timer = Timer(duration, _nextPhase);
    }
  }

  void _nextPhase() {
    if (_isDisposed || !mounted) return;

    // Check for null before disposing
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
    }

    setState(() {
      if (_phaseIndex == _phases.length - 1) {
        _currentCycle++;
        _phaseIndex = 0;
      } else {
        _phaseIndex++;
      }
    });

    if (!_isDisposed) {
      _startPhase();
    }
  }

  void _showRatingModal() {
    if (!mounted) return;

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
            if (!context.mounted) return;
            Navigator.pop(context); // Close the modal
            Navigator.pop(context); // Close the session screen
          },
          onCancel: () {
            if (!context.mounted) return;
            Navigator.pop(context); // Close the modal
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _controller?.dispose();
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
                      painter: CircleBreathPainter(
                        value: _controller?.value ?? 0.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Cycle $_currentCycle of ${widget.pattern.cycles}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _timer?.cancel();
                        _showRatingModal();
                      },
                      child: const Text("Stop Session"),
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
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;
    final currentRadius = maxRadius * value;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(CircleBreathPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
