import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../services/photo_service.dart';
import '../../services/settings_service.dart';
import '../../services/template_service.dart';
import '../../services/whatsapp_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common.dart';
import '../../widgets/id_card_widget.dart';
import '../../widgets/invoice_widget.dart';

/// Welcome Kit bottom sheet - one-tap actions right after adding a member:
///  1. Welcome Message  -> wa.me WELCOME template
///  2. Send ID Card     -> WhatsApp of student with ID card JPG
///  3. Send Invoice     -> WhatsApp of student with invoice image
class WelcomeKitSheet extends StatefulWidget {
  final Student student;
  final ({int base, int discount, int admissionDue, int total, int paid, int balance}) summary;
  final String planName;
  final String courseLine;

  const WelcomeKitSheet({
    super.key,
    required this.student,
    required this.summary,
    required this.planName,
    required this.courseLine,
  });

  @override
  State<WelcomeKitSheet> createState() => _WelcomeKitSheetState();
}

class _WelcomeKitSheetState extends State<WelcomeKitSheet> {
  bool _busy = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendWelcome() async {
    if (_busy) return;
    setState(() => _busy = true);
    final state = AppState.instance;
    final st = state.statusFor(widget.student);
    final template = await SettingsService.instance.templateText(TemplateKeys.welcome);
    final values = TemplateService.valuesFor(
      student: widget.student,
      studio: state.studio.name,
      address: state.studio.address,
      cyclePrice: st.cyclePrice,
      planName: widget.planName,
      courseName: widget.courseLine,
      paidTill: st.paidTill != null ? Dates.fmt(st.paidTill!) : null,
      due: 0,
      today: state.today,
    );
    final text = TemplateService.fill(template, values);
    final ok = await WhatsAppService.openChat(widget.student.mobile, text);
    setState(() => _busy = false);
    if (!ok) _snack('No WhatsApp on this number');
  }

  Future<void> _sendIdCard() async {
    if (_busy) return;
    setState(() => _busy = true);
    final state = AppState.instance;
    final st = state.statusFor(widget.student);
    final jpeg = await DocumentService.renderToJpeg(
      IdCardWidget(
        student: widget.student,
        studio: state.studio,
        status: st,
        courseLine: widget.courseLine,
        planName: widget.planName,
      ),
      size: const Size(360, 560),
    );
    if (jpeg == null) {
      setState(() => _busy = false);
      _snack('Could not create ID card image');
      return;
    }
    final template = await SettingsService.instance.templateText(TemplateKeys.idCard);
    final values = TemplateService.valuesFor(
      student: widget.student,
      studio: state.studio.name,
      address: state.studio.address,
      cyclePrice: st.cyclePrice,
      planName: widget.planName,
      courseName: widget.courseLine,
      paidTill: st.paidTill != null ? Dates.fmt(st.paidTill!) : null,
      due: 0,
      today: state.today,
    );
    final text = TemplateService.fill(template, values);
    final ok = await WhatsAppService.shareImageToWhatsApp(
      filePath: jpeg,
      mobile: widget.student.mobile,
      text: text,
    );
    setState(() => _busy = false);
    if (!ok) await WhatsAppService.shareFile(jpeg, text: text);
  }

  Future<void> _sendInvoice() async {
    if (_busy) return;
    setState(() => _busy = true);
    final s = widget.summary;
    final lines = <InvoiceLine>[
      if (s.admissionDue > 0) InvoiceLine('Admission Fee', s.admissionDue),
      InvoiceLine('Membership (${_planMonths()} month${_planMonths() == 1 ? '' : 's'})', s.base),
      if (s.discount > 0) InvoiceLine('Discount', -s.discount),
    ];
    final jpeg = await DocumentService.renderToJpeg(
      InvoiceWidget(
        student: widget.student,
        studio: AppState.instance.studio,
        lines: lines,
        total: s.base + s.admissionDue - s.discount,
        paid: s.paid,
        balance: s.balance,
        planName: widget.planName,
        courseLine: widget.courseLine,
      ),
      size: const Size(560, 720),
    );
    if (jpeg == null) {
      setState(() => _busy = false);
      _snack('Could not create invoice image');
      return;
    }
    final ok = await WhatsAppService.shareImageToWhatsApp(
      filePath: jpeg,
      mobile: widget.student.mobile,
      text: 'Invoice - ${widget.student.jdNo}',
    );
    setState(() => _busy = false);
    if (!ok) await WhatsAppService.shareFile(jpeg, text: 'Invoice');
  }

  int _planMonths() {
    final p = AppState.instance.planById(widget.student.planId);
    return p?.months ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Avatar(photoPath: widget.student.photoPath, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, ${widget.student.name}!',
                          style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
                      Text('${widget.student.jdNo}  •  ${widget.student.mobile}',
                          style: wt(Theme.of(context).textTheme.labelSmall,
                              weight: 700, color: AppColors.gold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _kitButton(
              icon: Icons.chat_bubble_outline,
              label: 'Welcome Message',
              sub: 'Send the welcome template on WhatsApp',
              gold: true,
              onTap: _busy ? null : _sendWelcome,
            ),
            const SizedBox(height: 10),
            _kitButton(
              icon: Icons.badge_outlined,
              label: 'Send ID Card',
              sub: 'Opens WhatsApp with the ID card attached',
              onTap: _busy ? null : _sendIdCard,
            ),
            const SizedBox(height: 10),
            _kitButton(
              icon: Icons.receipt_long_outlined,
              label: 'Send Invoice',
              sub: 'Opens WhatsApp with the invoice attached',
              onTap: _busy ? null : _sendInvoice,
            ),
            const SizedBox(height: 14),
            Center(
              child: Text('All buttons open WhatsApp of ${widget.student.mobile}',
                  style: wt(Theme.of(context).textTheme.labelSmall,
                      weight: 500, color: AppColors.greyIcon)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kitButton({
    required IconData icon,
    required String label,
    required String sub,
    VoidCallback? onTap,
    bool gold = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ScaleTap(
      onTap: onTap == null ? null : () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: gold ? AppColors.gold.withValues(alpha: 0.13) : scheme.outline.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: gold ? Border.all(color: AppColors.gold.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: gold ? AppColors.gold : scheme.onSurface),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
                Text(sub,
                    style: wt(Theme.of(context).textTheme.bodySmall,
                        weight: 500, color: AppColors.greyIcon)),
              ],
            ),
            const Spacer(),
            if (_busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
              )
            else
              const Icon(Icons.chevron_right, size: 20, color: AppColors.greyIcon),
          ],
        ),
      ),
    );
  }
}
