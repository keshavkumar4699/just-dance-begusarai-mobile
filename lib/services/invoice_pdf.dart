/// Just Dance — PDF invoice generation (pure Dart, offline).
/// Two layouts: the COURSE/PLAN invoice (months allocated + valid till) and
/// the PERSONAL TRAINING invoice (sessions allocated). Amounts use "Rs."
/// instead of the rupee symbol.
library;

import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/utils.dart';
import '../data/models.dart';
import '../data/store.dart';

/// Pure invoice math — unit-testable without rendering a PDF.
class InvoiceMath {
  static double total({required double gross, required double discount}) =>
      gross - discount;

  static int sessionsAllocated(double paid, double sessionPrice) =>
      sessionPrice > 0 ? (paid / sessionPrice).floor() : 0;
}

class InvoicePdf {
  InvoicePdf._();
  static final InvoicePdf instance = InvoicePdf._();

  static const _gold = PdfColor.fromInt(0xFFC8A24A);
  static const _black = PdfColor.fromInt(0xFF0E0E10);
  static const _muted = PdfColor.fromInt(0xFF6E6E76);
  static const _green = PdfColor.fromInt(0xFF46A758);
  static const _red = PdfColor.fromInt(0xFFE5484D);

  /// "Rs." with Indian grouping: 1500 -> "Rs. 1,500".
  static String rs(num v) {
    final neg = v < 0;
    final abs = v.abs();
    final isInt = abs == abs.roundToDouble();
    final s = isInt
        ? _groupDigits(abs.round())
        : '${_groupDigits(abs.floor())}.${abs.toStringAsFixed(2).split('.').last}';
    return '${neg ? '-Rs. ' : 'Rs. '}$s';
  }

  static String _groupDigits(int v) {
    final s = v.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '${groups.join(',')},$last3';
  }

  /// Course/plan invoice: months allocated + valid till.
  Future<File> generateCourseInvoice({
    required AppStore store,
    required Student s,
    required DateTime date,
    required String courseLine,
    required String planName,
    required int monthsAllocated,
    required DateTime validTill,
    required double admissionFee,
    required double planPrice,
    required double discount,
    required double paid,
    required double balance,
  }) async {
    final doc = await _base(store, date, (ctx, base, b, blk) {
      final gross = planPrice + admissionFee;
      final total = InvoiceMath.total(gross: gross, discount: discount);
      return [
        _memberBlock(
            ctx,
            base,
            b,
            s,
            courseLine,
            [
              _kv('Plan', planName.isEmpty ? '—' : planName, base, b),
              _kv('Months allocated',
                  '$monthsAllocated month${monthsAllocated == 1 ? '' : 's'}',
                  base, b),
              _kv('Valid till', fmtDate(validTill, forceYear: true), base, b),
            ]),
        _amountBlock(ctx, base, b, blk, admissionFee, planPrice, discount,
            total, paid, balance),
      ];
    });
    return _save(doc, 'invoice_${s.jdNo}_${date.millisecondsSinceEpoch}.pdf');
  }

  /// Personal training invoice: sessions allocated.
  Future<File> generatePtInvoice({
    required AppStore store,
    required Student s,
    required DateTime date,
    required int sessionsAllocated,
    required double sessionPrice,
    required double discount,
    required double paid,
    required double balance,
  }) async {
    final doc = await _base(store, date, (ctx, base, b, blk) {
      final gross = sessionsAllocated * sessionPrice;
      final total = InvoiceMath.total(gross: gross, discount: discount);
      final meta = [
        if (s.ptDays.isNotEmpty) s.ptDays,
        if (s.ptTiming.isNotEmpty) s.ptTiming,
      ].join(' · ');
      return [
        _memberBlock(
            ctx,
            base,
            b,
            s,
            'Personal Training',
            [
              _kv('Sessions allocated', '$sessionsAllocated', base, b),
              _kv('Charge per session', rs(sessionPrice), base, b),
              if (meta.isNotEmpty) _kv('Days · Timing', meta, base, b),
            ]),
        _amountBlock(ctx, base, b, blk, 0, gross, discount, total, paid,
            balance),
      ];
    });
    return _save(doc, 'invoice_${s.jdNo}_${date.millisecondsSinceEpoch}.pdf');
  }

