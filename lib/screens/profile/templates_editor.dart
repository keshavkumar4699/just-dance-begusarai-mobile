import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../services/template_service.dart';
import '../../services/whatsapp_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// WhatsApp template editor: 4 editable templates with placeholder chips,
/// live preview and one-tap self-test (wa.me to studio contact).
class TemplatesEditor extends StatefulWidget {
  const TemplatesEditor({super.key});

  @override
  State<TemplatesEditor> createState() => _TemplatesEditorState();
}

class _TemplatesEditorState extends State<TemplatesEditor> {
  final Map<String, TextEditingController> _controllers = {};
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    for (final t in AppState.instance.templates) {
      _controllers[t.key] = TextEditingController(text: t.text);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _studioName => AppState.instance.studio.name.isEmpty ? 'Studio Crow' : AppState.instance.studio.name;
  String get _address => AppState.instance.studio.address;

  Future<void> _save() async {
    final list = [
      for (final entry in TemplateKeys.defaults.entries)
        WaTemplate(key: entry.key, text: _controllers[entry.key]?.text ?? entry.value),
    ];
    await AppState.instance.saveTemplates(list);
    _dirty = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Templates saved')),
      );
    }
  }

  Future<void> _selfTest(String key) async {
    final text = TemplateService.preview(
      _controllers[key]?.text ?? '',
      studio: _studioName,
      address: _address,
    );
    final contact = AppState.instance.studio.contact;
    final ok = await WhatsAppService.openChat(contact.isEmpty ? '9000000000' : contact, text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No WhatsApp on this number')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = {
      TemplateKeys.welcome: 'Welcome',
      TemplateKeys.feeCollected: 'Fee Collected',
      TemplateKeys.feesDue: 'Fees Due',
      TemplateKeys.idCard: 'Send ID Card',
    };
    final controllers = _controllers;

    return Scaffold(
      appBar: AppBar(
        title: Text('WhatsApp Templates',
            style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
        actions: [
          if (_dirty)
            TextButton(onPressed: _save, child: const Text('Save',
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          // Placeholder chips legend
          SectionLabel('AVAILABLE PLACEHOLDERS'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in kTemplatePlaceholders)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                  ),
                  child: Text(p,
                      style: wt(Theme.of(context).textTheme.labelSmall,
                          weight: 700, color: AppColors.gold)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Empty placeholders are dropped automatically',
              style: wt(Theme.of(context).textTheme.labelSmall,
                  weight: 500, color: AppColors.greyIcon)),
          const SizedBox(height: 18),
          for (final entry in TemplateKeys.defaults.entries) ...[
            _templateCard(names[entry.key] ?? entry.key, entry.key, controllers[entry.key]!),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _templateCard(String name, String key, TextEditingController controller) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name.toUpperCase(),
                  style: wt(Theme.of(context).textTheme.labelSmall,
                      weight: 800, color: AppColors.gold)),
              const Spacer(),
              ScaleTap(
                onTap: () => _selfTest(key),
                child: Row(
                  children: [
                    const Icon(Icons.near_me_outlined, size: 14, color: AppColors.greyIcon),
                    const SizedBox(width: 4),
                    Text('Test',
                        style: wt(Theme.of(context).textTheme.labelSmall,
                            weight: 600, color: AppColors.greyIcon)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 2,
            onChanged: (_) => setState(() => _dirty = true),
            decoration: const InputDecoration(isDense: true, hintText: 'Type the message...'),
          ),
          const SizedBox(height: 10),
          // Live preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LIVE PREVIEW',
                    style: wt(Theme.of(context).textTheme.labelSmall,
                        weight: 700, color: AppColors.greyIcon)),
                const SizedBox(height: 4),
                Text(
                  TemplateService.preview(controller.text,
                      studio: _studioName, address: _address),
                  style: wt(Theme.of(context).textTheme.bodySmall, weight: 500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
