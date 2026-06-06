import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Privacy Policy',
          style: GoogleFonts.inter(fontSize: 17.sp, fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 48.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text('Effective Date: May 2026', style: AppTextStyles.bodySmall),
              SizedBox(height: 24.h),

              _body(
                'Welcome to Enbridge. Your privacy is important to us. This Privacy Policy explains how Enbridge collects, uses, stores, and protects your information when you use our mobile application, website, and related services.',
              ),
              SizedBox(height: 24.h),

              _section('1. Information We Collect'),
              _subTitle('Account Information'),
              _body('When you create an account, we may collect:'),
              SizedBox(height: 8.h),
              ...[
                'Name',
                'Email address',
                'Profile picture',
                'Login credentials through Google or email authentication',
              ].map(_bullet),

              SizedBox(height: 16.h),
              _subTitle('Usage & Productivity Data'),
              _body('To provide personalized productivity experiences, we may collect:'),
              SizedBox(height: 8.h),
              ...[
                'Tasks and schedules',
                'Habit tracking information',
                'Focus session activity',
                'Productivity analytics',
                'Mood and wellness inputs',
                'Notification preferences',
              ].map(_bullet),

              SizedBox(height: 16.h),
              _subTitle('Technical Information'),
              _body('We may automatically collect:'),
              SizedBox(height: 8.h),
              ...[
                'Device type and operating system',
                'IP address',
                'App version',
                'Crash reports and diagnostics',
                'Browser type and device identifiers',
              ].map(_bullet),

              SizedBox(height: 24.h),
              _section('2. How We Use Your Information'),
              _body('We use collected information to:'),
              SizedBox(height: 8.h),
              ...[
                'Provide and improve our services',
                'Personalize user experience',
                'Generate productivity insights and analytics',
                'Send reminders, notifications, and updates',
                'Maintain security and prevent unauthorized access',
                'Improve app performance and reliability',
              ].map(_bullet),

              SizedBox(height: 24.h),
              _section('3. AI-Powered Features'),
              _body(
                'Enbridge may use AI technologies to generate schedules, recommend routines, organize tasks, and provide productivity suggestions. AI-generated content is intended for informational purposes only and should not be considered professional, medical, or psychological advice.',
              ),

              SizedBox(height: 24.h),
              _section('4. Data Storage & Security'),
              _body(
                'We implement industry-standard security practices, including encrypted communication, secure authentication systems, protected cloud infrastructure, and restricted access controls to help protect your information.\n\nWhile we strive to use commercially acceptable means to protect your data, no method of electronic storage or internet transmission is completely secure.',
              ),

              SizedBox(height: 24.h),
              _section('5. Sharing of Information'),
              _body('Enbridge does not sell or rent personal data to third parties.'),
              SizedBox(height: 8.h),
              _body('We may share limited information with trusted third-party service providers used for:'),
              SizedBox(height: 8.h),
              ...[
                'Authentication services',
                'Cloud storage',
                'Analytics',
                'Notifications',
                'AI functionality',
              ].map(_bullet),
              SizedBox(height: 8.h),
              _body('These providers are required to maintain confidentiality and security standards.'),

              SizedBox(height: 24.h),
              _section('6. Cookies & Authentication'),
              _body(
                'Enbridge may use cookies, tokens, and secure authentication technologies to improve login experience, maintain sessions, and enhance platform functionality.',
              ),

              SizedBox(height: 24.h),
              _section('7. User Rights & Controls'),
              _body('Users may:'),
              SizedBox(height: 8.h),
              ...[
                'Access and update account information',
                'Delete tasks and personal data',
                'Disable notifications',
                'Request account deletion',
              ].map(_bullet),
              SizedBox(height: 8.h),
              _body('For account deletion or privacy-related requests, contact:'),
              SizedBox(height: 4.h),
              Text('enbridge784@gmail.com',
                style: GoogleFonts.inter(
                  fontSize: 14.sp, color: AppColors.accentGreen, fontWeight: FontWeight.w500)),

              SizedBox(height: 24.h),
              _section('8. Children\'s Privacy'),
              _body('Enbridge is not intended for children under the age of 13 without parental consent.'),

              SizedBox(height: 24.h),
              _section('9. Changes to This Policy'),
              _body(
                'We may update this Privacy Policy periodically. Continued use of Enbridge after policy changes constitutes acceptance of the updated policy.',
              ),

              SizedBox(height: 24.h),
              _section('10. Contact Us'),
              _body('For questions regarding this Privacy Policy or your data:'),
              SizedBox(height: 4.h),
              Text('Email: enbridge784@gmail.com',
                style: GoogleFonts.inter(
                  fontSize: 14.sp, color: AppColors.accentGreen, fontWeight: FontWeight.w500)),

              SizedBox(height: 32.h),
              Divider(color: AppColors.border),
              SizedBox(height: 12.h),
              Text('Last updated: May 2026', style: AppTextStyles.bodySmall),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: Text(
      t,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _subTitle(String t) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Text(
      t,
      style: GoogleFonts.inter(
        fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _body(String t) => Text(
    t,
    style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF999990), height: 1.7),
  );

  Widget _bullet(String t) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 7.h),
          width: 5.w, height: 5.w,
          decoration: const BoxDecoration(
            color: AppColors.accentGreen, shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            t,
            style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF999990), height: 1.6),
          ),
        ),
      ],
    ),
  );
}
