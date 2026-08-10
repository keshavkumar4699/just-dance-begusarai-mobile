import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/photo_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'add_details_form.dart';
import 'crop_screen.dart';

/// Center "+" flow: Camera / Gallery / Photo Later -> square crop -> details form.
class AddMemberSheet extends StatefulWidget {
  const AddMemberSheet({super.key});

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  String? _photoPath;

  Future<void> _pick(ImageSource source) async {
    final nav = Navigator.of(context);
    nav.pop(); // close the sheet
    final raw = await PhotoService.pick(source);
    if (raw == null) return; // user cancelled - Photo Later or Edit later
    if (!mounted) return;
    final compressed = await PhotoService.compress(raw);
    final cropped = await nav.push<String>(
      MaterialPageRoute(builder: (_) => CropScreen(imagePath: compressed)),
    );
    if (!mounted) return;
    setState(() => _photoPath = cropped ?? compressed);
    _goToForm();
  }

  void _photoLater() {
    Navigator.of(context).pop();
    _goToForm();
  }

  void _goToForm() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddDetailsForm(photoPath: _photoPath),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add Member',
                style: wt(Theme.of(context).textTheme.titleLarge, weight: 800)),
            const SizedBox(height: 4),
            Text('Add a photo of the member',
                style: wt(Theme.of(context).textTheme.bodySmall,
                    weight: 500, color: AppColors.greyIcon)),
            const SizedBox(height: 20),
            _option(
              icon: Icons.photo_camera_outlined,
              label: 'Camera',
              sub: 'Take a photo now',
              onTap: () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 10),
            _option(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              sub: 'Choose from photos',
              onTap: () => _pick(ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            _option(
              icon: Icons.person_outline,
              label: 'Photo Later',
              sub: 'You can add it from Profile later',
              onTap: _photoLater,
            ),
          ],
        ),
      ),
    );
  }

  Widget _option({required IconData icon, required String label, required String sub, required VoidCallback onTap}) {
    return ScaleTap(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.gold),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
                Text(sub,
                    style: wt(Theme.of(context).textTheme.bodySmall,
                        weight: 500, color: AppColors.greyIcon)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.greyIcon),
          ],
        ),
      ),
    );
  }
}

