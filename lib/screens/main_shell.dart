import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';

import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget? child;
  const MainShell({super.key, this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/tasks')) return 1;
    if (location.startsWith('/focus')) return 2;
    if (location.startsWith('/habits')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/tasks');
        break;
      case 2:
        context.go('/focus');
        break;
      case 3:
        context.go('/habits');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    return Scaffold(
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
