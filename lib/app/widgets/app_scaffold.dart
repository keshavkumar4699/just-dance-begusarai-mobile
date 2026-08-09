import 'package:flutter/material.dart';
import 'bottom_nav.dart';
import '../../features/home/home_screen.dart';
import '../../features/personal_training/pt_screen.dart';
import '../../features/collections/collections_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/add_member/add_member_sheet.dart';

class AppScaffold extends StatefulWidget {
  final int initialIndex;

  const AppScaffold({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      _showAddMemberSheet();
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _showAddMemberSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddMemberSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: const [
          HomeScreen(),
          PTScreen(),
          SizedBox.shrink(), // Index 2 placeholder (Add Member triggered via modal sheet)
          CollectionsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onAddTap: _showAddMemberSheet,
      ),
    );
  }
}
