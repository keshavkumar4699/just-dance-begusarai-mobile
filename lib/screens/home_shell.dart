import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/collections/collections_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/common.dart';
import 'add/add_member_sheet.dart';

/// 5-tab Instagram-style shell. Active = gold filled, inactive = grey outline.
/// Center + has a thin gold ring and opens the Add Member flow.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [HomeScreen(), AttendanceScreen(), CollectionsScreen(), ProfileScreen()];

  Future<void> _openAddMember() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMemberSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onSelect: (i) {
          setState(() => _index = i);
        },
        onAdd: _openAddMember,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  const _BottomBar({required this.index, required this.onSelect, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = AppColors.gold;
    final inactive = AppColors.greyIcon;

    Widget icon(IconData outline, IconData filled, int i, {String? label}) {
      final selected = index == i;
      return ScaleTap(
        onTap: () => onSelect(i),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Icon(
            selected ? filled : outline,
            key: ValueKey(selected),
            size: 24,
            color: selected ? active : inactive,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              icon(Icons.home_outlined, Icons.home, 0),
              icon(Icons.calendar_month_outlined, Icons.calendar_month, 1),
              // Center add button with thin gold ring, slightly larger.
              ScaleTap(
                onTap: onAdd,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 1.4),
                  ),
                  child: const Icon(Icons.add, size: 26, color: AppColors.gold),
                ),
              ),
              icon(Icons.wallet_outlined, Icons.wallet, 2),
              icon(Icons.person_outline, Icons.person, 3),
            ],
          ),
        ),
      ),
    );
  }
}

