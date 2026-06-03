import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:enbridge/widgets/aiva_ring_widget.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  String? _selectedCategory;

  // Fix 1: track selected pain points
  final Set<String> _selectedPains = {};

  // Fix 2: editable schedule times
  final Map<String, TimeOfDay> _schedule = {
    'Wake up': const TimeOfDay(hour: 7, minute: 0),
    'Deep focus': const TimeOfDay(hour: 9, minute: 0),
    'Gym': const TimeOfDay(hour: 18, minute: 0),
    'Sleep': const TimeOfDay(hour: 23, minute: 0),
  };

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  void _nextPage() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveOnboardingData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('onboarding_responses').upsert({
          'user_id': user.id,
          'pain_points': _selectedPains.toList(),
          'user_type': _selectedCategory ?? 'Everyday You',
          'schedule': {
            'wake_up': _formatTime(_schedule['Wake up']!),
            'deep_focus': _formatTime(_schedule['Deep focus']!),
            'gym': _formatTime(_schedule['Gym']!),
            'sleep': _formatTime(_schedule['Sleep']!),
          },
        });
      } else {
        // Cache for later sync after auth
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'cached_pain_points',
          _selectedPains.toList(),
        );
        await prefs.setString(
          'cached_user_type',
          _selectedCategory ?? 'Everyday You',
        );
        await prefs.setString(
          'cached_schedule_wake_up',
          _formatTime(_schedule['Wake up']!),
        );
        await prefs.setString(
          'cached_schedule_deep_focus',
          _formatTime(_schedule['Deep focus']!),
        );
        await prefs.setString(
          'cached_schedule_gym',
          _formatTime(_schedule['Gym']!),
        );
        await prefs.setString(
          'cached_schedule_sleep',
          _formatTime(_schedule['Sleep']!),
        );
      }
    } catch (_) {}
  }

  Future<void> _goToRegister() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await _saveOnboardingData();
    if (mounted) {
      context.go('/register', extra: _selectedCategory ?? 'Everyday You');
    }
  }

  Future<void> _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await _saveOnboardingData();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPage1(),
                _buildPage2(),
                _buildPage3(),
                _buildPage4(),
                _buildPage5(),
              ],
            ),
            Positioned(
              top: 16.h,
              right: 16.w,
              child: TextButton(
                onPressed: _goToLogin,
                child: Text(
                  'Skip',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accentGreen,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30.h,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _controller,
                  count: 5,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppColors.accentGreen,
                    dotColor: AppColors.bgElevated,
                    dotHeight: 8.h,
                    dotWidth: 8.w,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Particle / orb background ────────────────────────────────────
        const _ParticleBackground(),

        // ── Main content ─────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),

              // AIVA ring animation
              AIVARingWidget(size: 180.w, animate: true),

              SizedBox(height: 20.h),

              // ── Sound wave bars (standalone, below ring) ───────────────
              const _SoundWaveBars(),

              SizedBox(height: 28.h),

              // ── Glassmorphism card ─────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 28.h),
                    decoration: BoxDecoration(
                      color: AppColors.aivaBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(
                        color: AppColors.aivaBlueMid.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Powered badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.aivaBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: AppColors.aivaBlueMid.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Text(
                            '✦  Powered by AIVA AI',
                            style: AppTextStyles.labelEyebrow.copyWith(
                              fontSize: 10.sp,
                              color: AppColors.aivaBlueMid,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),

                        SizedBox(height: 18.h),

                        // Headline
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              AppColors.textPrimary,
                              AppColors.aivaBlueMid,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'Enbridge',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 48.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        Text(
                          'Your productivity bridge\nto maximum potential.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.6,
                            fontSize: 13.sp,
                          ),
                        ),

                        SizedBox(height: 28.h),

                        // Primary CTA — blue gradient
                        GestureDetector(
                          onTap: _nextPage,
                          child: Container(
                            width: double.infinity,
                            height: 52.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.aivaGradStart,
                                  AppColors.aivaGradEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(50.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.aivaBlue.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Get Started',
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Secondary CTA — ghost
                        GestureDetector(
                          onTap: _goToLogin,
                          child: Container(
                            width: double.infinity,
                            height: 52.h,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(50.r),
                              border: Border.all(color: AppColors.borderMid),
                            ),
                            child: Center(
                              child: Text(
                                'Log In',
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPage2() {
    final painOptions = [
      'Procrastination',
      'Lack of focus',
      'Disorganized tasks',
      'Low motivation',
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is holding you back?',
            style: AppTextStyles.displayHeading,
          ),
          SizedBox(height: 8.h),
          Text('Select all that apply', style: AppTextStyles.bodySmall),
          SizedBox(height: 24.h),
          ...painOptions.map((text) => _painCard(text)),
          SizedBox(height: 48.h),
          _nextBtn(),
        ],
      ),
    );
  }

  Widget _painCard(String text) {
    final isSelected = _selectedPains.contains(text);
    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedPains.remove(text);
        } else {
          _selectedPains.add(text);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.h),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGreen.withValues(alpha: 0.12)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? AppColors.accentGreen : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accentGreen : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, color: Colors.black, size: 14.sp)
                  : null,
            ),
            SizedBox(width: 16.w),
            Text(
              text,
              style: AppTextStyles.cardTitle.copyWith(
                color: isSelected
                    ? AppColors.accentGreen
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage3() {
    final types = ['Student', 'Professional', 'Employee', 'Everyday You'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Who are you?', style: AppTextStyles.displayHeading),
          SizedBox(height: 32.h),
          ...types.map(
            (e) => GestureDetector(
              onTap: () => setState(() => _selectedCategory = e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: 12.h),
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _selectedCategory == e
                      ? AppColors.accentGreen.withValues(alpha: 0.12)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _selectedCategory == e
                        ? AppColors.accentGreen
                        : AppColors.border,
                    width: _selectedCategory == e ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  e,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: _selectedCategory == e
                        ? AppColors.accentGreen
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 48.h),
          _nextBtn(),
        ],
      ),
    );
  }

  Widget _buildPage4() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ideal schedule', style: AppTextStyles.displayHeading),
          SizedBox(height: 8.h),
          Text('Tap a time to edit it', style: AppTextStyles.bodySmall),
          SizedBox(height: 32.h),
          ..._schedule.entries.map((e) => _timeRow(e.key, e.value)),
          SizedBox(height: 48.h),
          _nextBtn(),
        ],
      ),
    );
  }

  Widget _timeRow(String label, TimeOfDay time) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.accentGreen,
                      onPrimary: Colors.black,
                      surface: Color(0xFF1A1A1A),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => _schedule[label] = picked);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(time),
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentGreen,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.edit_rounded,
                    color: AppColors.accentGreen,
                    size: 14.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage5() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 64.sp,
            color: AppColors.accentGreen,
          ),
          SizedBox(height: 24.h),
          Text('Stay on track', style: AppTextStyles.displayHeading),
          SizedBox(height: 16.h),
          Text(
            'We will need permissions to send you reminders and notifications to keep you accountable.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          SizedBox(height: 48.h),
          ElevatedButton(
            onPressed: _goToRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.r),
              ),
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16.h),
          TextButton(
            onPressed: _goToLogin,
            style: TextButton.styleFrom(
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.r),
                side: BorderSide(color: AppColors.border),
              ),
            ),
            child: Text(
              'Log In',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextBtn() {
    return ElevatedButton(
      onPressed: _nextPage,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: Colors.black,
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.r),
        ),
      ),
      child: const Text('Continue'),
    );
  }
}

