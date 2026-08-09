import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Studio Crow Feedback & Alert Utilities
abstract class AppFeedback {
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    final scaffold = ScaffoldMessenger.maybeOf(context);
    if (scaffold == null) return;

    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.darkPrimaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? AppColors.statusExpired : AppColors.darkSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isError ? AppColors.statusExpired : AppColors.champagneGold,
            width: 1,
          ),
        ),
      ),
    );
  }
}
