import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/widgets/shared_widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback? onRegister;
  final VoidCallback? onBack;

  const LoginScreen({
    super.key,
    required this.onLogin,
    this.onRegister,
    this.onBack,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                BackPillButton(onPressed: widget.onBack),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EyebrowLabel('Enbridge'),
                      const SizedBox(height: 14),
                      Text('Welcome back.', style: AppTextStyles.displayLarge),
                      const SizedBox(height: 12),
                      Text(
                        'Log in to reach your dashboard, task list, habits, and focus sessions.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      _fieldLabel('Email'),
                      const SizedBox(height: 8),
                      TextField(
                        style: AppTextStyles.inputText,
                        keyboardType: TextInputType.emailAddress,
                        decoration: AppDecorations.inputDecoration(hint: 'you@example.com'),
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        style: AppTextStyles.inputText,
                        obscureText: _obscure,
                        decoration: AppDecorations.inputDecoration(
                          hint: '••••••••',
                          suffix: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textTertiary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: GestureDetector(
                          onTap: widget.onLogin,
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.bgElevated,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Center(
                              child: SvgPicture.asset('assets/svg/google_logo.svg',
                                  width: 22, height: 22),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(label: 'Log in', onPressed: widget.onLogin),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: widget.onRegister,
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: 'Need an account? ', style: AppTextStyles.bodySmall),
                            TextSpan(text: 'Register',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600)),
                          ])),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500));
}
