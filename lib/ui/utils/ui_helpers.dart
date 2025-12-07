

import 'package:flutter/material.dart';

Future<bool> confirmDialog(
  BuildContext context, {
    required String title,
    required String message,
  }
) async {
  final res = await showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Batal')
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Ya')
        ),
      ],
    ),
  );

  return res ?? false;
}

void showToast(BuildContext context, String msg, {
  bool error = false
}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: error ? theme.colorScheme.error : theme.colorScheme.primary,
    )
  );
}