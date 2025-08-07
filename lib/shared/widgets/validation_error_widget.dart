import 'package:flutter/material.dart';
import '../../data/exceptions/api_exceptions.dart';

class ValidationErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ValidationErrorWidget({super.key, this.errorMessage, this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data validation issue detected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The app will continue with safe defaults. Error: $errorMessage',
            style: const TextStyle(fontSize: 12),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class ValidationHelper {
  static void showValidationSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show appropriate error message based on API exception type
  static void showApiErrorSnackBar(BuildContext context, Object error) {
    String message;
    Color backgroundColor;
    IconData icon;
    Duration duration;

    if (error is ApiException) {
      message = error.userMessage;

      switch (error.runtimeType) {
        case UnauthorizedException:
          backgroundColor = Colors.red[700]!;
          icon = Icons.lock_outline;
          duration = const Duration(seconds: 6);
          break;
        case ConflictException:
          backgroundColor = Colors.orange[700]!;
          icon = Icons.warning;
          duration = const Duration(seconds: 4);
          break;
        case ValidationException:
        case BadRequestException:
          backgroundColor = Colors.orange[600]!;
          icon = Icons.error_outline;
          duration = const Duration(seconds: 5);
          break;
        case NetworkException:
        case TimeoutException:
          backgroundColor = Colors.blue[700]!;
          icon = Icons.wifi_off;
          duration = const Duration(seconds: 5);
          break;
        case RateLimitException:
          backgroundColor = Colors.purple[700]!;
          icon = Icons.hourglass_empty;
          duration = const Duration(seconds: 6);
          break;
        default:
          backgroundColor = Colors.red[700]!;
          icon = Icons.error;
          duration = const Duration(seconds: 5);
      }
    } else {
      message = 'An unexpected error occurred';
      backgroundColor = Colors.red[700]!;
      icon = Icons.error;
      duration = const Duration(seconds: 4);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action:
            (error is NetworkException || error is TimeoutException)
                ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    // This can be handled by the calling widget
                  },
                )
                : null,
      ),
    );
  }
}