// ── Particle background ───────────────────────────────────────────────────────

class _ParticleBackground extends StatefulWidget {
  const _ParticleBackground();

  @override
  State<_ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<_ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const _orbs = [
    _OrbData(dx: 0.15, dy: 0.12, size: 180, alpha: 0.07, speed: 0.0),
    _OrbData(dx: 0.80, dy: 0.08, size: 140, alpha: 0.05, speed: 0.3),
    _OrbData(dx: 0.60, dy: 0.75, size: 200, alpha: 0.06, speed: 0.6),
    _OrbData(dx: 0.05, dy: 0.65, size: 120, alpha: 0.04, speed: 0.9),
    _OrbData(dx: 0.90, dy: 0.50, size: 100, alpha: 0.05, speed: 0.45),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        return Stack(
          children: _orbs.map((orb) {
            final t = (_ctrl.value + orb.speed) % 1.0;
            final dy = sin(t * 2 * pi) * 12;
            return Positioned(
              left: orb.dx * size.width - orb.size / 2,
              top: orb.dy * size.height - orb.size / 2 + dy,
              child: Container(
                width: orb.size,
                height: orb.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.aivaBlue.withValues(alpha: orb.alpha),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _OrbData {
  final double dx, dy, size, alpha, speed;
  const _OrbData({
    required this.dx,
    required this.dy,
    required this.size,
    required this.alpha,
    required this.speed,
  });
}

// ── Sound wave bars ───────────────────────────────────────────────────────────

class _SoundWaveBars extends StatefulWidget {
  const _SoundWaveBars();

  @override
  State<_SoundWaveBars> createState() => _SoundWaveBarsState();
}

class _SoundWaveBarsState extends State<_SoundWaveBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Heights matching AIVA Freelancia SVG: 40 80 120 60 20
    final baseHeights = [10.0, 20.0, 30.0, 15.0, 6.0];
    final phases = [0.0, 0.3, 0.6, 0.9, 1.2];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(5, (i) {
            final animFactor = 0.5 + 0.5 * sin((_ctrl.value + phases[i]) * pi);
            final h = baseHeights[i] * (0.6 + 0.4 * animFactor);
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: 4.w,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2.r),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.aivaGradStart, AppColors.aivaGradEnd],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
