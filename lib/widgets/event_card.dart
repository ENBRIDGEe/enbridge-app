import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/models/event_model.dart';

/// Card displaying a single calendar event.
class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onDelete;

  const EventCard({super.key, required this.event, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: AppColors.accentRed, size: 22.sp),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: AppDecorations.card(radius: 16),
        child: Row(
          children: [
            // Type indicator dot
            Container(
              width: 4.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: _typeColor(event.type),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTextStyles.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      event.description!,
                      style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11.sp, color: AppColors.textTertiary),
                      SizedBox(width: 4.w),
                      Text(
                        _formatTime(event.date),
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11.sp),
                      ),
                      if (event.hasReminder) ...[
                        SizedBox(width: 10.w),
                        Icon(Icons.notifications_active_outlined,
                            size: 11.sp, color: AppColors.accentGreen),
                        SizedBox(width: 3.w),
                        Text(
                          'Reminder set',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11.sp,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // Type badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _typeColor(event.type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                event.type.label,
                style: AppTextStyles.tagLabel.copyWith(
                  fontSize: 10.sp,
                  color: _typeColor(event.type),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  Color _typeColor(EventType type) {
    switch (type) {
      case EventType.task:     return AppColors.accentGreen;
      case EventType.habit:    return AppColors.accentOrange;
      case EventType.focus:    return AppColors.aivaBlueMid;
      case EventType.reminder: return const Color(0xFFA78BFA);
      case EventType.general:  return AppColors.textSecondary;
    }
  }
}
