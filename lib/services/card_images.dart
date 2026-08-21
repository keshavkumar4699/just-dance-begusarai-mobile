/// Just Dance — offscreen rendering of shareable images (ID card, invoice).
/// Drawn with dart:ui canvases (no extra packages); saved as .jpg files into
/// the app cache "shared" folder for the WhatsApp share intent.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../core/utils.dart';
import '../data/fee_engine.dart';
import '../data/models.dart';
import '../data/store.dart';

class CardImages {
  CardImages._();
  static final CardImages instance = CardImages._();

  static const gold = ui.Color(0xFFC8A24A);
  static const black = ui.Color(0xFF0E0E10);
  static const ivory = ui.Color(0xFFF5F1E8);
  static const muted = ui.Color(0xFF8B8B93);
  static const hairline = ui.Color(0x29FFFFFF);

  ui.Image? _logoCache;

  Future<ui.Image?> _logo(StudioInfo studio) async {
    try {
      if (studio.photoPath.isNotEmpty &&
          await File(studio.photoPath).exists()) {
        final bytes = await File(studio.photoPath).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        return (await codec.getNextFrame()).image;
      }
      final cached = _logoCache;
      if (cached != null) return cached;
      final data = await rootBundle.load('assets/logo.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final img = (await codec.getNextFrame()).image;
      _logoCache = img;
      return img;
    } catch (_) {
      return null;
    }
  }

  Future<ui.Image?> _photo(String path) async {
    try {
      if (path.isEmpty) return null;
      final f = File(path);
      if (!await f.exists()) return null;
      final bytes = await f.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }

  void _text(
    ui.Canvas canvas,
    String text,
    ui.Offset at, {
    double size = 28,
    ui.Color color = ivory,
    FontWeight weight = FontWeight.w400,
    double maxWidth = 400,
    TextAlign align = TextAlign.left,
    int maxLines = 1,
    double letterSpacing = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size,
          color: color,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      ),
      textAlign: align,
      textDirection: ui.TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, at);
  }

  void _roundRectImage(ui.Canvas canvas, ui.Image img, ui.Rect dst,
      {double radius = 24}) {
    canvas.save();
    canvas.clipRRect(ui.RRect.fromRectAndRadius(dst, ui.Radius.circular(radius)));
    final srcSide = img.width < img.height ? img.width.toDouble() : img.height.toDouble();
    final src = ui.Rect.fromLTWH(
        (img.width - srcSide) / 2, (img.height - srcSide) / 2, srcSide, srcSide);
    canvas.drawImageRect(img, src, dst, ui.Paint()..filterQuality = ui.FilterQuality.medium);
    canvas.restore();
  }

  Future<File> _save(ui.PictureRecorder recorder, int w, int h, String name) async {
    final pic = recorder.endRecording();
    final img = await pic.toImage(w, h);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/shared');
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}/$name.jpg');
    await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    return file;
  }

  // ---------------- ID CARD (1080 x 680, black + gold) ----------------

  Future<File> generateIdCard({
    required AppStore store,
    required Student s,
    required FeeStatus status,
  }) async {
    const w = 1080, h = 760;
    final recorder = ui.PictureRecorder();
    final c = ui.Canvas(recorder);
    final studio = store.studio;

    // Card body
    final cardRect = ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    final rrect = ui.RRect.fromRectAndRadius(cardRect, const ui.Radius.circular(36));
    c.drawRRect(rrect, ui.Paint()..color = black);
    c.drawRRect(
        rrect,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = gold);
    final inner = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(14, 14, w - 28, h - 28), const ui.Radius.circular(28));
    c.drawRRect(
        inner,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = hairline);

