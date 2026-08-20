/// Just Dance — WhatsApp Templates: 4 editable templates with placeholder
/// chips, live preview, and one-tap self-test (opens the owner's own chat).
library;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/store.dart';
import '../../services/whatsapp_service.dart';
import '../widgets/common.dart';

class TemplatesScreen extends StatefulWidget {
  final AppStore store;
  const TemplatesScreen({super.key, required this.store});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  late final Map<String, TextEditingController> _controllers;

  static const _meta = {
    kTemplateWelcome: ('WELCOME', Icons.waving_hand_outlined),
    kTemplateFeeCollected: ('FEE COLLECTED', Icons.payments_outlined),
    kTemplateFeesDue: ('FEES DUE', Icons.notification_important_outlined),
    kTemplateSendId: ('SEND ID CARD', Icons.badge_outlined),
  };

  AppStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final e in kDefaultTemplates.entries)
        e.key: TextEditingController(text: store.templates[e.key])
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String?> get _sample => {
        '{name}': 'Rahul',
        '{id}': 'JD-001',
        '{plan}': 'Monthly',
        '{course}': store.courses.isEmpty
            ? 'Strength Training'
            : store.courses.first.name,
        '{validTill}': fmtDate(addMonths(DateTime.now(), 1), forceYear: true),
        '{amount}': fmtMoney(
            store.courses.isEmpty ? 1500 : store.courses.first.fee),
        '{due}':
            fmtMoney(store.courses.isEmpty ? 1500 : store.courses.first.fee),
        '{month}': monthLabel(DateTime.now()),
        '{studio}': store.studio.name,
        '{address}': store.studio.address,
      };

  void _insert(TextEditingController c, String token) {
    final sel = c.selection;
    final text = c.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    c.value = TextEditingValue(
      text: text.replaceRange(start, end, token),
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  Future<void> _save() async {
    await store.saveTemplates(
        _controllers.map((k, v) => MapEntry(k, v.text.trim())));
    if (mounted) showSnack(context, 'Templates saved', duration: kSnackSuccess);
  }

  Future<void> _selfTest(String key) async {
    final msg = fillTemplate(_controllers[key]!.text, _sample);
    final target = store.studio.whatsapp.isNotEmpty
        ? store.studio.whatsapp
        : store.studio.phone;
    if (target.isEmpty) {
      showSnack(context, 'Add your WhatsApp number in Studio Info first', duration: kSnackWarn);
      return;
    }
    final ok = await WhatsAppService.instance.openChat(target, msg);
    if (!ok && mounted) showSnack(context, 'Could not open WhatsApp', duration: kSnackError);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp Templates')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(
            'Tap a chip to insert a placeholder. Empty values are removed automatically when sending.',
            style: TextStyle(color: c.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (final e in _meta.entries) _templateCard(c, e.key, e.value),
          const SizedBox(height: 8),
          GoldButton('Save Templates', icon: Icons.check, onTap: _save),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _templateCard(AppColors c, String key, (String, IconData) meta) {
    final (label, icon) = meta;
    final ctrl = _controllers[key]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: c.gold),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _selfTest(key),
                icon: WhatsAppIcon(size: 16, color: c.gold),
                label: Text('Test on me',
                    style: TextStyle(color: c.gold, fontSize: 11.5)),
              ),
            ],
          ),
          TextField(
            controller: ctrl,
            maxLines: 4,
            minLines: 2,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final token in kTemplatePlaceholders)
                Pressable(
                  onTap: () => _insert(ctrl, token),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.goldSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(token,
                        style: TextStyle(
                            color: c.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              fillTemplate(ctrl.text, _sample),
              style: TextStyle(
                  color: c.textMuted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
