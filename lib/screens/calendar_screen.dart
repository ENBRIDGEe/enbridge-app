import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/models/event_model.dart';
import 'package:enbridge/core/providers/calendar_provider.dart';
import 'package:enbridge/widgets/event_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarProvider);
    final eventMap = ref.watch(eventMapProvider);
    final selectedEvents = ref.watch(eventsForDayProvider(_selectedDay));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCHEDULE',
                          style: AppTextStyles.labelEyebrow.copyWith(
                            fontSize: 10.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Calendar',
                          style: AppTextStyles.displaySmall.copyWith(
                            fontSize: 22.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAddEventSheet(context),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppColors.accentGreen,
                    iconSize: 26.sp,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // ── Calendar widget ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  decoration: AppDecorations.card(radius: 20),
                  child: TableCalendar<EventModel>(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                    calendarFormat: _calendarFormat,
                    eventLoader: (day) {
                      final key = DateTime(day.year, day.month, day.day);
                      return eventMap[key] ?? [];
                    },
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      defaultTextStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 13.sp,
                      ),
                      weekendTextStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13.sp,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.aivaBlue,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.aivaBlueMid,
                        shape: BoxShape.circle,
                      ),
                      markerSize: 5,
                      markerMargin: EdgeInsets.symmetric(horizontal: 1.w),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      titleTextStyle: AppTextStyles.cardTitle.copyWith(
                        fontSize: 14.sp,
                      ),
                      formatButtonDecoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderMid),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      formatButtonTextStyle: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11.sp,
                      ),
                      leftChevronIcon: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.textSecondary,
                      ),
                      rightChevronIcon: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: AppTextStyles.labelEyebrow.copyWith(
                        fontSize: 10.sp,
                        letterSpacing: 0,
                      ),
                      weekendStyle: AppTextStyles.labelEyebrow.copyWith(
                        fontSize: 10.sp,
                        letterSpacing: 0,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // ── Events for selected day ────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Text(
                    _dayLabel(_selectedDay),
                    style: AppTextStyles.labelEyebrow.copyWith(fontSize: 10.sp),
                  ),
                  const Spacer(),
                  if (selectedEvents.isNotEmpty)
                    Text(
                      '${selectedEvents.length} event${selectedEvents.length > 1 ? 's' : ''}',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11.sp),
                    ),
                ],
              ),
            ),

            SizedBox(height: 10.h),

            Expanded(
              child: eventsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.aivaBlue),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Could not load events',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                data: (_) {
                  if (selectedEvents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_note_outlined,
                            size: 40.sp,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'No events for this day',
                            style: AppTextStyles.bodySmall,
                          ),
                          SizedBox(height: 8.h),
                          TextButton.icon(
                            onPressed: () => _showAddEventSheet(context),
                            icon: const Icon(
                              Icons.add,
                              color: AppColors.accentGreen,
                            ),
                            label: Text(
                              'Add event',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      return EventCard(
                        event: event,
                        onDelete: () => ref
                            .read(calendarProvider.notifier)
                            .deleteEvent(event.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventSheet(context),
        backgroundColor: AppColors.aivaBlue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    if (isSameDay(day, now)) return 'TODAY';
    if (isSameDay(day, now.add(const Duration(days: 1)))) return 'TOMORROW';
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return '${days[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}';
  }

  void _showAddEventSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEventSheet(
        initialDate: _selectedDay,
        onAdd: (event) {
          ref.read(calendarProvider.notifier).addEvent(event);
        },
      ),
    );
  }
}

// ── Add Event Bottom Sheet ─────────────────────────────────────────────────────

class _AddEventSheet extends StatefulWidget {
  final DateTime initialDate;
  final void Function(EventModel) onAdd;

  const _AddEventSheet({required this.initialDate, required this.onAdd});

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late DateTime _date;
  TimeOfDay _time = TimeOfDay.now();
  bool _hasReminder = false;
  TimeOfDay _reminderTime = TimeOfDay.now();
  EventType _type = EventType.general;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24.w,
            16.h,
            24.w,
            MediaQuery.of(context).viewInsets.bottom + 32.h,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgSurface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            border: const Border(top: BorderSide(color: AppColors.borderMid)),
          ),
          child: SingleChildScrollView(
            child: Column(
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
                Text(
                  'New Event',
                  style: AppTextStyles.displaySmall.copyWith(fontSize: 20.sp),
                ),
                SizedBox(height: 20.h),

                // Title
                TextField(
                  controller: _titleCtrl,
                  style: AppTextStyles.inputText,
                  decoration: AppDecorations.inputDecoration(
                    hint: 'Event title',
                  ),
                ),
                SizedBox(height: 12.h),

                // Description
                TextField(
                  controller: _descCtrl,
                  style: AppTextStyles.inputText,
                  maxLines: 2,
                  decoration: AppDecorations.inputDecoration(
                    hint: 'Description (optional)',
                  ),
                ),
                SizedBox(height: 16.h),

                // Date + Time row
                Row(
                  children: [
                    Expanded(
                      child: _PickerTile(
                        icon: Icons.calendar_today_outlined,
                        label: _formatDate(_date),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                            builder: (ctx, child) => _darkPicker(ctx, child),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _PickerTile(
                        icon: Icons.access_time_rounded,
                        label: _time.format(context),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _time,
                            builder: (ctx, child) => _darkPicker(ctx, child),
                          );
                          if (picked != null) setState(() => _time = picked);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Event type
                Text(
                  'Type',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: EventType.values.map((t) {
                    final sel = _type == t;
                    return GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.aivaBlue.withValues(alpha: 0.2)
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: sel
                                ? AppColors.aivaBlueMid
                                : AppColors.border,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          t.label,
                          style: AppTextStyles.tagLabel.copyWith(
                            color: sel
                                ? AppColors.aivaBlueMid
                                : AppColors.textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),

                // Reminder toggle
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: AppDecorations.card(radius: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 18.sp,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Set reminder',
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      Switch(
                        value: _hasReminder,
                        onChanged: (v) => setState(() => _hasReminder = v),
                        activeThumbColor: AppColors.accentGreen,
                        trackColor: WidgetStateProperty.all(
                          AppColors.accentGreen.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_hasReminder) ...[
                  SizedBox(height: 10.h),
                  _PickerTile(
                    icon: Icons.alarm_rounded,
                    label: 'Reminder at ${_reminderTime.format(context)}',
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                        builder: (ctx, child) => _darkPicker(ctx, child),
                      );
                      if (picked != null) {
                        setState(() => _reminderTime = picked);
                      }
                    },
                  ),
                ],

                SizedBox(height: 24.h),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.aivaGradStart,
                          AppColors.aivaGradEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                      ),
                      child: Text(
                        'Save Event',
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
      ),
    );
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final eventDt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    DateTime? reminderDt;
    if (_hasReminder) {
      reminderDt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _reminderTime.hour,
        _reminderTime.minute,
      );
    }

    final event = EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      date: eventDt,
      reminderAt: reminderDt,
      hasReminder: _hasReminder,
      type: _type,
      userId: null, // filled by notifier
    );

    widget.onAdd(event);
    Navigator.pop(context);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _darkPicker(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.aivaBlue,
          onPrimary: Colors.white,
          surface: Color(0xFF1A1A1A),
          onSurface: Colors.white,
        ),
      ),
      child: child!,
    );
  }
}

// ── Small picker tile ─────────────────────────────────────────────────────────

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: AppDecorations.card(radius: 14),
        child: Row(
          children: [
            Icon(icon, size: 16.sp, color: AppColors.aivaBlueMid),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
