import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/screens/dashboard_screen.dart';
import 'package:enbridge/screens/tasks_screen.dart';
import 'package:enbridge/screens/focus_screen.dart';
import 'package:enbridge/screens/habits_screen.dart';
import 'package:enbridge/screens/analytics_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _current = 0;
  late final List<AnimationController> _fadeControllers;
  late final List<Animation<double>> _fadeAnims;

  final _screens = const [
    DashboardScreen(),
    TasksScreen(),
    FocusScreen(),
    HabitsScreen(),
    AnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeControllers = List.generate(
        _screens.length,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 280)));
    _fadeAnims = _fadeControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _fadeControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _fadeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == _current) return;
    _fadeControllers[_current].reverse();
    setState(() => _current = index);
    _fadeControllers[index].forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: List.generate(_screens.length, (i) {
          return FadeTransition(
            opacity: _fadeAnims[i],
            child: Offstage(
              offstage: _current != i,
              child: _screens[i],
            ),
          );
        }),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _current,
        onTap: _switchTab,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.check_box_outlined, Icons.check_box_rounded, 'Tasks'),
    (Icons.timer_outlined, Icons.timer_rounded, 'Focus'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Habits'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: AppColors.navBg,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final isSelected = currentIndex == i;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: SizedBox(
                width: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? _items[i].$2 : _items[i].$1,
                      size: 22,
                      color: isSelected
                          ? AppColors.accentGreen
                          : AppColors.textTertiary,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 4, height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.accentGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
