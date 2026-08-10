
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/date_utils.dart';

/// One-tap WhatsApp + dialer actions (owner presses send - NO automation).
class WhatsAppService {
  static const MethodChannel _channel = MethodChannel('studio_crow/native');

  /// Opens WhatsApp chat with [mobile] prefilled with [text].
  static Future<bool> openChat(String mobile, String text) async {
    final uri = Uri.parse(
        'https://wa.me/${Phones.waNumber(mobile)}?text=${Uri.encodeComponent(text)}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      // wa.me fallback
      return launchUrl(Uri.parse('https://wa.me/${Phones.waNumber(mobile)}'),
          mode: LaunchMode.externalApplication);
    }
    return ok;
  }

  /// Direct share: opens WhatsApp of [mobile] with an attached image (+ optional text).
  /// Returns false when WhatsApp is not installed on this device.
  static Future<bool> shareImageToWhatsApp({
    required String filePath,
    required String mobile,
    String text = '',
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>(
        'shareToWhatsApp',
        {'path': filePath, 'number': mobile, 'text': text},
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Fallback share (used when WhatsApp is missing) - system chooser.
  static Future<void> shareFile(String filePath, {String text = ''}) async {
    await Share.shareXFiles([XFile(filePath)], text: text, subject: 'Studio Crow');
  }

  /// Opens the dialer with the student's mobile.
  static Future<void> call(String mobile) async {
    final uri = Uri.parse(Phones.tel(mobile));
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
