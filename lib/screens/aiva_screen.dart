import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/providers/aiva_provider.dart';
import 'package:enbridge/widgets/aiva_ring_widget.dart';
import 'package:enbridge/widgets/aiva_session_card.dart';

class AIVAScreen extends ConsumerWidget {
  const AIVAScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(aivaSessionProvider);
    final activeSession = ref.watch(activeAIVASessionProvider);
    final pastSessions = sessions.where((s) => !s.isActive).toList().reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // Background radial glow
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.aivaBlue.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AIVA AI',
                                style: AppTextStyles.labelEyebrow.copyWith(
                                  color: AppColors.aivaBlueMid,
                                  letterSpacing: 3,
                                  fontSize: 11.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Your AI Companion',
                                style: AppTextStyles.displaySmall.copyWith(fontSize: 22.sp),
                              ),
                            ],
                          ),
                        ),
                        // Mini ring icon
                        AIVARingWidget(size: 48.w, animate: true),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 32.h)),

                // ── Hero ring + Live / Start button ────────────────────────
                SliverToBoxAdapter(
                  child: _HeroRingSection(activeSession: activeSession, ref: ref),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 32.h)),

                // ── Active session card ────────────────────────────────────
                if (activeSession != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT SESSION',
                            style: AppTextStyles.labelEyebrow.copyWith(fontSize: 10.sp),
                          ),
                          SizedBox(height: 12.h),
                          AIVASessionCard(session: activeSession, isActive: true),
                        ],
                      ),
                    ),
                  ),

                if (activeSession != null)
                  SliverToBoxAdapter(child: SizedBox(height: 28.h)),

                // ── Past sessions ──────────────────────────────────────────
                if (pastSessions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        'SESSION HISTORY',
                        style: AppTextStyles.labelEyebrow.copyWith(fontSize: 10.sp),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final session = pastSessions[index];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 12.h),
                        child: GestureDetector(
                          onTap: () => context.push(
                            '/aiva/chat',
                            extra: {'topic': session.topic},
                          ),
                          child: AIVASessionCard(session: session),
                        ),
                      );
                    },
                    childCount: pastSessions.length,
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 120.h)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero section with large ring ──────────────────────────────────────────────

class _HeroRingSection extends StatelessWidget {
  final AIVASession? activeSession;
  final WidgetRef ref;

  const _HeroRingSection({required this.activeSession, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // Large ring
          AIVARingWidget(size: 160.w, animate: true),

          SizedBox(height: 24.h),

          // Status text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: activeSession != null
                ? Column(
                    key: const ValueKey('active'),
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.aivaGradStart, AppColors.aivaGradEnd],
                        ).createShader(bounds),
                        child: Text(
                          'Session Active',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        activeSession!.topic,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.aivaBlueMid,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('idle'),
                    children: [
                      Text(
                        'Ready to assist',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Start a session to get personalised AI guidance',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),

          SizedBox(height: 24.h),

          // CTA Button
          _AIVACTAButton(
            isActive: activeSession != null,
            onTap: () {
              if (activeSession == null) {
                _showNewSessionSheet(context, ref);
              } else {
                context.push('/aiva/chat', extra: {'topic': activeSession!.topic});
              }
            },
          ),
        ],
      ),
    );
  }

  void _showNewSessionSheet(BuildContext context, WidgetRef ref) {
    final topicCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewSessionSheet(
        controller: topicCtrl,
        onStart: (topic) {
          ref.read(aivaSessionProvider.notifier).startNewSession(topic);
          ref.read(aivaChatProvider.notifier).reset();
          Navigator.pop(context);
          context.push('/aiva/chat', extra: {'topic': topic});
        },
      ),
    );
  }
}

class _AIVACTAButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _AIVACTAButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.aivaGradStart, AppColors.aivaGradEnd],
              ),
              borderRadius: BorderRadius.circular(50.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.aivaBlue.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              isActive ? 'Open Session' : 'Start Session',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── New session bottom sheet ───────────────────────────────────────────────────

class _NewSessionSheet extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onStart;

  const _NewSessionSheet({required this.controller, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24.w, 20.h, 24.w,
            MediaQuery.of(context).viewInsets.bottom + 32.h,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgSurface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            border: const Border(
              top: BorderSide(color: AppColors.borderMid, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text('New AIVA Session', style: AppTextStyles.displaySmall.copyWith(fontSize: 20.sp)),
              SizedBox(height: 6.h),
              Text(
                'What would you like to talk about?',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: controller,
                autofocus: true,
                style: AppTextStyles.inputText,
                decoration: AppDecorations.inputDecoration(
                  hint: 'e.g. Goal planning, deep focus, productivity…',
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.aivaGradStart, AppColors.aivaGradEnd],
                    ),
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      final topic = controller.text.trim();
                      onStart(topic.isEmpty ? 'General Session' : topic);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                    ),
                    child: Text(
                      'Start',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
