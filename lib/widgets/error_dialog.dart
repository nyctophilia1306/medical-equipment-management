import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String errorMessage;
  final String title;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.errorMessage,
    this.title = 'Lỗi',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(errorMessage),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Đồng ý'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        if (onRetry != null)
          TextButton(
            child: const Text('Thử Lại'),
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
          ),
      ],
    );
  }
}