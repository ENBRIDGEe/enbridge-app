import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String category;
  const RegisterScreen({super.key, required this.category});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _showConfirmError = false;
  bool _showSuccess = false;
  bool _isLoading = false;

  Future<void> _register() async {
    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _showConfirmError = true);
      return;
    }
    setState(() {
      _showConfirmError = false;
      _isLoading = true;
    });

    try {
      await supabase.auth.signUp(
        email: _emailCtrl.text,
        password: _passCtrl.text,
        data: {'name': widget.category},
      );
      if (mounted) setState(() => _showSuccess = true);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      String friendly;
      if (msg.contains('already registered') || msg.contains('user_already_exists')) {
        // show snackbar with login action
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('An account with this email already exists. Try logging in.'),
              action: SnackBarAction(label: 'Log in', onPressed: () => context.go('/login')),
              backgroundColor: const Color(0xFF2D1515),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }
        return;
      } else if (msg.contains('over_email_send_rate_limit') ||
                 msg.contains('email rate limit') ||
                 msg.contains('too many requests')) {
        friendly = 'Too many sign-up attempts. Please wait a few minutes and try again.';
      } else if (msg.contains('invalid email')) {
        friendly = 'Please enter a valid email address.';
      } else if (msg.contains('password') && msg.contains('weak')) {
        friendly = 'Password is too weak. Use at least 6 characters.';
      } else {
        friendly = 'Registration failed. Please try again.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(friendly, style: const TextStyle(color: Colors.white))),
          ]),
          backgroundColor: const Color(0xFF2D1515),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Something went wrong. Please try again.'),
          backgroundColor: const Color(0xFF2D1515),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: '534783747908-qu45emh5u5dqkniv996siilsoe91d0f5.apps.googleusercontent.com',
    );
    
    await googleSignIn.signOut(); // clear any cached account first
    
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return; // user cancelled
    
    final googleAuth = await googleUser.authentication;
    
    if (googleAuth.idToken == null) {
      throw Exception('No ID token received from Google');
    }
    
    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );
  } catch (e) {
    debugPrint('Google Sign-In error: $e');
    // show snackbar with e.toString()
  }
}
  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Check your inbox.', style: GoogleFonts.playfairDisplay(fontSize: 28.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  Text('We\'ve sent a confirmation link to ${_emailCtrl.text}. Tap it to activate your account.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: () async {
                      await supabase.auth.resend(type: OtpType.signup, email: _emailCtrl.text);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email resent')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgCard,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                    child: const Text('Resend email'),
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text('Back to login', style: TextStyle(color: AppColors.accentGreen, fontSize: 16.sp)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24.sp),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20.h),
                Text('Create Account', style: AppTextStyles.displayHeading.copyWith(fontSize: 32.sp)),
                SizedBox(height: 8.h),
                Text('Join Enbridge for  goals.', style: AppTextStyles.bodyMedium),
                SizedBox(height: 48.h),

                TextField(
                  controller: _emailCtrl,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _confirmPassCtrl,
                  obscureText: true,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  ),
                ),
                if (_showConfirmError)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h, left: 4.w),
                    child: Text('Passwords do not match', style: TextStyle(color: Colors.redAccent, fontSize: 14.sp)),
                  ),
                SizedBox(height: 32.h),

                GestureDetector(
                  onTap: () => signInWithGoogle(),
                  child: Container(
                    width: 52.h,
                    height: 52.h,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.g_mobiledata, color: Colors.white, size: 36.sp), // Placeholder for google logo
                    ),
                  ),
                ),
                SizedBox(height: 32.h),

                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.black,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : Text('Sign up', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 48.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}