    // Header: logo + studio name
    final logo = await _logo(studio);
    if (logo != null) {
      _roundRectImage(c, logo, const ui.Rect.fromLTWH(48, 44, 96, 96), radius: 20);
    }
    _text(c, studio.name.toUpperCase(), const ui.Offset(168, 56),
        size: 40, weight: FontWeight.w800, maxWidth: 760, letterSpacing: 2);
    if (studio.address.isNotEmpty) {
      _text(c, studio.address, const ui.Offset(168, 106),
          size: 22, color: muted, maxWidth: 760);
    }
    _text(c, 'MEMBER ID CARD', const ui.Offset(w - 48 - 300, 66),
        size: 20, color: gold, weight: FontWeight.w700, maxWidth: 300, align: TextAlign.right, letterSpacing: 3);

    // Divider
    c.drawRect(const ui.Rect.fromLTWH(48, 168, w - 96, 1), ui.Paint()..color = hairline);

    // Photo
    final photo = await _photo(s.photoPath);
    final photoRect = const ui.Rect.fromLTWH(48, 208, 300, 380);
    if (photo != null) {
      _roundRectImage(c, photo, photoRect, radius: 20);
    } else {
      c.drawRRect(
          ui.RRect.fromRectAndRadius(photoRect, const ui.Radius.circular(20)),
          ui.Paint()..color = const ui.Color(0xFF1C1C20));
      _text(c, s.name.isEmpty ? '?' : s.name.characters.first.toUpperCase(),
          ui.Offset(photoRect.left, photoRect.top + 130),
          size: 110, color: gold, weight: FontWeight.w700,
          maxWidth: photoRect.width, align: TextAlign.center);
    }

    // Fields
    final x = 396.0;
    var y = 212.0;
    void field(String label, String value) {
      _text(c, label.toUpperCase(), ui.Offset(x, y),
          size: 18, color: muted, weight: FontWeight.w600, letterSpacing: 1.6, maxWidth: 620);
      _text(c, value, ui.Offset(x, y + 26),
          size: 28, weight: FontWeight.w600, maxWidth: 620);
      y += 80;
    }

    field('Name', s.name);
    field("Father's Name", s.fatherName.isEmpty ? '—' : s.fatherName);
    field('ID No  ·  Category', '${s.jdNo}  ·  ${categoryFor(s.dob, s.gender)}');
    // Compact course line (course · batch) so long day/duration strings
    // never push the card layout out of order.
    final scs = store.coursesOf(s.id);
    StudentCourse? primary;
    if (scs.isNotEmpty) {
      primary = scs.first;
      for (final e in scs) {
        if (e.isPrimary) primary = e;
      }
    }
    final bLabel =
        primary == null ? '' : AppStore.batchShortLabel(primary.batchId);
    final interestNames = <String>[];
    if (primary != null && primary.interests.isNotEmpty) {
      final ids = primary.interests
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>();
      for (final id in ids) {
        final ci = store.interestById(id);
        if (ci != null) interestNames.add(ci.name);
      }
    }
    final courseName =
        primary == null ? '—' : (store.courseById(primary.courseId)?.name ?? '—');
    final courseDisplay = [
      courseName,
      if (bLabel.isNotEmpty) bLabel,
      if (interestNames.isNotEmpty) interestNames.join(', '),
    ].join('  ·  ');
    field('Course', courseDisplay);
    final plan = store.planById(s.planId);
    field('Plan  ·  Valid Till',
        '${plan?.name ?? '—'}  ·  ${fmtDate(status.paidTill, forceYear: true)}');
    field('Mobile', s.mobile);

    // Status strip at card bottom-right area
    final stripText = status.hasDue
        ? 'FEES DUE ${fmtMoney(status.due)}'
        : (status.advance > 0
            ? 'FEES PAID  (+ADVANCE ${fmtMoney(status.advance)})'
            : 'FEES PAID');
    final stripColor = status.hasDue
        ? const ui.Color(0xFFE5484D)
        : const ui.Color(0xFF46A758);
    _text(c, stripText, ui.Offset(x, h - 52),
        size: 24, color: stripColor, weight: FontWeight.w800, maxWidth: 620, letterSpacing: 1);

