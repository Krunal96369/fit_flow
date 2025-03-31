import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/error/error_service.dart';

class ErrorDialog extends StatelessWidget {
  final ErrorType errorType;
  final String technicalMessage;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.errorType,
    required this.technicalMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorService = ErrorServiceImpl(); // In real app, inject this
    final userMessage = errorService.getUserFriendlyMessage(
      errorType,
      technicalMessage,
    );

    return AlertDialog(
      title: const Text('Error'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(userMessage),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            const Text(
              'Technical details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(technicalMessage, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('Retry'),
          ),
      ],
    );
  }
}
