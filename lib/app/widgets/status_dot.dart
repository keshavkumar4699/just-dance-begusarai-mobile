import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../models/student.dart';

class StatusDot extends StatelessWidget {
  final MemberStatus status;
  final bool showLabel;

  const StatusDot({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  static Color getStatusColor(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return AppColors.statusActive;
      case MemberStatus.nearExpiry:
        return AppColors.statusNearExpiry;
      case MemberStatus.expired:
        return AppColors.statusExpired;
      case MemberStatus.inactive:
        return AppColors.statusInactive;
      case MemberStatus.blocked:
        return AppColors.statusBlocked;
    }
  }

  static String getStatusLabel(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return 'Active';
      case MemberStatus.nearExpiry:
        return 'Near Expiry';
      case MemberStatus.expired:
        return 'Expired';
      case MemberStatus.inactive:
        return 'Inactive';
      case MemberStatus.blocked:
        return '🚫 Blocked';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(status);
    final label = getStatusLabel(status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
