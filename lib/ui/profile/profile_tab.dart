/// Just Dance — TAB 5: PROFILE.
/// WhatsApp-style editable header, theme toggle, catalog section, templates,
/// App Lock, backup card, About.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/store.dart';
import '../../services/backup_service.dart';
import '../../services/lock_service.dart';
import '../../services/photo_service.dart';
import '../add/crop_screen.dart';
import '../widgets/common.dart';
import 'catalog_screen.dart';
import 'templates_screen.dart';

class ProfileTab extends StatelessWidget {
  final AppStore store;
  const ProfileTab({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          _Header(store: store),
          const SizedBox(height: 16),
          _themeToggle(context, c),
          const SizedBox(height: 12),
          _navTile(context, c, Icons.category_outlined,
              'Schedule',
              subtitle:
                  'Courses, batches, timings, plans, admission fee, GST & personal training',
              onTap: () => Navigator.push(context,
                  fadeSlideRoute(CatalogScreen(store: store)))),
          _navTile(context, c, Icons.chat_bubble_outline, 'WhatsApp Templates',
              subtitle: 'Welcome, fee collected, fees due, ID card',
              onTap: () => Navigator.push(context,
                  fadeSlideRoute(TemplatesScreen(store: store)))),
          const SizedBox(height: 12),
          _lockTile(context, c),
          const SizedBox(height: 12),
          BackupCard(store: store),
          const SizedBox(height: 12),
          _about(context, c),
        ],
      ),
    );
  }

  Widget _themeToggle(BuildContext context, AppColors c) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final (label, icon, dark) in const [
            ('Dark', Icons.dark_mode_outlined, true),
            ('Light', Icons.light_mode_outlined, false),
          ])
            Expanded(
              child: Pressable(
                onTap: () => store.setTheme(dark),
                child: AnimatedContainer(
                  duration: Motion.fast,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: store.isDark == dark ? c.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon,
                          size: 16,
                          color: store.isDark == dark
                              ? Colors.black
                              : c.textMuted),
                      const SizedBox(width: 6),
                      Text(label,
                          style: TextStyle(
                              color: store.isDark == dark
                                  ? Colors.black
                                  : c.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _navTile(BuildContext context, AppColors c, IconData icon,
      String title,
      {String? subtitle, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.hairline),
          ),
          child: Row(
            children: [
              Icon(icon, color: c.gold, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: TextStyle(
                              color: c.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lockTile(BuildContext context, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: c.gold,
        secondary: Icon(Icons.lock_outline, color: c.gold, size: 21),
        title: const Text('Lock with device screen lock',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('Face, fingerprint or phone PIN',
            style: TextStyle(color: c.textMuted, fontSize: 11.5)),
        value: store.deviceLockOn,
        onChanged: (v) async {
          if (v) {
            final available = await LockService.instance.available();
            if (!available) {
              if (context.mounted) {
                showSnack(context,
                    'No device lock found — set a screen lock in phone settings first',
                    duration: kSnackError);
              }
              return;
            }
            final ok = await LockService.instance.unlock();
            if (!ok) return;
          }
          await store.setDeviceLock(v);
        },
      ),
    );
  }

  Widget _about(BuildContext context, AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        children: [
          const AppLogo(size: 44),
          const SizedBox(height: 8),
          const Text('Just Dance',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          Text('v1.0.0 · offline-first studio manager',
              style: TextStyle(color: c.textMuted, fontSize: 11.5)),
          const SizedBox(height: 4),
          Text('Your data stays on your phone and your Google Drive backup.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ---------------- header (avatar + studio info) ----------------

class _Header extends StatelessWidget {
  final AppStore store;
  const _Header({required this.store});

  Future<void> _changeAvatar(BuildContext context, ImageSource source) async {
    store.suppressLock = true;
    XFile? picked;
    try {
      picked = await PhotoService.instance.pick(source);
    } finally {
      store.suppressLock = false;
    }
    if (picked == null || !context.mounted) return;
    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;
    final crop = await CropScreen.push(context, bytes);
    final saved = await PhotoService.instance.saveCompressed(bytes,
        crop: crop, prefix: 'studio', fallbackPath: picked.path);
    final info = store.studio..photoPath = saved;
    await store.saveStudio(info);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final info = store.studio;
    final hasPhoto =
        info.photoPath.isNotEmpty && File(info.photoPath).existsSync();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        children: [
          Pressable(
            onTap: () async {
              final choice = await showAppSheet<ImageSource>(
                context,
                SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.photo_camera_outlined,
                            color: c.gold),
                        title: const Text('Camera'),
                        onTap: () =>
                            Navigator.pop(context, ImageSource.camera),
                      ),
                      ListTile(
                        leading: Icon(Icons.photo_library_outlined,
                            color: c.gold),
                        title: const Text('Gallery'),
                        onTap: () =>
                            Navigator.pop(context, ImageSource.gallery),
                      ),
                    ],
                  ),
                ),
                isScrollControlled: false,
              );
              if (choice != null && context.mounted) {
                await _changeAvatar(context, choice);
              }
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: hasPhoto
                        ? Image.file(File(info.photoPath), fit: BoxFit.cover)
                        : Image.asset('assets/logo.png'),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: c.gold, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 11, color: Colors.black),
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
                Text(info.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17)),
                if (info.director.isNotEmpty)
                  Text(info.director,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: c.textMuted, fontSize: 12.5)),
                if (info.phone.isNotEmpty)
                  Text(info.phone,
                      style:
                          TextStyle(color: c.textMuted, fontSize: 12)),
                TextButton.icon(
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28)),
                  onPressed: () => showAppSheet(
                      context, StudioEditSheet(store: store)),
                  icon: Icon(Icons.edit_outlined, color: c.gold, size: 14),
                  label: Text('Edit Studio Info',
                      style: TextStyle(
                          color: c.gold,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudioEditSheet extends StatefulWidget {
  final AppStore store;
  const StudioEditSheet({super.key, required this.store});

  @override
  State<StudioEditSheet> createState() => _StudioEditSheetState();
}

class _StudioEditSheetState extends State<StudioEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _director;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _instagram;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final s = widget.store.studio;
    _name = TextEditingController(text: s.name);
    _director = TextEditingController(text: s.director);
    _phone = TextEditingController(text: s.phone);
    _whatsapp = TextEditingController(text: s.whatsapp);
    _instagram = TextEditingController(text: s.instagram);
    _address = TextEditingController(text: s.address);
  }

  @override
  void dispose() {
    for (final c in [_name, _director, _phone, _whatsapp, _instagram, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Studio Info',
                style: Theme.of(context).textTheme.titleMedium),
            const FieldLabel('Studio name'),
            TextField(controller: _name),
            const FieldLabel('Director'),
            TextField(controller: _director),
            const FieldLabel('Contact number'),
            TextField(
                controller: _phone, keyboardType: TextInputType.phone),
            const FieldLabel('WhatsApp number'),
            TextField(
                controller: _whatsapp, keyboardType: TextInputType.phone),
            const FieldLabel('Instagram'),
            TextField(
                controller: _instagram,
                decoration: const InputDecoration(hintText: '@yourstudio')),
            const FieldLabel('Address'),
            TextField(controller: _address, maxLines: 2),
            const SizedBox(height: 18),
            GoldButton('Save', icon: Icons.check, onTap: () async {
              final info = widget.store.studio
                ..name = _name.text.trim().isEmpty
                    ? 'My Studio'
                    : _name.text.trim()
                ..director = _director.text.trim()
                ..phone = _phone.text.trim()
                ..whatsapp = _whatsapp.text.trim()
                ..instagram = _instagram.text.trim()
                ..address = _address.text.trim();
              await widget.store.saveStudio(info);
              if (context.mounted) Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------- backup card ----------------

class BackupCard extends StatefulWidget {
  final AppStore store;
  const BackupCard({super.key, required this.store});

  @override
  State<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<BackupCard> {
  bool _busy = false;

  AppStore get store => widget.store;

  Future<void> _connect() async {
    setState(() => _busy = true);
    final acc = await BackupService.instance.signInInteractive();
    if (mounted) setState(() => _busy = false);
    if (acc != null && mounted) {
      showSnack(context, 'Connected as ${acc.email}', duration: kSnackSuccess);
      _showBackupResult(await BackupService.instance.backupNow());
      return;
    }
    if (mounted) {
      final err = store.backupMeta['error'] as String?;
      if (err != null && err.isNotEmpty) {
        showSnack(context, 'Google sign-in failed — $err',
            duration: kSnackBackup);
      }
    }
  }

  void _showBackupResult(BackupResult r) {
    if (!mounted) return;
    switch (r.error) {
      case null:
        showSnack(context, 'Backup complete ✔', duration: kSnackBackup);
      case 'reconnect':
        showSnack(context, 'Google session expired — tap Connect again',
            duration: kSnackBackup);
      case 'nointernet':
        showSnack(context, 'No internet — backup will retry automatically',
            duration: kSnackBackup);
      case 'quota':
        showSnack(context, 'Google Drive storage is full',
            duration: kSnackBackup);
      case 'wifi':
        showSnack(context, 'Waiting for Wi-Fi (Wi-Fi-only is on)',
            duration: kSnackBackup);
      default:
        showSnack(context, 'Backup failed — will retry',
            duration: kSnackBackup);
    }
  }

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    final r = await BackupService.instance.backupNow();
    if (!mounted) return;
    setState(() => _busy = false);
    _showBackupResult(r);
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final payload = await BackupService.instance.fetchBackup();
    if (!mounted) return;
    setState(() => _busy = false);
    if (payload == null) {
      showSnack(context, 'No backup found on this Google account',
          duration: kSnackBackup);
      return;
    }
    final created =
        DateTime.tryParse('${payload['createdAt'] ?? ''}') ?? DateTime.now();
    final counts = (payload['counts'] as Map?) ?? {};
    final ok = await showConfirmDialog(
      context,
      title: 'Restore backup?',
      message: 'From ${fmtDate(created, forceYear: true)}\n'
          '• ${counts['students'] ?? 0} members\n'
          '• ${counts['courses'] ?? 0} courses, ${counts['batches'] ?? 0} batches, ${counts['timings'] ?? 0} timings\n'
          '• ${counts['plans'] ?? 0} plans\n'
          '• ${counts['ledger'] ?? 0} ledger entries, ${counts['attendance'] ?? 0} attendance rows\n'
          '• ${counts['photos'] ?? 0} photos\n'
          '• Settings (admission fee, GST, templates, studio info)\n\n'
          'Your current data is kept as a snapshot with Undo.',
      confirmLabel: 'Restore',
    );
    if (!ok || !mounted) return;
    var mergeMissing = false;
    final missing = BackupService.instance.missingTables(payload);
    if (missing.isNotEmpty) {
      final labels = [
        if (missing.contains('courses')) 'Courses',
        if (missing.contains('batches')) 'Batches',
        if (missing.contains('timings')) 'Timings',
        if (missing.contains('plans')) 'Plans',
        if (missing.contains('settings')) 'Settings',
        if (missing.contains('studentCourses')) 'Course assignments',
        if (missing.contains('students')) 'Members',
        if (missing.contains('ledger')) 'Ledger',
        if (missing.contains('attendance')) 'Attendance',
      ];
      final proceed = await showConfirmDialog(
        context,
        title: 'Old backup detected',
        message:
            'This backup was created by an older version of the app and is missing: ${labels.join(', ')}.\n\n'
            'Your current data for these will be kept.',
        confirmLabel: 'Restore anyway',
        cancelLabel: 'Cancel',
      );
      if (!proceed || !mounted) return;
      mergeMissing = true;
    }
    await BackupService.instance.applyRestore(store, payload,
        mergeMissing: mergeMissing);
    if (!mounted) return;
    showSnack(
      context,
      'Backup restored ✔',
      duration: kSnackBackup,
      action: SnackBarAction(
        label: 'Undo',
        textColor: AppColors.of(context).gold,
        onPressed: () => BackupService.instance.undoRestore(store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final meta = store.backupMeta;
    final email = meta['email'] as String?;
    final lastRaw = meta['lastBackup'] as String?;
    final last = lastRaw == null ? null : DateTime.tryParse(lastRaw);
    final error = meta['error'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: error == 'quota' ? c.expired : c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined, color: c.gold, size: 21),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Backup',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              ),
              if (store.backupPending)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.nearExpiry.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Pending',
                      style: TextStyle(
                          color: c.nearExpiry,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            email == null
                ? 'Not connected — sign in once to back up to your Google Drive (hidden app folder).'
                : 'Connected: $email',
            style: TextStyle(color: c.textMuted, fontSize: 12),
          ),
          if (last != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Last backup: ${fmtDate(last, forceYear: true)} ${TimeOfDay.fromDateTime(last).format(context)}',
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),
            ),
          if (error == 'quota') ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.expired.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Google Drive storage is full. Free up space, then tap Retry.',
                style: TextStyle(color: c.expired, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (email == null) ...[
                Expanded(
                  child: GoldButton('Connect Google',
                      icon: Icons.login,
                      onTap: _busy ? null : _connect),
                ),
              ] else ...[
                Expanded(
                  child: GoldButton(
                      error == 'quota' ? 'Retry' : 'Backup Now',
                      icon: Icons.cloud_upload_outlined,
                      onTap: _busy ? null : _backupNow),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GhostButton('Restore',
                      icon: Icons.cloud_download_outlined,
                      onTap: _busy ? null : _restore),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GhostButton('Change',
                      icon: Icons.switch_account_outlined,
                      onTap: _busy
                          ? null
                          : () async {
                              await BackupService.instance.signOut();
                              await _connect();
                            }),
                ),
              ],
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeThumbColor: c.gold,
            title: const Text('Daily backup at 4 AM',
                style: TextStyle(fontSize: 13)),
            value: store.dailyBackupOn,
            onChanged: (v) async {
              await store.setDailyBackup(v);
              await BackupService.instance.scheduleDaily(
                  enabled: v, wifiOnly: store.wifiOnlyBackup);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeThumbColor: c.gold,
            title:
                const Text('Wi-Fi only', style: TextStyle(fontSize: 13)),
            value: store.wifiOnlyBackup,
            onChanged: (v) async {
              await store.setWifiOnly(v);
              await BackupService.instance.scheduleDaily(
                  enabled: store.dailyBackupOn, wifiOnly: v);
            },
          ),
        ],
      ),
    );
  }
}
