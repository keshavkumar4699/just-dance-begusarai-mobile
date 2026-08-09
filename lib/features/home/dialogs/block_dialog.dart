import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../models/student.dart';
import '../../../database/repositories/student_repository.dart';
import '../../../app/widgets/app_button.dart';

class BlockDialog extends StatefulWidget {
  final Student student;
  final VoidCallback onToggled;

  const BlockDialog({
    super.key,
    required this.student,
    required this.onToggled,
  });

  @override
  State<BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<BlockDialog> {
  bool _isProcessing = false;

  Future<void> _handleToggle() async {
    setState(() => _isProcessing = true);
    try {
      await StudentRepository().toggleBlockStatus(widget.student.id!, !widget.student.isBlocked);
      if (mounted) {
        Navigator.pop(context);
        widget.onToggled();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operation fail ho gaya. Dobara try karein.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final isCurrentlyBlocked = widget.student.isBlocked;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCurrentlyBlocked ? Icons.lock_open : Icons.block,
              size: 44,
              color: isCurrentlyBlocked ? AppColors.statusActive : AppColors.statusBlocked,
            ),
            const SizedBox(height: 12),
            Text(
              isCurrentlyBlocked ? 'Unblock ${widget.student.name}?' : 'Block ${widget.student.name}?',
              style: AppTypography.headingSmall(primaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isCurrentlyBlocked
                  ? 'Unblock karne ke baad member dobara active lists me dikhne lagega.'
                  : 'Blocked member normal member lists me active nahi dikhega.',
              style: TextStyle(fontSize: 13, color: secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryTextColor,
                      side: BorderSide(color: isDark ? AppColors.darkHairline : AppColors.lightHairline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: isCurrentlyBlocked ? 'Unblock' : 'Block',
                    isLoading: _isProcessing,
                    onPressed: _handleToggle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
