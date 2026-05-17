import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/widgets/shared_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Avatar
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text('A',
                      style: GoogleFonts.inter(
                          fontSize: 28, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(height: 14),
              Text('Alex Johnson', style: AppTextStyles.displaySmall.copyWith(fontSize: 22)),
              const SizedBox(height: 4),
              Text('alex@example.com', style: AppTextStyles.bodySmall),
              const SizedBox(height: 28),

              // Productivity score card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: AppDecorations.card(),
                child: Column(
                  children: [
                    const EyebrowLabel('Productivity score'),
                    const SizedBox(height: 16),
                    CircularPercentIndicator(
                      radius: 65,
                      lineWidth: 7,
                      percent: 0.78,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('78',
                              style: AppTextStyles.numberMedium.copyWith(fontSize: 28)),
                          Text('%', style: AppTextStyles.bodySmall),
                        ],
                      ),
                      progressColor: AppColors.accentGreen,
                      backgroundColor: AppColors.bgElevated,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings rows
              const EyebrowLabel('Settings'),
              const SizedBox(height: 12),
              ..._settingsItems(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _settingsItems(BuildContext context) {
    final items = [
      (Icons.notifications_outlined, 'Notifications', false),
      (Icons.schedule_outlined, 'Schedule', false),
      (Icons.flag_outlined, 'Goals', false),
      (Icons.lock_outline_rounded, 'Privacy', false),
      (Icons.palette_outlined, 'App theme', false),
    ];

    return [
      ...items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _SettingsRow(icon: item.$1, label: item.$2),
      )),
      const SizedBox(height: 4),
      _SettingsRow(icon: Icons.logout_rounded, label: 'Log out', isDestructive: true),
    ];
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: AppDecorations.card(radius: 16),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: isDestructive ? AppColors.accentRed : AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: AppTextStyles.cardTitle.copyWith(
                    color: isDestructive ? AppColors.accentRed : AppColors.textPrimary)),
          ),
          if (!isDestructive)
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
        ],
      ),
    );
  }
}
