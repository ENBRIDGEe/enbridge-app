import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              Center(
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      'E',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGreen,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              Center(
                child: Text(
                  'About Enbridge',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 28.h),

              _body(
                'Enbridge is a modern productivity and life management platform designed to help students and young professionals stay organized, disciplined, and consistent in their daily lives.',
              ),
              SizedBox(height: 12.h),
              _body(
                'Our platform combines productivity tools, habit-building systems, focus management, analytics, and AI-powered assistance into one seamless experience.',
              ),
              SizedBox(height: 12.h),
              _body(
                'Unlike traditional productivity applications, Enbridge is designed around real student and lifestyle challenges — balancing academics, personal goals, routines, wellness, and daily responsibilities without burnout.',
              ),
              SizedBox(height: 28.h),

              _sectionTitle('Core Features'),
              SizedBox(height: 12.h),
              ...[
                'Smart task management',
                'Habit tracking and streak systems',
                'Focus sessions and productivity timers',
                'Smart reminders and notifications',
                'Productivity analytics and insights',
                'Emotional productivity tracking',
                'AI-powered planning and recommendations',
                'Cross-platform experience across mobile and web',
              ].map((f) => _bulletItem(f)),
              SizedBox(height: 28.h),

              _sectionTitle('Our Mission'),
              SizedBox(height: 12.h),
              _body(
                'Our mission is to help people reduce procrastination, improve consistency, build discipline, and achieve their goals through a smarter and more human-centered productivity experience.',
              ),
              SizedBox(height: 28.h),

              _sectionTitle('Our Vision'),
              SizedBox(height: 12.h),
              _body(
                'We envision Enbridge evolving into a complete personal operating system for life — helping users organize routines, improve productivity, maintain wellness, and grow consistently every day.',
              ),
              SizedBox(height: 28.h),

              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Built for students. Designed for growth. Powered by consistency.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15.sp,
                    color: AppColors.accentGreen,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 28.h),

              Divider(color: AppColors.border),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Version', style: AppTextStyles.bodyMedium),
                  Text('1.0.0', style: AppTextStyles.cardTitle),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Contact', style: AppTextStyles.bodyMedium),
                  Text('enbridge784@gmail.com',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentGreen, fontSize: 13.sp)),
                ],
              ),
              SizedBox(height: 16.h),
              SizedBox(height: 16.h),
              Divider(color: AppColors.border),
              SizedBox(height: 16.h),
              Center(
                child: Text(
                  'Developed by Debangshu Mounas.',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF888880),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: GoogleFonts.playfairDisplay(
      fontSize: 20.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
  );

  Widget _body(String t) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 14.sp,
      color: const Color(0xFF999990),
      height: 1.7,
    ),
  );

  Widget _bulletItem(String t) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 7.h),
          width: 6.w, height: 6.w,
          decoration: const BoxDecoration(
            color: AppColors.accentGreen,
            shape: BoxShape.circle,
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
