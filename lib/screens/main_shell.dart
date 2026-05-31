import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget? child;
  const MainShell({super.key, this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/tasks'))     return 1;
    if (location.startsWith('/aiva'))      return 2;
    if (location.startsWith('/calendar'))  return 3;
    if (location.startsWith('/focus'))     return 4;
    if (location.startsWith('/habits'))    return 5;
    if (location.startsWith('/profile'))   return 6;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/dashboard'); break;
      case 1: context.go('/tasks');     break;
      case 2: context.go('/aiva');      break;
      case 3: context.go('/calendar'); break;
      case 4: context.go('/focus');     break;
      case 5: context.go('/habits');    break;
      case 6: context.go('/profile');   break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.bgPrimary,
      body: child,
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        onTap: (idx) => _onItemTapped(idx, context),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined,            Icons.home_rounded,               'Home'),
    (Icons.check_box_outlined,       Icons.check_box_rounded,          'Tasks'),
    (Icons.auto_awesome_outlined,    Icons.auto_awesome_rounded,       'AIVA'),
    (Icons.calendar_month_outlined,  Icons.calendar_month_rounded,     'Calendar'),
    (Icons.timer_outlined,           Icons.timer_rounded,              'Focus'),
    (Icons.bar_chart_outlined,       Icons.bar_chart_rounded,          'Habits'),
    (Icons.person_outline_rounded,   Icons.person_rounded,             'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: AppColors.navBg.withValues(alpha: 0.6),
            border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final isSelected = currentIndex == i;
                // AIVA tab uses blue accent instead of green
                final activeColor = i == 2
                    ? AppColors.aivaBlueMid
                    : AppColors.accentGreen;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: SizedBox(
                    width: 44,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? _items[i].$2 : _items[i].$1,
                          size: 20,
                          color: isSelected ? activeColor : AppColors.textTertiary,
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 4, height: 4,
                            decoration: BoxDecoration(
                              color: activeColor,
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
        ),
      ),
    );
  }
}
