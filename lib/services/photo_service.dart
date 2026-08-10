import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Photo handling: pick (camera/gallery), square crop, 640px JPEG compression.
/// JPEG encoding runs on the native side (no extra packages).
class PhotoService {
  static const MethodChannel _channel = MethodChannel('studio_crow/native');

  /// Picks an image from camera or gallery. Returns null on cancel.
  static Future<String?> pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 92,
    );
    return picked?.path;
  }

  /// Compresses a photo to max 640px JPEG. On failure returns the original path.
  static Future<String> compress(String path) async {
    try {
      final out = await _channel.invokeMethod<String>('compressImage', {'path': path});
      if (out != null && File(out).existsSync()) return out;
    } catch (_) {}
    return path;
  }

  /// Encodes PNG bytes into a JPEG file (used for rendered ID cards / invoices).
  static Future<String?> encodeJpeg(ui.Image image, {int quality = 88}) async {
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;
      final out = await _channel.invokeMethod<String>('encodeJpeg', {
        'width': image.width,
        'height': image.height,
        'png': data.buffer.asUint8List(),
        'quality': quality,
      });
      return out;
    } catch (_) {
      return null;
    }
  }

  /// True when the device is on Wi-Fi (Wi-Fi-only backup setting).
  static Future<bool> isOnWifi() async {
    try {
      return await _channel.invokeMethod<bool>('isWifi') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Deletes a photo file (used when a student is deleted).
  static void deleteFile(String path) {
    try {
      final f = File(path);
      if (f.existsSync() && f.path.contains('/')) f.deleteSync();
    } catch (_) {}
  }
}

/// Captures any widget offscreen and returns it as a JPEG file path.
/// Used to render ID cards, invoices and welcome kit images for WhatsApp.
class DocumentService {
  /// Renders [child] at [size] (logical px) and returns a JPEG path.
  static Future<String?> renderToJpeg(
    Widget child, {
    required Size size,
    double pixelRatio = 2.2,
  }) async {
    final key = GlobalKey();
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return null;

    final entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned(
            left: 20000, // offscreen, invisible to the user
            top: 0,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(entry);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final jpeg = await PhotoService.encodeJpeg(image);
      image.dispose();
      return jpeg;
    } finally {
      entry.remove();
    }
  }
}

/// Global navigator key so non-widget services can push routes.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
