import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/widgets/shared_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final List<_HabitData> _habits = [
    _HabitData(
      name: 'Morning workout',
      streak: 12,
      days: [true, true, true, false, true, true, null],
      done: true,
    ),
    _HabitData(
      name: 'Read 30 minutes',
      streak: 7,
      days: [true, false, true, true, true, null, null],
      done: false,
    ),
    _HabitData(
      name: 'Drink 2L water',
      streak: 21,
      days: [true, true, true, true, true, true, null],
      done: true,
    ),
    _HabitData(
      name: 'No social media before 9AM',
      streak: 4,
      days: [false, false, true, true, true, null, null],
      done: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: GestureDetector(
        onTap: () {},
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('+', style: GoogleFonts.inter(
                  fontSize: 20, color: AppColors.accentGreen, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('Add habit', style: AppTextStyles.cardTitle),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const EyebrowLabel('Your habits'),
              const SizedBox(height: 10),
              Text('Build consistency.', style: AppTextStyles.displayHeading),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _habits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final h = _habits[i];
                    return _HabitCard(
                      habit: h,
                      onToggle: () => setState(() => _habits[i] =
                          h.copyWith(done: !h.done)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final _HabitData habit;
  final VoidCallback onToggle;
  const _HabitCard({required this.habit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(habit.name, style: AppTextStyles.cardTitle),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: habit.done ? AppColors.accentGreen : Colors.transparent,
                    border: Border.all(
                      color: habit.done ? AppColors.accentGreen : AppColors.textTertiary,
                      width: 1.5,
                    ),
                  ),
                  child: habit.done
                      ? const Icon(Icons.check, size: 14, color: AppColors.bgPrimary)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('🔥 ${habit.streak} days',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.accentOrange,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 12),
          HabitWeekTracker(days: habit.days),
        ],
      ),
    );
  }
}

class _HabitData {
  final String name;
  final int streak;
  final List<bool?> days;
  final bool done;

  const _HabitData({
    required this.name,
    required this.streak,
    required this.days,
    required this.done,
  });

  _HabitData copyWith({bool? done}) =>
      _HabitData(name: name, streak: streak, days: days, done: done ?? this.done);
}