    return _save(recorder, w, h, 'id_${s.jdNo}');
  }

  // ---------------- INVOICE (1080 x 1560) ----------------

  Future<File> generateInvoice({
    required AppStore store,
    required Student s,
    required DateTime date,
    required String courseLine,
    required String planName,
    required double admissionFee,
    required double planPrice,
    required double discount,
    required double paid,
    required double balance,
  }) async {
    const w = 1080, h = 1560;
    final recorder = ui.PictureRecorder();
    final c = ui.Canvas(recorder);
    final studio = store.studio;

    c.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        ui.Paint()..color = black);
    c.drawRect(const ui.Rect.fromLTWH(28, 28, w - 56, h - 56),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = gold);
    c.drawRect(const ui.Rect.fromLTWH(40, 40, w - 80, h - 80),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = hairline);

    final logo = await _logo(studio);
    if (logo != null) {
      _roundRectImage(c, logo, const ui.Rect.fromLTWH((w - 120) / 2, 80, 120, 120),
          radius: 24);
    }
    _text(c, studio.name.toUpperCase(), const ui.Offset(80, 224),
        size: 44, weight: FontWeight.w800, maxWidth: w - 160, align: TextAlign.center, letterSpacing: 3);
    var subY = 282.0;
    if (studio.address.isNotEmpty) {
      _text(c, studio.address, ui.Offset(80, subY),
          size: 24, color: muted, maxWidth: w - 160, align: TextAlign.center);
      subY += 36;
    }
    if (studio.phone.isNotEmpty) {
      _text(c, studio.phone, ui.Offset(80, subY),
          size: 24, color: muted, maxWidth: w - 160, align: TextAlign.center);
    }

    _text(c, 'FEES RECEIPT', const ui.Offset(80, 384),
        size: 26, color: gold, weight: FontWeight.w700,
        maxWidth: w - 160, align: TextAlign.center, letterSpacing: 6);
    c.drawRect(const ui.Rect.fromLTWH(80, 440, w - 160, 1), ui.Paint()..color = hairline);

    // Student block
    var y = 480.0;
    void row(String label, String value, {bool bold = false, ui.Color? color}) {
      _text(c, label, ui.Offset(96, y),
          size: 26, color: muted, maxWidth: 420);
      _text(c, value, ui.Offset(520, y),
          size: 26, color: color ?? ivory,
          weight: bold ? FontWeight.w700 : FontWeight.w500,
          maxWidth: w - 96 - 520, align: TextAlign.right);
      y += 62;
    }

    row('Receipt date', fmtDate(date, forceYear: true));
    row('Member', s.name);
    row('ID No', s.jdNo);
    row('Course', courseLine.isEmpty ? '—' : courseLine);
    row('Plan', planName.isEmpty ? '—' : planName);
    y += 12;
    c.drawRect(ui.Rect.fromLTWH(96, y, w - 192, 1), ui.Paint()..color = hairline);
    y += 34;

    final netPlan = (planPrice - discount).clamp(0.0, double.infinity);
    final netTotal = netPlan + admissionFee;
    if (admissionFee > 0) {
      row('Admission fee', fmtMoney(admissionFee));
      if (netPlan > 0) row('Course fee', fmtMoney(netPlan));
    }
    row('Total', fmtMoney(netTotal), bold: true, color: gold);
    c.drawRect(ui.Rect.fromLTWH(96, y, w - 192, 1), ui.Paint()..color = hairline);
    y += 34;
    row(balance > 0 ? 'Balance due' : 'Balance',
        balance > 0 ? fmtMoney(balance) : fmtMoney(0),
        bold: true,
        color: balance > 0 ? const ui.Color(0xFFE5484D) : const ui.Color(0xFF46A758));

    // Footer
    _text(c, 'Thank you!', const ui.Offset(80, h - 220),
        size: 30, weight: FontWeight.w600, maxWidth: w - 160, align: TextAlign.center);
    _text(c, '– ${studio.name}', const ui.Offset(80, h - 160),
        size: 26, color: gold, weight: FontWeight.w700, maxWidth: w - 160, align: TextAlign.center);

    return _save(recorder, w, h, 'invoice_${s.jdNo}_${date.millisecondsSinceEpoch}');
  }
}
