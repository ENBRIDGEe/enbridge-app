import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _success = false;

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
          color: Colors.white, size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: isError ? const Color(0xFF2D1515) : const Color(0xFF152D1E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> _updatePassword() async {
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill in both fields.');
      return;
    }
    if (pass.length < 6) {
      _showSnack('Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      _showSnack('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: pass));
      if (mounted) {
        setState(() => _success = true);
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to update password. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80.w, height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_open_rounded, color: AppColors.accentGreen, size: 40.sp),
                  ),
                  SizedBox(height: 32.h),
                  Text('Password updated!',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text('You can now log in with your new password.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40.h),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.black,
                      minimumSize: Size(double.infinity, 56.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
                    ),
                    child: Text('Back to login', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22.sp),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            Text(
              'New password',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text('Enter and confirm your new password.', style: AppTextStyles.bodyMedium),
            SizedBox(height: 40.h),

            // New password
            TextField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'New password',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgElevated,
                prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20.sp),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary, size: 20.sp),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              ),
            ),
            SizedBox(height: 16.h),

            // Confirm password
            TextField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'Confirm new password',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgElevated,
                prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20.sp),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary, size: 20.sp),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              ),
            ),
            SizedBox(height: 32.h),

            ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 56.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text('Update password', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
