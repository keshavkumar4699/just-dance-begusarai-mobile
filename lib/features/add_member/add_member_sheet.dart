import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/widgets/app_button.dart';
import 'add_member_screen.dart';

class AddMemberSheet extends StatefulWidget {
  const AddMemberSheet({super.key});

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final ImagePicker _picker = ImagePicker();
  String? _pickedPhotoPath;
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isProcessing = true);
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 640,
        imageQuality: 85,
      );

      if (photo != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'member_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(photo.path).copy(p.join(appDir.path, fileName));

        setState(() {
          _pickedPhotoPath = savedImage.path;
          _isProcessing = false;
        });

        if (mounted) {
          _proceedToAddMemberForm();
        }
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo select nahi ho paya. Please dobara try karein.')),
        );
      }
    }
  }

  void _proceedToAddMemberForm() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddMemberScreen(photoPath: _pickedPhotoPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: isDark ? AppColors.darkHairline : AppColors.lightHairline, width: 1),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryTextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Naya Member Judega',
              style: AppTypography.headingMedium(primaryTextColor),
            ),
            const SizedBox(height: 6),
            Text(
              'Member ki photo select karein ya skip karein.',
              style: TextStyle(fontSize: 13, color: secondaryTextColor),
            ),
            const SizedBox(height: 24),

            if (_isProcessing) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_pickedPhotoPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_pickedPhotoPath!),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.statusActive, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Photo Selected ✔',
                    style: TextStyle(
                      color: AppColors.statusActive,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.champagneGold),
              title: Text('Camera Se', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600)),
              onTap: () => _pickImage(ImageSource.camera),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.champagneGold),
              title: Text('Gallery Se', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600)),
              onTap: () => _pickImage(ImageSource.gallery),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            ListTile(
              leading: Icon(Icons.person_off_outlined, color: secondaryTextColor),
              title: Text('Photo Baad Me', style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w500)),
              onTap: _proceedToAddMemberForm,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 16),

            if (_pickedPhotoPath != null)
              AppButton(
                label: 'Aage Badhein →',
                onPressed: _proceedToAddMemberForm,
              ),
          ],
        ),
      ),
    );
  }
}
