import 'package:flutter/material.dart';
import '../models/ledger_entry.dart';
import '../models/student.dart';
import '../services/fee_engine.dart';
import '../services/whatsapp_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class LedgerTableWidget extends StatelessWidget {
  final List<LedgerEntry> entries;
  final Student student;

  const LedgerTableWidget({
    Key? key,
    required this.entries,
    required this.student,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.activeGreen;
      case 'pending':
        return AppColors.pendingAmber;
      case 'overdue':
        return AppColors.overdueRed;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.activeGreenBg;
      case 'pending':
        return AppColors.pendingAmberBg;
      case 'overdue':
        return AppColors.overdueRedBg;
      default:
        return AppColors.surfaceLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'No ledger payment records found.',
          style: AppFonts.subtitleText(color: AppColors.textMuted),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGold, width: 0.5),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Month', style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Paid', style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Mode', style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Status', style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold))),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table Body List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderSubtle),
            itemBuilder: (context, index) {
              final item = entries[index];
              final statusColor = _getStatusColor(item.status);
              final statusBg = _getStatusBg(item.status);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.monthYear, style: AppFonts.bodyText(fontWeight: FontWeight.bold, fontSize: 13)),
                          if (item.paymentDate.isNotEmpty)
                            Text(item.paymentDate, style: AppFonts.subtitleText(fontSize: 10)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        FeeEngine.formatCurrency(item.amountPaid),
                        style: AppFonts.numberText(fontSize: 13, color: AppColors.ivory),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(item.paymentMode, style: AppFonts.bodyText(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppFonts.subtitleText(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: AppColors.gold, size: 18),
                      tooltip: 'Send Receipt via WhatsApp',
                      onPressed: () {
                        WhatsAppService.sendPaymentReceipt(
                          student: student,
                          entry: item,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
