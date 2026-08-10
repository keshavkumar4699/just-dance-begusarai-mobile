import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/photo_service.dart';
import '../add/crop_screen.dart';

/// Shared helper: pick (camera/gallery) -> compress -> square crop -> path.
/// Returns null when cancelled.
Future<String?> pickAndCrop(BuildContext context, ImageSource source) async {
  final raw = await PhotoService.pick(source);
  if (raw == null) return null;
  final compressed = await PhotoService.compress(raw);
  if (!context.mounted) return compressed;
  final cropped = await Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => CropScreen(imagePath: compressed)),
  );
  return cropped ?? compressed;
}
