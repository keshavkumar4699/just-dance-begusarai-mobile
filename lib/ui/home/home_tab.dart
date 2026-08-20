/// Just Dance — TAB 1: HOME.
/// Search, live count chips, Personal Training section, IG-post member list
/// sorted by expiry approach (EXPIRED top -> ending soon -> active).
library;

import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../widgets/common.dart';
import '../widgets/member_card.dart';
import 'pt_screen.dart';

class HomeTab extends StatefulWidget {
  final AppStore store;
  const HomeTab({super.key, required this.store});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  String _query = '';
  HomeFilter _filter = HomeFilter.all;
  final _cardKeys = <int, GlobalKey>{};
  final _scroll = ScrollController();

  AppStore get store => widget.store;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The display order of students in the list (sections flattened).
  List<Student> _orderedList() {
    final list = _filtered(_filter);
    if (list.isEmpty) return list;
    final now = DateTime.now();
    int daysLeftOf(Student s) => store.statusOf(s, today: now).daysLeft;
    list.sort((a, b) => daysLeftOf(a).compareTo(daysLeftOf(b)));
    final showSections = _filter.key == 'all' || _filter.key == 'due';
    if (!showSections) return list;
    final expired =
        list.where((s) => store.statusOf(s, today: now).expired).toList();
    final endingSoon = list.where((s) {
      final st = store.statusOf(s, today: now);
      return !st.expired &&
          st.daysLeft <= 7 &&
          store.memberStatus(s, today: now) != MemberStatus.blocked;
    }).toList();
    final rest = list
        .where((s) => !expired.contains(s) && !endingSoon.contains(s))
        .toList();
    return [...expired, ...endingSoon, ...rest];
  }

  /// Smoothly scrolls the member list so [studentId]'s card is in view.
  Future<void> scrollToStudent(int studentId) async {
    if (_cardKeys[studentId]?.currentContext == null) {
      // Slivers build lazily — estimate the offset for off-screen cards.
      final order = _orderedList();
      final idx = order.indexWhere((s) => s.id == studentId);
      if (idx >= 0 && _scroll.hasClients) {
        final est = (idx * 250.0).clamp(0.0, _scroll.position.maxScrollExtent);
        await _scroll.animateTo(est,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic);
      }
    }
    final ctx = _cardKeys[studentId]?.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.3,
      );
    }
  }

  bool _matches(Student s) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return s.name.toLowerCase().contains(q) ||
        s.mobile.contains(q) ||
        s.altMobile.contains(q) ||
        s.jdNo.toLowerCase().contains(q);
  }

  int _countFor(HomeFilter f) => _filtered(f).length;

  List<Student> _filtered(HomeFilter f) {
    final now = DateTime.now();
    return store.students.where((s) {
      if (s.ptEnabled) return false; // PT members live in the PT tab only
      if (!_matches(s)) return false;
      final ms = store.memberStatus(s, today: now);
      final st = store.statusOf(s, today: now);
      switch (f.key) {
        case 'all':
          return ms != MemberStatus.blocked;
        case 'active':
          return ms == MemberStatus.active || ms == MemberStatus.nearExpiry;
        case 'inactive':
          return ms == MemberStatus.inactive;
        case 'expired':
          return ms == MemberStatus.expired;
        case 'due':
          return st.hasDue && ms != MemberStatus.blocked;
        case 'blocked':
          return ms == MemberStatus.blocked;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 26),
            const SizedBox(width: 10),
            Text(store.studio.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          color: c.gold,
          onRefresh: () => store.recomputeAll(),
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(child: _searchBar(c)),
              SliverToBoxAdapter(child: _chips(c)),
              SliverToBoxAdapter(child: _ptSection(c)),
              _memberList(c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search by name, mobile or ID…',
          prefixIcon: Icon(Icons.search, color: c.textMuted, size: 20),
          isDense: true,
        ),
      ),
    );
  }

  Widget _chips(AppColors c) {
    final defs = [
      (HomeFilter.all, 'All'),
      (HomeFilter.active, 'Active'),
      (HomeFilter.inactive, 'Inactive'),
      (HomeFilter.expired, 'Expired'),
      (HomeFilter.due, 'Due'),
      (HomeFilter.blocked, 'Blocked'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: defs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (f, label) = defs[i];
          final selected = _filter.key == f.key;
          return Pressable(
            onTap: () => setState(() => _filter = f),
            child: AnimatedScale(
              scale: selected ? 1.05 : 1.0,
              duration: Motion.fast,
              curve: Motion.curve,
              child: AnimatedContainer(
                duration: Motion.fast,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? c.gold : c.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: selected ? c.gold : c.hairline),
                ),
                child: Row(
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: selected ? Colors.black : c.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    CountUpText(
                      _countFor(f),
                      style: TextStyle(
                          color: selected
                              ? Colors.black.withValues(alpha: 0.65)
                              : c.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// WhatsApp-"Archived"-style compact PT row.
  Widget _ptSection(AppColors c) {
    final pts = store.students.where((s) => s.ptEnabled && !s.isBlocked).length;
    if (pts == 0) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Pressable(
        onTap: () => Navigator.push(
            context, fadeSlideRoute(PtScreen(store: store))),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.hairline),
          ),
          child: Row(
            children: [
              Icon(Icons.fitness_center_outlined,
                  size: 20, color: c.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Personal Training',
                    style: TextStyle(
                        color: c.textMuted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600)),
              ),
              Text('($pts)',
                  style: TextStyle(color: c.textMuted, fontSize: 12.5)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: c.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberList(AppColors c) {
    final list = _filtered(_filter);
    if (list.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.people_outline,
          title: store.students.isEmpty
              ? 'No members yet — tap + to add'
              : 'No members here',
          hint: store.students.isEmpty
              ? 'Your studio family starts with the first member.'
              : 'Try another filter or search.',
        ),
      );
    }

    // Sort by expiry approach: EXPIRED (most overdue first) -> daysLeft asc.
    final now = DateTime.now();
    int daysLeftOf(Student s) => store.statusOf(s, today: now).daysLeft;
    list.sort((a, b) => daysLeftOf(a).compareTo(daysLeftOf(b)));

    final expired =
        list.where((s) => store.statusOf(s, today: now).expired).toList();
    final endingSoon = list.where((s) {
      final st = store.statusOf(s, today: now);
      return !st.expired &&
          st.daysLeft <= 7 &&
          store.memberStatus(s, today: now) != MemberStatus.blocked;
    }).toList();
    final rest = list
        .where((s) => !expired.contains(s) && !endingSoon.contains(s))
        .toList();

    final children = <Widget>[];
    var stagger = 0;
    GlobalKey cardKeyOf(int id) =>
        _cardKeys.putIfAbsent(id, () => GlobalKey());
    void section(String label, List<Student> items) {
      if (items.isEmpty) return;
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: SectionLabel('$label (${items.length})'),
      ));
      for (final s in items) {
        children.add(KeyedSubtree(
          key: cardKeyOf(s.id),
          child: MemberCard(store: store, student: s, staggerIndex: stagger++),
        ));
      }
    }

    final showSections = _filter.key == 'all' || _filter.key == 'due';
    if (showSections) {
      section('EXPIRED', expired);
      section('ENDING WITHIN 7 DAYS', endingSoon);
      section('ACTIVE', rest);
    } else {
      for (final s in list) {
        children.add(KeyedSubtree(
          key: cardKeyOf(s.id),
          child: MemberCard(store: store, student: s, staggerIndex: stagger++),
        ));
      }
    }
    children.add(const SizedBox(height: 24));

    return SliverList(
      delegate: SliverChildListDelegate(children),
    );
  }
}
