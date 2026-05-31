import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/providers/aiva_provider.dart';

/// Glassmorphism card showing a single AIVA session.
class AIVASessionCard extends StatelessWidget {
  final AIVASession session;
  final bool isActive;

  const AIVASessionCard({
    super.key,
    required this.session,
    this.isActive = false,
  });

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.aivaBlue.withValues(alpha: 0.08)
                : AppColors.bgCard.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isActive
                  ? AppColors.aivaBlueMid.withValues(alpha: 0.4)
                  : AppColors.border,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.topic,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 15.sp,
                        color: isActive
                            ? AppColors.aivaBlueMid
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isActive)
                    _LiveBadge()
                  else
                    Text(
                      _formatDate(session.startedAt),
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11.sp),
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                session.summary,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 14.h),
              // Stats row
              Row(
                children: [
                  _StatChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${session.messageCount} messages',
                    active: isActive,
                  ),
                  SizedBox(width: 10.w),
                  _StatChip(
                    icon: Icons.timer_outlined,
                    label: _formatDuration(session.duration),
                    active: isActive,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.aivaBlue.withValues(alpha: 0.15 + _ctrl.value * 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.aivaBlueMid.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                color: AppColors.aivaBlueMid.withValues(
                  alpha: 0.6 + _ctrl.value * 0.4,
                ),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 5.w),
            Text(
              'LIVE',
              style: AppTextStyles.labelEyebrow.copyWith(
                fontSize: 9.sp,
                color: AppColors.aivaBlueMid,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _StatChip({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13.sp,
          color: active ? AppColors.aivaBlueMid : AppColors.textTertiary,
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 11.sp,
            color: active ? AppColors.aivaBlueMid : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
