import 'dart:io';

import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../services/photo_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Square crop screen: pan + pinch zoom inside a square viewport, Done captures
/// exactly the visible square (widget capture -> JPEG).
class CropScreen extends StatefulWidget {
  final String imagePath;

  const CropScreen({super.key, required this.imagePath});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _key = GlobalKey();
  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    HapticFeedback.lightImpact();
    try {
      final boundary = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.of(context).pop(widget.imagePath);
        return;
      }
      final image = await boundary.toImage(pixelRatio: 2.2);
      final jpeg = await PhotoService.encodeJpeg(image);
      image.dispose();
      if (!mounted) return;
      Navigator.of(context).pop(jpeg ?? widget.imagePath);
    } catch (_) {
      if (mounted) Navigator.of(context).pop(widget.imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final side = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Crop photo',
            style: wt(Theme.of(context).textTheme.titleMedium,
                weight: 700, color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Square viewport with the interactive image.
            RepaintBoundary(
              key: _key,
              child: ClipRect(
                child: SizedBox(
                  width: side,
                  height: side,
                  child: InteractiveViewer(
                    transformationController: _transform,
                    minScale: 1,
                    maxScale: 4,
                    child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Pinch to zoom, drag to adjust',
                style: wt(Theme.of(context).textTheme.bodySmall,
                    weight: 500, color: Colors.white70)),
            const SizedBox(height: 20),
            ScaleTap(
              onTap: _done,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('Done',
                    style: wt(Theme.of(context).textTheme.labelLarge,
                        weight: 800, color: AppColors.darkBg)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

