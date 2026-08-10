import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../services/backup_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common.dart';
import 'crop_flow.dart';
import 'settings_editors.dart';
import 'templates_editor.dart';
import '../dialogs/confirm_dialogs.dart';

/// TAB 5 - PROFILE: studio header (editable), theme, catalog CRUD,
/// WhatsApp templates, app lock, backup, about.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _lock = LocalAuthentication();
  bool _lockBusy = false;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return SafeArea(
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
              Text('Profile', style: wt(Theme.of(context).textTheme.titleLarge, weight: 800)),
              const SizedBox(height: 14),
              _studioHeader(state),
              const SizedBox(height: 16),
              // ---- Theme ----
              _sectionCard('APPEARANCE', [
                Row(
                  children: [
                    Text('Theme',
                        style: wt(Theme.of(context).textTheme.bodyMedium, weight: 600)),
                    const Spacer(),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('🌙 Dark')),
                        ButtonSegment(value: false, label: Text('☀ Light')),
                      ],
                      selected: {state.dark},
                      onSelectionChanged: (s) => state.setTheme(s.first),
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        selectedForegroundColor: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 12),
              // ---- Catalog accordion ----
              _catalogCard(state),
              const SizedBox(height: 12),
              // ---- Templates ----
              _sectionCard('WHATSAPP TEMPLATES', [
                Text('4 editable templates for one-tap messages',
                    style: wt(Theme.of(context).textTheme.bodySmall,
                        weight: 500, color: AppColors.greyIcon)),
                const SizedBox(height: 8),
                ScaleTap(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TemplatesEditor())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.gold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Edit templates',
                              style: wt(Theme.of(context).textTheme.labelMedium,
                                  weight: 700, color: AppColors.gold)),
                        ),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.gold),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              // ---- App lock ----
              _sectionCard('SECURITY', [
                SwitchListTile(
                  value: state.deviceLockOn,
                  activeTrackColor: AppColors.gold.withValues(alpha: 0.4),
                  activeThumbColor: AppColors.gold,
                  onChanged: _lockBusy ? null : _toggleLock,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Lock with device screen lock',
                      style: wt(Theme.of(context).textTheme.bodyMedium, weight: 600)),
                  subtitle: Text(
                    'Face / fingerprint / device PIN',
                    style: wt(Theme.of(context).textTheme.bodySmall,
                        weight: 500, color: AppColors.greyIcon),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              // ---- Backup ----
              _backupCard(state),
              const SizedBox(height: 12),
              // ---- About ----
              _sectionCard('ABOUT', [
                _kv('App', '${AppInfo.name} v${AppInfo.version}'),
                _kv('Data', 'Stored only on this phone'),
                _kv('Backups', 'Google Drive (private app folder)'),
                const SizedBox(height: 4),
                Text('Made for a single studio owner',
                    style: wt(Theme.of(context).textTheme.bodySmall,
                        weight: 500, color: AppColors.greyIcon)),
              ]),
            ],
          );
        },
      ),
    );
  }

  // =============================================================================
  // Studio header (WhatsApp style)
  // =============================================================================
  Widget _studioHeader(AppState state) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          // Editable avatar.
          ScaleTap(
            onTap: _editAvatar,
            child: Stack(
              children: [
                Avatar(
                  photoPath: state.studio.logoPath.isEmpty ? null : state.studio.logoPath,
                  size: 64,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                    child: const Icon(Icons.photo_camera, size: 11, color: AppColors.darkBg),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.studio.name.isEmpty ? 'Studio Crow' : state.studio.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: wt(Theme.of(context).textTheme.titleLarge, weight: 800)),
                const SizedBox(height: 2),
                Text('Director: ${state.studio.director.isEmpty ? '--' : state.studio.director}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: wt(Theme.of(context).textTheme.bodySmall,
                        weight: 500, color: AppColors.greyIcon)),
                if (state.studio.contact.isNotEmpty)
                  Text(state.studio.contact,
                      style: wt(Theme.of(context).textTheme.bodySmall,
                          weight: 600, color: AppColors.gold)),
              ],
            ),
          ),
          ScaleTap(
            onTap: _editStudioInfo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('Edit',
                  style: wt(Theme.of(context).textTheme.labelMedium,
                      weight: 700, color: AppColors.gold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editAvatar() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Camera', style: wt(Theme.of(ctx).textTheme.bodyMedium, weight: 600)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Gallery', style: wt(Theme.of(ctx).textTheme.bodyMedium, weight: 600)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (src == null || !mounted) return;
    final path = await pickAndCrop(context, src);
    if (path == null || !mounted) return;
    final info = AppState.instance.studio.copyWith(logoPath: path);
    await AppState.instance.saveStudioInfo(info);
  }

  Future<void> _editStudioInfo() async {
    final info = await showDialog<StudioInfo>(
      context: context,
      builder: (_) => const StudioInfoEditor(),
    );
    if (info != null) {
      await AppState.instance.saveStudioInfo(info);
    }
  }

  // =============================================================================
  // Lock
  // =============================================================================
  Future<void> _toggleLock(bool enable) async {
    setState(() => _lockBusy = true);
    if (enable) {
      // Verify device auth works before enabling.
      final supported = await _lock.isDeviceSupported();
      if (!supported) {
        _snack('Device security is not set up on this phone');
        setState(() => _lockBusy = false);
        return;
      }
      try {
        final ok = await _lock.authenticate(
          localizedReason: 'Set up Studio Crow lock',
          options: const AuthenticationOptions(biometricOnly: false),
        );
        if (!ok) {
          _snack('Not unlocked - lock stays off');
          setState(() => _lockBusy = false);
          return;
        }
      } catch (_) {
        _snack('Device security not available');
        setState(() => _lockBusy = false);
        return;
      }
    }
    await AppState.instance.setDeviceLock(enable);
    _snack(enable ? 'App locked with device security' : 'App lock off');
    setState(() => _lockBusy = false);
  }

  // =============================================================================
  // Catalog accordion
  // =============================================================================
  Widget _catalogCard(AppState state) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: ExpansionTile(
        shape: const Border(),
        leading: const Icon(Icons.category_outlined, size: 20, color: AppColors.gold),
        title: Text('Courses, Batches, Timings & Plans',
            style: wt(Theme.of(context).textTheme.titleSmall, weight: 700)),
        subtitle: Text('Fees, batches, timings and plan offers',
            style: wt(Theme.of(context).textTheme.labelSmall,
                weight: 500, color: AppColors.greyIcon)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          // Admission fee setting
          Row(
            children: [
              Text('Admission Fee',
                  style: wt(Theme.of(context).textTheme.bodyMedium, weight: 600)),
              const Spacer(),
              SizedBox(
                width: 110,
                child: TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: Money.fmt(state.admissionFeeAmount),
                    prefixText: '₹ ',
                  ),
                  onSubmitted: (v) {
                    final n = int.tryParse(v);
                    if (n != null) state.setAdmissionFeeAmount(n);
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _catalogSection(
            title: 'Courses (${state.courses.length})',
            icon: Icons.school_outlined,
            items: [
              for (final c in state.courses)
                _itemRow(
                  c.name,
                  '${Money.fmt(c.fee)}/mo',
                  onEdit: () => _editCourse(c),
                  onDelete: () => _deleteWithGuard(() => state.deleteCourse(c), 'course'),
                ),
            ],
            onAdd: () => _editCourse(null),
          ),
          const Divider(height: 24),
          _catalogSection(
            title: 'Batches per course',
            icon: Icons.groups_outlined,
            items: [
              for (final c in state.courses)
                for (final b in state.batches.where((b) => b.courseId == c.id))
                  _itemRow(
                    '${c.name}: ${b.name}',
                    b.daysInfo,
                    onEdit: () => _editBatch(b),
                    onDelete: () => _deleteWithGuard(() => state.deleteBatch(b), 'batch'),
                  ),
            ],
            onAdd: () => _editBatch(null),
          ),
          const Divider(height: 24),
          _catalogSection(
            title: 'Timings per batch',
            icon: Icons.schedule_outlined,
            items: [
              for (final b in state.batches)
                for (final t in state.timings.where((t) => t.batchId == b.id))
                  _itemRow(
                    '${b.name}: ${t.label}',
                    t.startTime.isEmpty ? '' : '${t.startTime}-${t.endTime}',
                    onEdit: () => _editTiming(t),
                    onDelete: () => _deleteWithGuard(() => state.deleteTiming(t), 'timing'),
                  ),
            ],
            onAdd: () => _editTiming(null),
          ),
          const Divider(height: 24),
          _catalogSection(
            title: 'Plans (${state.plans.length})',
            icon: Icons.workspace_premium_outlined,
            items: [
              for (final p in state.plans)
                _itemRow(
                  p.name,
                  '${p.months} mo${p.discountValue > 0 ? ', ${p.discountValue}${p.discountType} off' : ''}',
                  onEdit: () => _editPlan(p),
                  onDelete: () => _deleteWithGuard(() => state.deletePlan(p), 'plan'),
                ),
            ],
            onAdd: () => _editPlan(null),
          ),
        ],
      ),
    );
  }

  Widget _catalogSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Text('Nothing yet',
              style: wt(Theme.of(context).textTheme.bodySmall,
                  weight: 500, color: AppColors.greyIcon)),
        ...items,
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16, color: AppColors.gold),
          label: Text('Add',
              style: wt(Theme.of(context).textTheme.labelMedium,
                  weight: 700, color: AppColors.gold)),
        ),
      ],
    );
  }

  Widget _itemRow(String title, String sub, {VoidCallback? onEdit, VoidCallback? onDelete}) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: wt(Theme.of(context).textTheme.bodyMedium, weight: 600)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        style: wt(Theme.of(context).textTheme.labelSmall,
                            weight: 500, color: AppColors.greyIcon)),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.greyIcon),
          onPressed: onEdit,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.expired),
          onPressed: onDelete,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Future<void> _deleteWithGuard(Future<String?> Function() del, String what) async {
    final err = await del();
    if (!mounted) return;
    if (err != null) {
      await confirmDialog(
        context,
        title: 'Cannot delete $what',
        message: '$err.\nRemove it from all students first.',
        confirmLabel: 'OK',
      );
    } else {
      _snack('$what deleted');
    }
  }

  Future<void> _editCourse(Course? c) async {
    final result = await showDialog<Course>(
      context: context,
      builder: (_) => CourseEditor(course: c),
    );
    if (result != null) {
      if (c == null) {
        await AppState.instance.addCourse(result.name, result.fee, result.description);
      } else {
        await AppState.instance.updateCourse(result);
      }
    }
  }

  Future<void> _editBatch(Batch? b) async {
    final result = await showDialog<Batch>(
      context: context,
      builder: (_) => BatchEditor(batch: b),
    );
    if (result != null) {
      if (b == null) {
        await AppState.instance.addBatch(result.courseId, result.name, result.daysInfo);
      } else {
        await AppState.instance.updateBatch(result);
      }
    }
  }

  Future<void> _editTiming(Timing? t) async {
    final result = await showDialog<Timing>(
      context: context,
      builder: (_) => TimingEditor(timing: t),
    );
    if (result != null) {
      if (t == null) {
        await AppState.instance.addTiming(result.batchId, result.label, result.startTime, result.endTime);
      } else {
        await AppState.instance.updateTiming(result);
      }
    }
  }

  Future<void> _editPlan(Plan? p) async {
    final result = await showDialog<Plan>(
      context: context,
      builder: (_) => PlanEditor(plan: p),
    );
    if (result != null) {
      if (p == null) {
        await AppState.instance.addPlan(result.name, result.months, result.discountType, result.discountValue);
      } else {
        await AppState.instance.updatePlan(result);
      }
    }
  }

  // =============================================================================
  // Backup card
  // =============================================================================
  Widget _backupCard(AppState state) {
    final meta = state.backupMeta;
    final signedIn = meta.accountEmail != null;
    return _sectionCard('GOOGLE DRIVE BACKUP', [
      Row(
        children: [
          const Icon(Icons.cloud_done_outlined, size: 18, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              signedIn ? meta.accountEmail! : 'Not signed in',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: wt(Theme.of(context).textTheme.bodyMedium, weight: 600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        meta.lastBackupAt != null
            ? 'Last backup: ${_fmtBackupTime(meta.lastBackupAt!)}${meta.lastBackupSize != null ? '  •  ${meta.lastBackupSize}' : ''}'
            : 'No backup yet',
        style: wt(Theme.of(context).textTheme.bodySmall,
            weight: 500, color: AppColors.greyIcon),
      ),
      if (meta.pending)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('A backup is pending - auto retry on',
              style: wt(Theme.of(context).textTheme.bodySmall,
                  weight: 600, color: AppColors.nearExpiry)),
        ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _miniBtn('Backup Now', Icons.cloud_upload_outlined, _backupNow),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _miniBtn('Restore', Icons.settings_backup_restore, _restore),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _miniBtn(
              signedIn ? 'Change Account' : 'Sign in',
              Icons.account_circle_outlined,
              _changeAccount,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      SwitchListTile(
        value: state.dailyBackupOn,
        activeTrackColor: AppColors.gold.withValues(alpha: 0.4),
        activeThumbColor: AppColors.gold,
        onChanged: (v) => AppState.instance.setDailyBackup(v),
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text('Daily backup at 4 AM',
            style: wt(Theme.of(context).textTheme.bodySmall, weight: 600)),
      ),
      SwitchListTile(
        value: state.wifiOnlyBackup,
        activeTrackColor: AppColors.gold.withValues(alpha: 0.4),
        activeThumbColor: AppColors.gold,
        onChanged: (v) => AppState.instance.setWifiOnly(v),
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text('Backup on Wi-Fi only',
            style: wt(Theme.of(context).textTheme.bodySmall, weight: 600)),
      ),
    ]);
  }

  String _fmtBackupTime(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return iso;
    return '${Dates.display(Dates.fmt(t))} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _backupNow() async {
    final state = AppState.instance;
    if (state.backupMeta.accountEmail == null) {
      _snack('Sign in with Google first');
      return;
    }
    final res = await state.backupNow();
    _snack(res.message);
  }

  Future<void> _restore() async {
    final state = AppState.instance;
    final fetch = await BackupService.instance.fetchBackupForRestore();
    if (!fetch.ok || !mounted) {
      _snack(fetch.message);
      return;
    }
    final meta = (fetch.meta?['data'] as Map?)?['exportedAt'];
    final ok = await confirmDialog(
      context,
      title: 'Restore from backup?',
      message: 'Backup found${meta != null ? ' (exported ${(meta as String).substring(0, 10)})' : ''}.\n'
          'Current data stays safe - you can Undo after restoring.',
      confirmLabel: 'Restore',
    );
    if (!ok || !mounted) return;
    final res = await state.restoreFromBackup(fetch.meta!);
    if (!mounted) return;
    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Restored from backup'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => AppState.instance.undoRestore(),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } else {
      _snack(res.message);
    }
  }

  Future<void> _changeAccount() async {
    try {
      await BackupService.instance.signOut();
      await BackupService.instance.signIn();
      _snack('Signed in');
    } catch (_) {
      _snack('Sign in cancelled');
    }
    await AppState.instance.reloadBackupMeta();
  }

  Widget _miniBtn(String label, IconData icon, VoidCallback onTap) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: AppColors.gold),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: wt(Theme.of(context).textTheme.labelSmall,
                    weight: 700, color: AppColors.gold)),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // Helpers
  // =============================================================================
  Widget _sectionCard(String title, List<Widget> children) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(k,
                style: wt(Theme.of(context).textTheme.bodySmall,
                    weight: 500, color: AppColors.greyIcon)),
          ),
          Text(v, style: wt(Theme.of(context).textTheme.bodySmall, weight: 600)),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
