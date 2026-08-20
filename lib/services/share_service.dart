/// Just Dance — sharing: direct-to-WhatsApp image share (native channel),
/// with share_plus as fallback when WhatsApp is unavailable.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../core/utils.dart';

class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  static const _channel = MethodChannel('studio_crow/share');

  /// Shares [path] straight into the WhatsApp chat of [mobile].
  /// Returns false when WhatsApp is not installed / share failed.
  Future<bool> imageToWhatsApp({
    required String mobile,
    required String imagePath,
    String text = '',
  }) =>
      _shareToWhatsApp(mobile: mobile, path: imagePath, text: text);

  /// Same as [imageToWhatsApp] but for documents (PDF invoices).
  Future<bool> documentToWhatsApp({
    required String mobile,
    required String path,
    String text = '',
  }) =>
      _shareToWhatsApp(mobile: mobile, path: path, text: text,
          type: 'application/pdf');

  Future<bool> _shareToWhatsApp({
    required String mobile,
    required String path,
    String text = '',
    String type = 'image/jpeg',
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>('shareToWhatsApp', {
        'phone': kCountryCode + normalizeMobile(mobile),
        'path': path,
        'text': text,
        'type': type,
      });
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Generic system share sheet fallback.
  Future<void> shareImage(String imagePath, {String text = ''}) async {
    await Share.shareXFiles([XFile(imagePath)], text: text);
  }

  Future<bool> whatsappInstalled() async {
    try {
      final f = File('/data/data/com.whatsapp');
      return await f.exists();
    } catch (_) {
      return true; // cannot query — assume installed
    }
  }
}
