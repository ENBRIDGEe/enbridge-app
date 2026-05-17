import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/widgets/shared_widgets.dart';
import 'package:fl_chart/fl_chart.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedMood = 1;
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _values = [5.0, 8.0, 6.0, 10.0, 7.0, 12.0, 4.0];

  static const _moods = [
    ('😄', 'Amazing'),
    ('🙂', 'Good'),
    ('😐', 'Okay'),
    ('😴', 'Tired'),
    ('😵', 'Burned Out'),
  ];

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
              const EyebrowLabel('Your week'),
              const SizedBox(height: 10),
              Text('Weekly overview.', style: AppTextStyles.displayHeading),
              const SizedBox(height: 28),

              // Bar chart
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                decoration: AppDecorations.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tasks completed', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          maxY: 14,
                          barGroups: List.generate(_days.length, (i) {
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: _values[i],
                                  color: AppColors.accentGreen,
                                  width: 22,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: 14,
                                    color: AppColors.bgElevated,
                                  ),
                                ),
                              ],
                            );
                          }),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, _) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _days[val.toInt()],
                                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stat cards row
              Row(
                children: const [
                  Expanded(child: _StatCard(label: 'Focus hours', value: '4h 20m')),
                  SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Tasks done', value: '38')),
                  SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Streak', value: '17 days')),
                ],
              ),
              const SizedBox(height: 24),

              // Insights
              const EyebrowLabel('Insights'),
              const SizedBox(height: 12),
              _InsightCard(
                  text: 'You\'re most productive on Saturdays — keep up the momentum!'),
              const SizedBox(height: 10),
              _InsightCard(
                  text: 'Your average focus session is 23 minutes. Try to push to 25!'),
              const SizedBox(height: 24),

              // Mood tracker
              const EyebrowLabel('Mood today'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_moods.length, (i) {
                  final sel = _selectedMood == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? AppColors.accentGreen : AppColors.border,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(_moods[i].$1, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(_moods[i].$2,
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: sel ? AppColors.accentGreen : AppColors.textTertiary)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.numberMedium.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String text;
  const _InsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: AppTextStyles.cardTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
