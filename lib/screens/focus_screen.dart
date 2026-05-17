import 'dart:async';
import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/widgets/shared_widgets.dart';
import 'package:percent_indicator/percent_indicator.dart';


class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final int _totalSeconds = 25 * 60;
  int _remaining = 24 * 60 + 13;
  bool _running = true;
  Timer? _timer;
  int _selectedSound = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_running && _remaining > 0) {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeString {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => _remaining / _totalSeconds;

  @override
  Widget build(BuildContext context) {
    final sounds = ['Rain', 'Lo-fi', 'Silence'];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const EyebrowLabel('Focus session'),
              const SizedBox(height: 40),

              // Circular timer
              CircularPercentIndicator(
                radius: 130,
                lineWidth: 8,
                percent: _progress.clamp(0.0, 1.0),
                center: Text(_timeString, style: AppTextStyles.timerLarge),
                progressColor: AppColors.accentGreen,
                backgroundColor: AppColors.bgElevated,
                circularStrokeCap: CircularStrokeCap.round,
                animation: false,
              ),
              const SizedBox(height: 32),

              // Quote
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '"Focus is the art of knowing what to ignore."',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyQuote,
                ),
              ),
              const SizedBox(height: 36),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionBtn(
                    icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    onTap: () => setState(() => _running = !_running),
                  ),
                  const SizedBox(width: 16),
                  _ActionBtn(
                    icon: Icons.check_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => setState(() => _remaining += 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('+5 min', style: AppTextStyles.cardTitle),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Sound chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(sounds.length, (i) {
                  final sel = _selectedSound == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSound = i),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? AppColors.accentGreen : AppColors.border,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Text(sounds[i],
                          style: AppTextStyles.tagLabel.copyWith(
                              color: sel ? AppColors.accentGreen : AppColors.textSecondary)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Stats row
              Row(
                children: const [
                  Expanded(child: _StatCard(label: 'Focus', value: '1h 47m')),
                  SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Break', value: '12m')),
                  SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Sessions', value: '3')),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 24),
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
      decoration: AppDecorations.card(color: AppColors.bgSurface, radius: 14),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.numberMedium),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
