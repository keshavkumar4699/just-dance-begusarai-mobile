import 'dart:io';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/models.dart';
import '../utils/date_utils.dart';

/// Black + gold ID card - shown on Student Detail and rendered as a JPG for
/// WhatsApp share. 360x560 logical px (portrait 9:14).
class IdCardWidget extends StatelessWidget {
  final Student student;
  final StudioInfo studio;
  final StudentStatus status;
  final String courseLine;
  final String planName;

  const IdCardWidget({
    super.key,
    required this.student,
    required this.studio,
    required this.status,
    required this.courseLine,
    required this.planName,
  });

  @override
  Widget build(BuildContext context) {
    final paidTill = status.paidTill != null ? Dates.display(Dates.fmt(status.paidTill!)) : '--';

    // Status strip.
    final String stripText;
    final Color stripColor;
    if (status.totalDue > 0) {
      stripText = 'FEES DUE ${Money.fmt(status.totalDue)}';
      stripColor = AppColors.expired;
    } else if (status.credit > 0) {
      stripText = 'FEES PAID  + ADVANCE ${Money.fmt(status.credit)}';
      stripColor = AppColors.active;
    } else {
      stripText = 'FEES PAID';
      stripColor = AppColors.active;
    }

    return Container(
      width: 360,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: logo + studio.
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 1.2),
                ),
                padding: const EdgeInsets.all(7),
                child: ClipOval(
                  child: studio.logoPath.isNotEmpty
                      ? Image.file(File(studio.logoPath), fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset('assets/images/logo.png', fit: BoxFit.cover))
                      : Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (studio.name.isEmpty ? 'Studio Crow' : studio.name).toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 2.2,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MEMBERSHIP ID CARD',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 8.5,
                      letterSpacing: 1.8,
                      color: Color(0xFF8B8B93),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                student.jdNo,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Photo + identity.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: student.photoPath.isNotEmpty
                    ? Image.file(File(student.photoPath), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset('assets/images/placeholder.png', fit: BoxFit.cover))
                    : Image.asset('assets/images/placeholder.png', fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: Color(0xFFF5F1E8),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (student.fatherName.isNotEmpty)
                      Text(
                        student.fatherName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11.5,
                          color: Color(0xFFB9B4A8),
                        ),
                      ),
                    const SizedBox(height: 8),
                    _kv('CATEGORY', _categoryText()),
                    _kv('MOBILE', student.mobile),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.gold.withValues(alpha: 0.35), height: 1),
          const SizedBox(height: 12),
          _kv('COURSE / BATCH / TIMING', courseLine.isEmpty ? '--' : courseLine),
          _kv('PLAN', planName.isEmpty ? '--' : planName),
          Row(
            children: [
              Expanded(child: _kv('VALID TILL', paidTill)),
              Expanded(child: _kv('JOINED', Dates.display(student.admissionDate))),
            ],
          ),
          const Spacer(),
          // Status strip.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: stripColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: stripColor.withValues(alpha: 0.6)),
            ),
            child: Text(
              stripText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 1.2,
                color: stripColor == AppColors.active ? const Color(0xFF46A758) : stripColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              '${studio.name.isEmpty ? 'Studio Crow' : studio.name}  •  ${studio.contact}',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 9,
                color: Color(0xFF8B8B93),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryText() {
    var cat = student.gender.toLowerCase() == 'male' || student.gender.toLowerCase() == 'female'
        ? categoryFor(dob: student.dob.isEmpty ? null : Dates.parse(student.dob))
        : '';
    if (cat.isEmpty) cat = student.gender;
    return cat.isEmpty ? '--' : cat;
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              k,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 8.5,
                letterSpacing: 1.4,
                color: Color(0xFF8B8B93),
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                color: Color(0xFFF5F1E8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

