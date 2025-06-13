import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AdminPinConfigError extends Error {
  final String message;
  AdminPinConfigError(this.message);

  @override
  String toString() => 'AdminPinConfigError: $message';
}

// Isolate function for PIN verification
Future<bool> _verifyPinInIsolate(Map<String, String> data) async {
  final enteredPin = data['enteredPin']!;
  final savedPin = data['savedPin']!;
  return enteredPin == savedPin;
}

class PinCodeScreen extends ConsumerStatefulWidget {
  final bool isSettingUp;

  const PinCodeScreen({super.key, this.isSettingUp = false});

  @override
  ConsumerState<PinCodeScreen> createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends ConsumerState<PinCodeScreen> {
  static const String _pinKey = 'user_pin_code';
  late final String _adminCode;
  static const int _maxLength = 12;

  String _enteredPin = '';
  bool _obscurePin = true;
  Timer? _obscureTimer;
  SharedPreferences? _prefs;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _validateAndInitializeAdminPin();
    _initPrefs();
  }

  void _validateAndInitializeAdminPin() {
    final adminPin = dotenv.env['ADMIN_PIN'];

    if (adminPin == null || adminPin.isEmpty) {
      const message =
          'Admin PIN not found in environment variables. Please set ADMIN_PIN in your .env file.';
      logger.e(message);
      _showFatalError(message);
      throw AdminPinConfigError(message);
    }

    _adminCode = adminPin;
  }

  void _showFatalError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fatal Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const Text(
                  'The application cannot continue due to a security configuration error:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(message),
                const SizedBox(height: 16),
                const Text(
                  'Please fix the configuration and restart the application.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Exit App'),
              onPressed: () => SystemNavigator.pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _obscureTimer?.cancel();
    super.dispose();
  }

  void _onKeyPress(String value) {
    if (_enteredPin.length < _maxLength && !_isProcessing) {
      setState(() {
        _enteredPin += value;
        _obscurePin = false;
      });

      // Start timer to obscure the last digit
      _obscureTimer?.cancel();
      _obscureTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _obscurePin = true;
          });
        }
      });
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty && !_isProcessing) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _onSubmit() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      _prefs ??= await SharedPreferences.getInstance();

      if (widget.isSettingUp) {
        // Save the PIN
        await _prefs!.setString(_pinKey, _enteredPin);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN code set successfully')),
        );
        context.go('/');
      } else {
        // Verify the PIN
        final savedPin = _prefs!.getString(_pinKey);

        if (_enteredPin == _adminCode) {
          // Admin code entered - run in isolate
          await compute<Map<String, String>, bool>(_verifyPinInIsolate, {
            'enteredPin': _enteredPin,
            'savedPin': _adminCode,
          });

          await _prefs!.setBool('unlimited_tokens', true);
          await _prefs!.setBool('pin_verified', true);
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin code activated: Unlimited usage'),
            ),
          );
          context.go('/');
        } else if (savedPin != null) {
          // Regular user PIN - verify in isolate
          final isValid = await compute<Map<String, String>, bool>(
            _verifyPinInIsolate,
            {'enteredPin': _enteredPin, 'savedPin': savedPin},
          );

          if (isValid) {
            await _prefs!.setBool('pin_verified', true);
            if (!mounted) return;

            final userName = _prefs!.getString('user_name') ?? 'User';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Welcome back, $userName')));
            context.go('/');
          } else {
            _handleInvalidPin();
          }
        } else {
          _handleInvalidPin();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handleInvalidPin() {
    setState(() {
      _enteredPin = '';
      _isProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PIN code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildKeypadButton(String value) {
    // Calculate button size based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize =
        (screenWidth - 32 - 24) /
        3; // (screen width - padding - gaps) / 3 buttons

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => _onKeyPress(value),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: buttonSize * 0.3, // Responsive font size
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required Icon icon,
    Color? color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = (screenWidth - 32 - 24) / 3;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: IconButton(
          onPressed: onPressed,
          icon: icon,
          iconSize: buttonSize * 0.3,
          color: color,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;
    final availableHeight =
        screenHeight -
        AppBar().preferredSize.height -
        topPadding -
        bottomPadding;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSettingUp ? 'Set PIN Code' : 'Enter PIN Code'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height:
                  availableHeight *
                  0.2, // 20% of available height for top content
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isSettingUp
                        ? 'Create a PIN code (up to 12 digits)'
                        : 'Enter your PIN code',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < _maxLength; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              width: 12,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color:
                                        i < _enteredPin.length
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child:
                                  i == _enteredPin.length - 1 &&
                                          !_obscurePin &&
                                          _enteredPin.isNotEmpty
                                      ? Text(
                                        _enteredPin[i],
                                        style: const TextStyle(fontSize: 24),
                                        textAlign: TextAlign.center,
                                      )
                                      : i < _enteredPin.length
                                      ? const Text(
                                        '•',
                                        style: TextStyle(fontSize: 24),
                                        textAlign: TextAlign.center,
                                      )
                                      : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildKeypadButton('1'),
                      _buildKeypadButton('2'),
                      _buildKeypadButton('3'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildKeypadButton('4'),
                      _buildKeypadButton('5'),
                      _buildKeypadButton('6'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildKeypadButton('7'),
                      _buildKeypadButton('8'),
                      _buildKeypadButton('9'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        onPressed: _onBackspace,
                        icon: const Icon(Icons.backspace),
                      ),
                      _buildKeypadButton('0'),
                      _buildActionButton(
                        onPressed: _enteredPin.isNotEmpty ? _onSubmit : null,
                        icon: const Icon(Icons.check_circle),
                        color:
                            _enteredPin.isNotEmpty
                                ? Theme.of(context).primaryColor
                                : Colors.deepPurple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
