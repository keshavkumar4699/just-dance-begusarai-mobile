import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/student.dart';

class IDCardService {
  static Future<void> captureAndShareIDCard(BuildContext context, GlobalKey boundaryKey, Student student) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary not found');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Image data empty');

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final imagePath = p.join(tempDir.path, '${student.jdNo}_id_card.png');
      final file = File(imagePath);
      await file.writeAsBytes(pngBytes);

      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: '🪪 ${student.name} ji, aapki Studio Crow ID card attached hai.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID Card image share nahi ho saka. Dobara try karein.')),
        );
      }
    }
  }

  static Future<void> shareMemberIDCard(BuildContext context, Student student) async {
    // Fallback share text if direct repaint boundary is not available
    try {
      final summaryText = '''
🪪 STUDIO CROW — MEMBER ID CARD
---------------------------------------
Member Name: ${student.name}
ID No: ${student.jdNo}
Category: ${student.category}
Plan: ${student.plan}
Services: ${student.services.join(", ")}
Mobile: ${student.mobile}
---------------------------------------
– Studio Crow Begusarai
''';

      final tempDir = await getTemporaryDirectory();
      final textFilePath = p.join(tempDir.path, '${student.jdNo}_id.txt');
      final file = File(textFilePath);
      await file.writeAsString(summaryText);

      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: '🪪 ${student.name} ji, aapki Studio Crow ID card details attached hain.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID Card share nahi ho saka.')),
        );
      }
    }
  }
}
