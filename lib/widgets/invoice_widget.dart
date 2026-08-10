import 'dart:io';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/models.dart';
import '../utils/date_utils.dart';

/// Invoice image rendered at admission / renewal: studio header, student info,
/// fee breakdown, footer "– {studio}". 560x740 logical px.
class InvoiceWidget extends StatelessWidget {
  final Student student;
  final StudioInfo studio;
  final List<InvoiceLine> lines;
  final int total;
  final int paid;
  final int balance; // positive = advance, negative = baki
  final String planName;
  final String courseLine;

  const InvoiceWidget({
    super.key,
    required this.student,
    required this.studio,
    required this.lines,
    required this.total,
    required this.paid,
    required this.balance,
    required this.planName,
    required this.courseLine,
  });

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFFAF8F4);
    final ink = const Color(0xFF141414);
    final gold = AppColors.gold;
    final grey = const Color(0xFF8B8B93);

    return Container(
      width: 560,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gold, width: 1.2),
                ),
                padding: const EdgeInsets.all(8),
                child: ClipOval(
                  child: studio.logoPath.isNotEmpty
                      ? Image.file(File(studio.logoPath), fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset('assets/images/logo.png', fit: BoxFit.cover))
                      : Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (studio.name.isEmpty ? 'Studio Crow' : studio.name).toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: 1.5,
                        color: ink,
                      ),
                    ),
                    if (studio.address.isNotEmpty)
                      Text(
                        studio.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 10.5, color: grey),
                      ),
                  ],
                ),
              ),
              Text(
                'INVOICE',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 3,
                  color: gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: gold.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 14),
          // Student info.
          _row('Member', student.name, ink, grey),
          _row('ID No', student.jdNo, ink, grey),
          _row('Course', courseLine, ink, grey),
          _row('Plan', planName.isEmpty ? '--' : planName, ink, grey),
          _row('Date', Dates.display(Dates.todayStr()), ink, grey),
          const SizedBox(height: 10),
          Divider(color: gold.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 10),
          // Fee lines.
          for (final l in lines) _row(l.label, Money.fmt(l.amount), ink, grey),
          const SizedBox(height: 6),
          Divider(color: gold.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 8),
          _row('TOTAL', Money.fmt(total), ink, ink, bold: true),
          _row('PAID', Money.fmt(paid), ink, const Color(0xFF46A758), bold: true),
          _row(
            balance >= 0 ? 'ADVANCE' : 'BALANCE',
            Money.fmt(balance.abs()),
            ink,
            balance >= 0 ? const Color(0xFF46A758) : const Color(0xFFE5484D),
            bold: true,
          ),
          const Spacer(),
          Center(
            child: Text(
              'Thank you! - ${studio.name.isEmpty ? 'Studio Crow' : studio.name}',
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, color: grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color ink, Color valueColor, {bool bold = false}) {
    final grey = const Color(0xFF8B8B93);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11.5,
                color: grey,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12.5,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceLine {
  final String label;
  final int amount;
  const InvoiceLine(this.label, this.amount);
}

