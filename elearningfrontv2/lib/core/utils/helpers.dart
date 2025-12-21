import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  static void showSnackBar(BuildContext context, String message,
      {Color backgroundColor = Colors.black}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Format a DateTime to "dd MMM yyyy HH:mm" using intl
  static String formatDateTime(DateTime dt) {
    try {
      final formatter = DateFormat('dd MMM yyyy HH:mm');
      return formatter.format(dt.toLocal());
    } catch (_) {
      return dt.toIso8601String();
    }
  }

  /// Format a DateTime to "dd MMM yyyy" using intl
  static String formatDate(DateTime dt) {
    try {
      final formatter = DateFormat('dd MMM yyyy');
      return formatter.format(dt.toLocal());
    } catch (_) {
      return dt.toIso8601String();
    }
  }

  /// Show a confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
