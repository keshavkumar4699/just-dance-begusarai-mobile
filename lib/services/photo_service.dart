/// Just Dance — photo pipeline: pick (camera/gallery) -> square crop ->
/// 640px on-device compression -> app documents folder.
/// Uses only dart:ui codecs (no extra packages); on any failure the original
/// file is copied instead so a pick is never lost.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PhotoService {
  PhotoService._();
  static final PhotoService instance = PhotoService._();

  final _picker = ImagePicker();

  Future<XFile?> pick(ImageSource source) async {
    try {
      return await _picker.pickImage(source: source, imageQuality: 95);
    } catch (e) {
      debugPrint('photo pick failed: $e');
      return null; // permission denied / cancelled
    }
  }

  Future<Directory> _photosDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/photos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Saves [bytes] (any format) as a 640px square JPEG-quality image.
  /// If [crop] is given (in natural pixels) that rect is used, else a centered
  /// square. Falls back to copying the original file on decode failure.
  Future<String> saveCompressed(
    Uint8List bytes, {
    ui.Rect? crop,
    String prefix = 'stu',
    String? fallbackPath,
  }) async {
    final dir = await _photosDir();
    final out = File(
        '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      var src = crop ??
          _centerSquare(img.width.toDouble(), img.height.toDouble());
      src = _clamp(src, img.width.toDouble(), img.height.toDouble());

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
      canvas.drawImageRect(
          img, src, const ui.Rect.fromLTWH(0, 0, 640, 640), paint);
      final picture = recorder.endRecording();
      final rendered = await picture.toImage(640, 640);
      final data =
          await rendered.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      rendered.dispose();
      if (data == null) throw StateError('encode failed');
      await out.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return out.path;
    } catch (e) {
      debugPrint('compress failed, copying original: $e');
      if (fallbackPath != null) {
        try {
          await File(fallbackPath).copy(out.path);
          return out.path;
        } catch (_) {}
      }
      await out.writeAsBytes(bytes, flush: true);
      return out.path;
    }
  }

  ui.Rect _centerSquare(double w, double h) {
    final side = w < h ? w : h;
    return ui.Rect.fromLTWH((w - side) / 2, (h - side) / 2, side, side);
  }

  ui.Rect _clamp(ui.Rect r, double w, double h) {
    final double maxSide = w < h ? w : h;
    var side = r.width < r.height ? r.width : r.height;
    side = side.clamp(1.0, maxSide);
    final left = r.left.clamp(0.0, w - side);
    final top = r.top.clamp(0.0, h - side);
    return ui.Rect.fromLTWH(left, top, side, side);
  }


  Future<void> deleteFile(String path) async {
    if (path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ---------------- backup helpers ----------------

  /// Reads the photo at [path] and returns it as a compact JPEG base64
  /// string (ideal for embedding in Drive backups), or null on any failure.
  Future<String?> readAsJpegBase64(String path) async {
    try {
      final f = File(path);
      if (!await f.exists()) return null;
      final bytes = await f.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return base64Encode(bytes); // keep original bytes as-is
      }
      final jpeg = img.encodeJpg(decoded, quality: 85);
      return base64Encode(jpeg);
    } catch (e) {
      debugPrint('photo -> base64 failed: $e');
      return null;
    }
  }

  /// Writes base64 photo bytes into the photos dir and returns the new path.
  Future<String?> writeFromBase64(String b64, String prefix) async {
    try {
      final bytes = base64Decode(b64);
      final dir = await _photosDir();
      final out = File(
          '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await out.writeAsBytes(bytes, flush: true);
      return out.path;
    } catch (e) {
      debugPrint('base64 -> photo failed: $e');
      return null;
    }
  }
}
