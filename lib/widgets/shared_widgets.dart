import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';

/// A pill-shaped primary (white fill) CTA button
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: AppColors.bgPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 0,
        ),
        onPressed: onPressed ?? () {},
        child: Text(label, style: AppTextStyles.ctaButton),
      ),
    );
  }
}

/// A pill-shaped secondary (dark fill, border) CTA button
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.bgCard,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: Color(0xFF333330), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 0,
        ),
        onPressed: onPressed ?? () {},
        child: Text(label, style: AppTextStyles.ctaButtonSecondary),
      ),
    );
  }
}

/// Eyebrow label in uppercase + tracked Inter
class EyebrowLabel extends StatelessWidget {
  final String text;
  const EyebrowLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTextStyles.labelEyebrow);
  }
}

/// Standard dark card container
class AppCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color? color;
  final EdgeInsets? padding;
  final bool showBorder;

  const AppCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.color,
    this.padding,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: AppDecorations.card(
        color: color,
        radius: radius,
        border: showBorder,
      ),
      child: child,
    );
  }
}

/// Green dot indicator
class GreenDot extends StatelessWidget {
  final double size;
  const GreenDot({super.key, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.accentGreen,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Focus bar gradient progress bar
class FocusProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0

  const FocusProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Stack(
        children: [
          Container(height: 6, color: const Color(0xFF2A2A2A)),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.focusGradientStart, AppColors.focusGradientEnd],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Divider line
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.border,
    );
  }
}

/// Back pill button
class BackPillButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const BackPillButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('← Back', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
      ),
    );
  }
}

/// Seven-day habit tracker squares
class HabitWeekTracker extends StatelessWidget {
  final List<bool?> days; // true=done, false=missed, null=today

  const HabitWeekTracker({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: days.map((done) {
        Color color;
        if (done == null) {
          color = AppColors.accentGreen.withValues(alpha: 0.38);
        } else if (done) {
          color = AppColors.accentGreen;
        } else {
          color = const Color(0xFF2A2A2A);
        }
        return Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }).toList(),
    );
  }
}
