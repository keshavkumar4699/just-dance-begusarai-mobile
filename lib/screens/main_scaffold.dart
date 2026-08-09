import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../tabs/home_tab.dart';
import '../tabs/personal_training_tab.dart';
import '../tabs/add_member_tab.dart';
import '../tabs/collections_tab.dart';
import '../tabs/profile_tab.dart';
import '../widgets/bottom_nav_icon.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    PersonalTrainingTab(),
    AddMemberTab(),
    CollectionsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hairline = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: hairline, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                  index: 0,
                  inactiveIcon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home'),
              _navItem(
                  index: 1,
                  inactiveIcon: Icons.fitness_center_outlined,
                  activeIcon: Icons.fitness_center,
                  label: 'PT'),
              _centerAddButton(),
              _navItem(
                  index: 3,
                  inactiveIcon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  label: 'Collections'),
              _navItem(
                  index: 4,
                  inactiveIcon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData inactiveIcon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: BottomNavIcon(
        icon: isActive ? activeIcon : inactiveIcon,
        label: label,
        isActive: isActive,
        onTap: () => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _centerAddButton() {
    final isActive = _currentIndex == 2;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: isActive ? 1.15 : 1.0,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.black, size: 30),
                ),
              ),
              const SizedBox(height: 2),
              Text('Add',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isActive
                          ? AppColors.gold
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }
}