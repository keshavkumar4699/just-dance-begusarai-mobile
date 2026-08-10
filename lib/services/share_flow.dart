import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/date_utils.dart';
import '../widgets/id_card_widget.dart';
import 'photo_service.dart';
import 'settings_service.dart';
import 'template_service.dart';
import 'whatsapp_service.dart';

/// Shared flow: renders a student's ID card JPG and shares it to their WhatsApp.
class ShareFlow {
  /// Renders + shares the ID card to the student's WhatsApp (falls back to
  /// system chooser when WhatsApp is not installed).
  static Future<void> shareIdCard(BuildContext context, Student s) async {
    final state = AppState.instance;
    final st = state.statusFor(s);
    final jpeg = await DocumentService.renderToJpeg(
      IdCardWidget(
        student: s,
        studio: state.studio,
        status: st,
        courseLine: state.primaryCourseLine(s),
        planName: state.planNameOf(s),
      ),
      size: const Size(360, 560),
    );
    if (jpeg == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create ID card image')),
        );
      }
      return;
    }
    final template = await SettingsService.instance.templateText(TemplateKeys.idCard);
    final values = TemplateService.valuesFor(
      student: s,
      studio: state.studio.name,
      address: state.studio.address,
      cyclePrice: st.cyclePrice,
      planName: state.planNameOf(s),
      courseName: state.primaryCourseLine(s),
      paidTill: st.paidTill != null ? Dates.fmt(st.paidTill!) : null,
      due: 0,
      today: state.today,
    );
    final text = TemplateService.fill(template, values);
    final ok = await WhatsAppService.shareImageToWhatsApp(
      filePath: jpeg,
      mobile: s.mobile,
      text: text,
    );
    if (!ok) await WhatsAppService.shareFile(jpeg, text: text);
  }
}