  pw.Widget _kv(String label, String value, pw.Font base, pw.Font b) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
                width: 96,
                child: pw.Text(label,
                    style: pw.TextStyle(font: b, fontSize: 9, color: _muted))),
            pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(font: base, fontSize: 9.5, color: _black)),
            ),
          ],
        ),
      );

  pw.Widget _memberBlock(pw.Context ctx, pw.Font base, pw.Font b, Student s,
          String courseLine, List<pw.Widget> rows) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _kv('Member', s.name, base, b),
          _kv('ID No', s.jdNo, base, b),
          _kv('Course', courseLine.isEmpty ? '—' : courseLine, base, b),
          _kv('Receipt date', fmtDate(DateTime.now(), forceYear: true), base, b),
          ...rows,
        ],
      );

  pw.Widget _amountBlock(
      pw.Context ctx,
      pw.Font base,
      pw.Font b,
      pw.Font blk,
      double admissionFee,
      double gross,
      double discount,
      double total,
      double paid,
      double balance) {
    pw.Widget amt(String label, String value, {PdfColor? color, bool bold = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(label,
                    style: pw.TextStyle(font: base, fontSize: 10, color: _black)),
              ),
              pw.Text(value,
                  style: pw.TextStyle(
                      font: bold ? blk : base,
                      fontSize: 10,
                      color: color ?? _black)),
            ],
          ),
        );
    final netCourse = (gross - discount).clamp(0.0, double.infinity);
    final netTotal = netCourse + admissionFee;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 6),
        pw.Container(height: 1, color: _gold),
        pw.SizedBox(height: 8),
        if (admissionFee > 0) ...[
          amt('Admission fee', rs(admissionFee)),
          if (netCourse > 0) amt('Course fee', rs(netCourse)),
        ],
        amt('Total', rs(netTotal), bold: true, color: _gold),
        pw.SizedBox(height: 6),
        pw.Container(height: 1, color: _gold),
        pw.SizedBox(height: 8),
        amt('Paid', rs(paid), bold: true),
        amt(balance > 0 ? 'Balance due' : 'Balance',
            balance > 0 ? rs(balance) : rs(0),
            bold: true, color: balance > 0 ? _red : _green),
      ],
    );
  }

  Future<pw.Document> _base(
    AppStore store,
    DateTime date,
    List<pw.Widget> Function(pw.Context, pw.Font, pw.Font, pw.Font) body,
  ) async {
    final studio = store.studio;
    final base = pw.Font.ttf(await rootBundle.load('fonts/Inter-400.ttf'));
    final b = pw.Font.ttf(await rootBundle.load('fonts/Inter-700.ttf'));
    final blk = pw.Font.ttf(await rootBundle.load('fonts/Inter-800.ttf'));

    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) {
        return [
          pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Column(
              children: [
                pw.Text(studio.name.toUpperCase(),
                    style: pw.TextStyle(
                        font: blk, fontSize: 20, letterSpacing: 3, color: _black)),
                if (studio.address.isNotEmpty)
                  pw.Text(studio.address,
                      style:
                          pw.TextStyle(font: base, fontSize: 9, color: _muted)),
                if (studio.phone.isNotEmpty)
                  pw.Text('Phone: ${studio.phone}',
                      style:
                          pw.TextStyle(font: base, fontSize: 9, color: _muted)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text('FEES RECEIPT',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: b, fontSize: 14, color: _gold, letterSpacing: 6)),
          pw.SizedBox(height: 6),
          pw.Container(height: 1, color: _gold),
          pw.SizedBox(height: 12),
          ...body(ctx, base, b, blk),
          pw.SizedBox(height: 40),
          pw.Text('Thank you!',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: b, fontSize: 13, color: _black)),
          pw.SizedBox(height: 6),
          pw.Text('– ${studio.name}',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: b, fontSize: 11, color: _gold)),
        ];
      },
    ));
    return doc;
  }

  Future<File> _save(pw.Document doc, String name) async {
    final bytes = await doc.save();
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/shared');
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
