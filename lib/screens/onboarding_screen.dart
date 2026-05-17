import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/widgets/shared_widgets.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;
  final Set<int> _selectedPain = {};
  int _selectedGoal = -1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < 4) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _current = i),
              children: [
                _Slide1(onStart: widget.onComplete, onExplore: _next),
                _Slide2(
                  selected: _selectedPain,
                  onToggle: (i) => setState(() {
                    if (_selectedPain.contains(i)) {
                      _selectedPain.remove(i);
                    } else {
                      _selectedPain.add(i);
                    }
                  }),
                  onNext: _next,
                ),
                _Slide3(
                  selected: _selectedGoal,
                  onSelect: (i) => setState(() => _selectedGoal = i),
                  onNext: _next,
                ),
                const _Slide4(),
                _Slide5(onStart: widget.onComplete),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: SmoothPageIndicator(
              controller: _controller,
              count: 5,
              effect: ExpandingDotsEffect(
                activeDotColor: AppColors.accentGreen,
                dotColor: AppColors.textTertiary,
                dotHeight: 6,
                dotWidth: 6,
                expansionFactor: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide 1 ──────────────────────────────────────────────────────────────────
class _Slide1 extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onExplore;
  const _Slide1({required this.onStart, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Green glow top-left
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x0F4ADE80), Colors.transparent],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bridging you to your maximum potential.',
                style: AppTextStyles.displayMedium,
              ),
              const SizedBox(height: 20),
              Text(
                'Enbridge creates a personalized roadmap that guides you every step of the way — so you can achieve what matters most.',
                style: AppTextStyles.bodyMedium,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Start the MVP',
                      onPressed: onStart,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Explore the flow',
                      onPressed: onExplore,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Slide 2 ──────────────────────────────────────────────────────────────────
class _Slide2 extends StatelessWidget {
  final Set<int> selected;
  final void Function(int) onToggle;
  final VoidCallback onNext;

  static const _pains = [
    'I procrastinate constantly',
    'I forget assignments',
    'Chores interrupt my study',
    'I lack consistency',
  ];

  const _Slide2({
    required this.selected,
    required this.onToggle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Do you relate?'),
          const SizedBox(height: 12),
          Text('The struggle is real.', style: AppTextStyles.displayMedium),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: List.generate(_pains.length, (i) {
                final isSelected = selected.contains(i);
                return GestureDetector(
                  onTap: () => onToggle(i),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accentGreen
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GreenDot(size: isSelected ? 10 : 7),
                        ),
                        Center(
                          child: Text(
                            _pains[i],
                            textAlign: TextAlign.center,
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Continue →', onPressed: onNext),
        ],
      ),
    );
  }
}

// ─── Slide 3 ──────────────────────────────────────────────────────────────────
class _Slide3 extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;
  final VoidCallback onNext;

  static const _goals = [
    ('Students', 'Ace your studies, build skills, shape your future.'),
    ('Professionals', 'Grow your career, lead with impact.'),
    ('Employees', 'Stay productive, balanced, and fulfilled.'),
    ('Everyday You', 'Build better habits, better health, a better life.'),
  ];

  const _Slide3({
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('For every you'),
          const SizedBox(height: 12),
          Text(
            'One platform. Every version of you.',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: _goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final isSelected = selected == i;
                final num = '0${i + 1}';
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accentGreen
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          num,
                          style: AppTextStyles.labelEyebrow.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _goals[i].$1,
                                style: AppTextStyles.cardTitle,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _goals[i].$2,
                                style: AppTextStyles.cardSubtitle,
                              ),
                            ],
                          ),
                        ),
                        GreenDot(size: isSelected ? 10 : 7),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Continue →', onPressed: onNext),
        ],
      ),
    );
  }
}

// ─── Slide 4 — Schedule ───────────────────────────────────────────────────────
class _Slide4 extends StatelessWidget {
  const _Slide4();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Your Schedule'),
          const SizedBox(height: 12),
          Text('Build your routine.', style: AppTextStyles.displayMedium),
          const SizedBox(height: 28),
          Expanded(
            child: ListView(
              children: const [
                _TimeField(label: 'Wake-up time', value: '6:30 AM'),
                SizedBox(height: 12),
                _TimeField(label: 'Sleep time', value: '10:30 PM'),
                SizedBox(height: 12),
                _TimeField(label: 'Study hours', value: '3 hours'),
                SizedBox(height: 12),
                _TimeField(label: 'Gym time', value: '7:00 AM'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  const _TimeField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.cardTitle),
        ],
      ),
    );
  }
}

// ─── Slide 5 — Permissions ────────────────────────────────────────────────────
class _Slide5 extends StatefulWidget {
  final VoidCallback onStart;
  const _Slide5({required this.onStart});

  @override
  State<_Slide5> createState() => _Slide5State();
}

class _Slide5State extends State<_Slide5> {
  bool _notif = true, _alarm = false, _calendar = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Permissions'),
          const SizedBox(height: 12),
          Text('Almost there.', style: AppTextStyles.displayMedium),
          const SizedBox(height: 28),
          _ToggleRow(
            label: 'Notifications',
            subtitle: 'Get smart reminders for your tasks',
            value: _notif,
            onChanged: (v) => setState(() => _notif = v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            label: 'Alarm access',
            subtitle: 'Wake up on time with Enbridge',
            value: _alarm,
            onChanged: (v) => setState(() => _alarm = v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            label: 'Calendar sync',
            subtitle: 'Sync your schedule automatically',
            value: _calendar,
            onChanged: (v) => setState(() => _calendar = v),
          ),
          const Spacer(),
          PrimaryButton(label: 'Get started', onPressed: widget.onStart),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentGreen,
            trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? AppColors.accentGreen.withValues(alpha: 0.3)
                  : AppColors.bgElevated,
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? AppColors.accentGreen
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
