import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;

  // Fix 5: map raw exception to friendly message
  String _friendlyError(Object e) {
    final raw = e.toString().toLowerCase();
    if (raw.contains('invalid_credentials') || raw.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (raw.contains('user_not_found') || raw.contains('no user found')) {
      return 'No account found with this email.';
    }
    if (raw.contains('email_not_confirmed')) {
      return 'Please confirm your email before logging in.';
    }
    if (raw.contains('too many requests') || raw.contains('rate limit')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: isError ? const Color(0xFF2D1515) : const Color(0xFF152D1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      _showSnackBar('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithPassword(email: email, password: pass);
    } catch (e) {
      if (mounted) _showSnackBar(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      const webClientId = '534783747908-qu45emh5u5dqkniv996siilsoe91d0f5.apps.googleusercontent.com';
      final googleSignIn = GoogleSignIn(serverClientId: webClientId);
      
      // Clear any bad cached state from previous failed attempts
      await googleSignIn.signOut();
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken != null) {
        await supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fix 4: Forgot password bottom sheet
  void _openForgotPassword() {
    final resetEmailCtrl = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 40.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w, height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Reset password',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Enter your email and we\'ll send a reset link.',
                      style: AppTextStyles.bodySmall,
                    ),
                    SizedBox(height: 24.h),
                    TextField(
                      controller: resetEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Your email',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20.sp),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                      onPressed: isSending
                          ? null
                          : () async {
                              final email = resetEmailCtrl.text.trim();
                              if (email.isEmpty) return;
                              setSheetState(() => isSending = true);
                              try {
                                await supabase.auth.resetPasswordForEmail(email);
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                _showSnackBar(
                                  'Password reset link sent to $email',
                                  isError: false,
                                );
                              } catch (e) {
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                _showSnackBar('Could not send reset email. Please try again.');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: Size(double.infinity, 54.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
                      ),
                      child: isSending
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Text('Send reset link', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60.h),
                Text('Welcome Back', style: AppTextStyles.displayHeading.copyWith(fontSize: 32.sp)),
                SizedBox(height: 8.h),
                Text('Log in to continue building your habits and tracking goals.', style: AppTextStyles.bodyMedium),
                SizedBox(height: 48.h),

                // Email field
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20.sp),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  ),
                ),
                SizedBox(height: 16.h),

                // Password field
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20.sp),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 20.sp),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  ),
                ),

                // Fix 4: Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _openForgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(color: AppColors.accentGreen, fontSize: 14.sp),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),

                // Google sign-in centered
                Center(
                  child: GestureDetector(
                    onTap: () => signInWithGoogle(),
                    child: Container(
                      width: 52.h,
                      height: 52.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.g_mobiledata, color: Colors.white, size: 36.sp),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.black,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : Text('Login', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ),

                SizedBox(height: 48.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: () => context.go('/register', extra: 'Personal'),
                      child: Text('Sign up', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
