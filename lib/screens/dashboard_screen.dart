import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/widgets/shared_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning, Alex',
                        style: AppTextStyles.greetingText,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saturday, 17 May 2026',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'A',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Progress card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: AppDecorations.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const EyebrowLabel('Today'),
                        // Streak chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: AppDecorations.elevatedCard(radius: 12),
                          child: Column(
                            children: [
                              const EyebrowLabel('Streak'),
                              const SizedBox(height: 2),
                              Text(
                                '17 days',
                                style: AppTextStyles.numberMedium.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('8 of 12', style: AppTextStyles.numberLarge),
                    const SizedBox(height: 2),
                    Text('tasks completed', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Focus mode card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: AppDecorations.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Focus mode', style: AppTextStyles.cardTitle),
                        Text(
                          '25:00',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const FocusProgressBar(value: 0.4),
                    const SizedBox(height: 16),
                    Text(
                      '"Small progress every day leads to big results."',
                      style: AppTextStyles.bodyQuote,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // User type grid
              const EyebrowLabel('For every you'),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: const [
                  _UserTypeCard(
                    title: 'Students',
                    subtitle:
                        'Ace your studies, build skills, shape your future.',
                  ),
                  _UserTypeCard(
                    title: 'Professionals',
                    subtitle: 'Grow your career, lead with impact.',
                  ),
                  _UserTypeCard(
                    title: 'Employees',
                    subtitle: 'Stay productive, balanced, and fulfilled.',
                  ),
                  _UserTypeCard(
                    title: 'Everyday You',
                    subtitle:
                        'Build better habits, better health, a better life.',
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Timeline
              const EyebrowLabel("Today's Timeline"),
              const SizedBox(height: 14),
              ..._timelineItems(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _timelineItems() {
    final items = [
      ('6:30 AM', 'Morning workout', 'done'),
      ('9:00 AM', 'Study — Physics chapter 4', 'done'),
      ('11:00 AM', 'Group project meeting', 'active'),
      ('2:00 PM', 'Lunch & break', 'pending'),
      ('4:00 PM', 'Review notes & flashcards', 'pending'),
    ];
    return items.map((e) {
      Color dotColor;
      if (e.$3 == 'done') {
        dotColor = AppColors.accentGreen;
      } else if (e.$3 == 'active')
        dotColor = AppColors.accentOrange;
      else
        dotColor = const Color(0xFF3A3A3A);

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppDecorations.card(radius: 14),
          child: Row(
            children: [
              Text(
                e.$1,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(e.$2, style: AppTextStyles.cardTitle)),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _UserTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _UserTypeCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              subtitle,
              style: AppTextStyles.cardSubtitle,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
