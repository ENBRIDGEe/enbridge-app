import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';

/// Circular AIVA logo avatar — used as the AIVA "DP" everywhere in the app.
class AIVALogoAvatar extends StatelessWidget {
  final double size;
  const AIVALogoAvatar({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.aivaGradStart, AppColors.aivaGradEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.aivaBlue.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/Full AIVA logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Image.asset(
              'assets/images/aiva_logo.png',
              width: size * 0.65,
              height: size * 0.65,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
