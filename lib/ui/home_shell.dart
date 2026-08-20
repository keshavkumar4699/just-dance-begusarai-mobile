/// Just Dance — 5-tab Instagram-style shell:
/// Home • Attendance • ＋ (center, gold ring) • Collections • Profile.
library;

import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../data/store.dart';
import 'add/add_member_flow.dart';
import 'attendance/attendance_tab.dart';
import 'collections/collections_tab.dart';
import 'home/home_tab.dart';
import 'profile/profile_tab.dart';

class HomeShell extends StatefulWidget {
  final AppStore store;
  const HomeShell({super.key, required this.store});

  static HomeShellState? of(BuildContext context) {
    if (context is StatefulElement && context.state is HomeShellState) {
      return context.state as HomeShellState;
    }
    return context.findAncestorStateOfType<HomeShellState>();
  }

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _homeKey = GlobalKey<HomeTabState>();

  void goTo(int index) => setState(() => _index = index);

  /// Scrolls the Home list so the given student's card is visible.
  Future<void> scrollToStudent(int studentId) =>
      _homeKey.currentState?.scrollToStudent(studentId) ?? Future.value();

  void _openAdd() => showAddMemberFlow(context, widget.store, shell: this);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(key: _homeKey, store: widget.store),
      AttendanceTab(store: widget.store),
      const SizedBox.shrink(), // center action placeholder
      CollectionsTab(store: widget.store),
      ProfileTab(store: widget.store),
    ];
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Motion.curve,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 1.02, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: tabs[_index],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: (i) => i == 2 ? _openAdd() : goTo(i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom, top: 6),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              active: index == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month,
              active: index == 1,
              onTap: () => onTap(1),
            ),
            _AddButton(onTap: () => onTap(2)),
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet,
              active: index == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              active: index == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = active ? c.gold : c.textMuted;
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Center(
          child: AnimatedSwitcher(
            duration: Motion.fast,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(active ? activeIcon : icon,
                key: ValueKey(active), color: color, size: 24),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      haptic: true,
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.surface2,
          border: Border.all(color: c.gold, width: 1.6),
        ),
        child: Icon(Icons.add, color: c.gold, size: 26),
      ),
    );
  }
}
