import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/student.dart';
import '../../../database/repositories/student_repository.dart';

class DeleteDialog extends StatefulWidget {
  final Student student;
  final VoidCallback onDeleted;

  const DeleteDialog({
    super.key,
    required this.student,
    required this.onDeleted,
  });

  @override
  State<DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<DeleteDialog> {
  final TextEditingController _nameConfirmController = TextEditingController();
  bool _isDeleting = false;

  bool get _isMatch => _nameConfirmController.text.trim() == widget.student.name.trim();

  Future<void> _handleDelete() async {
    if (!_isMatch || _isDeleting) return;

    setState(() => _isDeleting = true);

    try {
      await StudentRepository().deleteStudent(widget.student.id!);

      if (mounted) {
        Navigator.pop(context);
        widget.onDeleted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.student.name} permanently delete ho gaya.')),
        );
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete nahi ho saka. Dobara try karein.')),
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
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 28, color: AppColors.statusExpired),
                SizedBox(width: 8),
                Text(
                  'DELETE MEMBER',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusExpired,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Aap ${widget.student.name} ko delete karne ja rahe hain. Is member ke sabhi financial ledger records bhi delete ho jayenge.',
              style: TextStyle(fontSize: 13, color: secondaryTextColor),
            ),
            const SizedBox(height: 16),

            Text(
              'Confirm karne ke liye member ka naam type karein:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryTextColor),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Text(
                widget.student.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.champagneGold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _nameConfirmController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 14, color: primaryTextColor),
              decoration: InputDecoration(
                hintText: 'Member ka naam exact type karein...',
                hintStyle: TextStyle(fontSize: 12, color: secondaryTextColor),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.statusExpired)),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryTextColor,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isMatch && !_isDeleting ? _handleDelete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusExpired,
                      disabledBackgroundColor: AppColors.statusExpired.withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Permanently Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
