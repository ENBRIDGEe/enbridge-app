import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  bool _isLoading = true;
  List<dynamic> _habits = [];
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final weekAgo = DateTime.now()
          .subtract(const Duration(days: 6))
          .toIso8601String()
          .split('T')
          .first;

      final responses = await Future.wait([
        supabase.from('habits').select().eq('user_id', user.id).order('id'),
        supabase.from('habit_logs').select().eq('user_id', user.id).gte('date', weekAgo),
      ]);

      if (mounted) {
        setState(() {
          _habits = responses[0];
          _logs = responses[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleHabit(String habitId, String date, int currentStreak) async {
    final existingParams = _logs.firstWhere(
      (element) => element['habit_id'] == habitId && element['date'] == date,
      orElse: () => <String, dynamic>{},
    );

    if (existingParams.isEmpty) {
      await supabase.from('habit_logs').insert({
        'user_id': supabase.auth.currentUser!.id,
        'habit_id': habitId,
        'date': date,
        'completed': true,
      });
      await supabase.from('habits').update({'streak': currentStreak + 1}).eq('id', habitId);
    } else {
      bool wasCompleted = existingParams['completed'];
      await supabase.from('habit_logs').update({'completed': !wasCompleted}).eq('id', existingParams['id']);
    }
    _fetchData();
  }

  void _openAddHabit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitFormSheet(onSaved: () => _fetchData()),
    );
  }

  void _openEditHabit(Map habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitFormSheet(
        existingHabit: habit,
        onSaved: () => _fetchData(),
      ),
    );
  }

  Future<void> _deleteHabit(Map habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Delete habit', style: AppTextStyles.cardTitle),
        content: Text(
          'Delete "${habit['title']}"? This will permanently remove all logs and streaks.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final id = habit['id'].toString();
        await supabase.from('habit_logs').delete().eq('habit_id', id);
        await supabase.from('habits').delete().eq('id', id);
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Habit deleted'),
              backgroundColor: const Color(0xFF1A1A1A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80.h),
        child: GestureDetector(
          onTap: _openAddHabit,
        child: Container(
          height: 56.h,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(50.r),
            border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('+', style: GoogleFonts.inter(fontSize: 24.sp, color: AppColors.accentGreen, fontWeight: FontWeight.w600)),
              SizedBox(width: 8.w),
              Text('Add habit', style: AppTextStyles.cardTitle.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),
              Text('Habits', style: AppTextStyles.displayHeading.copyWith(fontSize: 28.sp)),
              SizedBox(height: 24.h),
              Expanded(
                child: _isLoading ? _buildSkeleton() : _buildList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_habits.isEmpty) {
      return Center(child: Text('No habits yet. Add your first habit!', style: AppTextStyles.bodyMedium));
    }

    final now = DateTime.now();
    final dates = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)).toIso8601String().split('T').first);

    return ListView.builder(
      itemCount: _habits.length,
      padding: EdgeInsets.only(bottom: 100.h),
      itemBuilder: (context, index) {
        final h = _habits[index];
        final habitId = h['id'].toString();
        final streak = (h['streak'] as int?) ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HabitDetailScreen(habit: h),
              ),
            ).then((_) => _fetchData());
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(h['title'], style: AppTextStyles.cardTitle),
                    ),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 18.sp),
                        SizedBox(width: 4.w),
                        Text('$streak', style: AppTextStyles.numberMedium.copyWith(fontSize: 16.sp)),
                        SizedBox(width: 8.w),
                        // Three-dot menu
                        SizedBox(
                          width: 32.w,
                          height: 32.w,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20.sp),
                            color: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            onSelected: (val) {
                              if (val == 'edit') _openEditHabit(h);
                              if (val == 'delete') _deleteHabit(h);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined, size: 18.sp, color: AppColors.textPrimary),
                                  SizedBox(width: 12.w),
                                  Text('Edit', style: AppTextStyles.bodyMedium),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline_rounded, size: 18.sp, color: Colors.redAccent),
                                  SizedBox(width: 12.w),
                                  Text('Delete', style: AppTextStyles.bodyMedium.copyWith(color: Colors.redAccent)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final date = dates[i];
                    final isToday = i == 6;
                    final log = _logs.firstWhere(
                      (e) => e['habit_id'].toString() == habitId && e['date'] == date,
                      orElse: () => <String, dynamic>{},
                    );
                    final isDone = log.isNotEmpty && log['completed'] == true;

                    return GestureDetector(
                      onTap: isToday ? () => _toggleHabit(habitId, date, streak) : null,
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.accentGreen : AppColors.bgSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isToday ? AppColors.accentGreen : Colors.transparent,
                            width: isToday && !isDone ? 2 : 0,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A1A),
      highlightColor: const Color(0xFF2A2A2A),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: EdgeInsets.only(bottom: 16.h),
            width: double.infinity,
            height: 120.h,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HabitFormSheet — used for both Add and Edit
// ─────────────────────────────────────────────────────────────
class HabitFormSheet extends StatefulWidget {
  final Map? existingHabit;
  final VoidCallback onSaved;
  const HabitFormSheet({super.key, this.existingHabit, required this.onSaved});

  @override
  State<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<HabitFormSheet> {
  late final TextEditingController _titleCtrl;
  bool _saving = false;
  bool get _isEditing => widget.existingHabit != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: _isEditing ? widget.existingHabit!['title'] as String : '');
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await supabase.from('habits').update({'title': _titleCtrl.text}).eq('id', widget.existingHabit!['id']);
      } else {
        await supabase.from('habits').insert({
          'user_id': supabase.auth.currentUser!.id,
          'title': _titleCtrl.text,
          'streak': 0,
        });
      }
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 40.h),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
            SizedBox(height: 20.h),
            Text(
              _isEditing ? 'Edit habit' : 'New habit',
              style: GoogleFonts.playfairDisplay(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'What habit will you build?',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 54.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text(
                      _isEditing ? 'Save changes' : 'Add habit',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HabitDetailScreen — records, streaks, heatmap
// ─────────────────────────────────────────────────────────────
class HabitDetailScreen extends StatefulWidget {
  final Map habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _allLogs = [];

  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalCompletions = 0;
  double _completionRate = 0;

  @override
  void initState() {
    super.initState();
    _currentStreak = (widget.habit['streak'] as int?) ?? 0;
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final habitId = widget.habit['id'].toString();
      // Last 90 days for heatmap
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 89)).toIso8601String().split('T').first;
      final logs = await supabase
          .from('habit_logs')
          .select()
          .eq('habit_id', habitId)
          .gte('date', ninetyDaysAgo)
          .order('date', ascending: true);

      // Calculate stats
      final completed = (logs as List).where((l) => l['completed'] == true).toList();
      _totalCompletions = completed.length;

      // Completion rate over 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 29));
      final last30 = completed.where((l) {
        final d = DateTime.parse(l['date']);
        return d.isAfter(thirtyDaysAgo.subtract(const Duration(days: 1)));
      }).length;
      _completionRate = (last30 / 30) * 100;

      // Longest streak
      _longestStreak = _calcLongestStreak(completed);

      if (mounted) {
        setState(() {
          _allLogs = logs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calcLongestStreak(List completed) {
    if (completed.isEmpty) return 0;
    final dates = completed.map((l) => DateTime.parse(l['date'])).toList()..sort();
    int longest = 1;
    int current = 1;
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return longest;
  }

  bool _isLoggedOnDay(DateTime day) {
    final dayStr = day.toIso8601String().split('T').first;
    return _allLogs.any((l) => l['date'] == dayStr && l['completed'] == true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.habit['title'] as String;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTextStyles.cardTitle),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),

                  // Stats row
                  Row(
                    children: [
                      Expanded(child: _statCard('🔥 Streak', '$_currentStreak days')),
                      SizedBox(width: 12.w),
                      Expanded(child: _statCard('🏆 Best', '$_longestStreak days')),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(child: _statCard('✅ Total', '$_totalCompletions done')),
                      SizedBox(width: 12.w),
                      Expanded(child: _statCard('📊 30-day', '${_completionRate.toStringAsFixed(0)}%')),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // Heatmap title
                  Text('Last 90 days', style: AppTextStyles.cardTitle.copyWith(fontSize: 18.sp)),
                  SizedBox(height: 4.h),
                  Text('Tap any day to see your record', style: AppTextStyles.bodySmall),
                  SizedBox(height: 16.h),

                  // Heatmap grid — 90 days, 13 columns (weeks) × 7 rows
                  _buildHeatmap(),

                  SizedBox(height: 32.h),

                  // Recent activity
                  Text('Recent activity', style: AppTextStyles.cardTitle.copyWith(fontSize: 18.sp)),
                  SizedBox(height: 12.h),
                  _buildRecentList(),

                  SizedBox(height: 60.h),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp)),
          SizedBox(height: 8.h),
          Text(value, style: AppTextStyles.numberMedium.copyWith(fontSize: 20.sp)),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    final today = DateTime.now();
    final startDay = today.subtract(const Duration(days: 89));
    // cell = 13px square + 3px gap; 7 rows × 16 = 112px total height
    const cellSize = 13.0;
    const cellGap = 3.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(13, (week) {
          return Padding(
            padding: const EdgeInsets.only(right: cellGap),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (day) {
                final cellDay = startDay.add(Duration(days: week * 7 + day));
                if (cellDay.isAfter(today)) {
                  return const SizedBox(width: cellSize, height: cellSize + cellGap);
                }
                final filled = _isLoggedOnDay(cellDay);
                final isToday = cellDay.year == today.year &&
                    cellDay.month == today.month &&
                    cellDay.day == today.day;
                return Padding(
                  padding: const EdgeInsets.only(bottom: cellGap),
                  child: Tooltip(
                    message:
                        '${cellDay.toIso8601String().split('T').first}: ${filled ? 'Done ✓' : 'Missed'}',
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: filled
                            ? AppColors.accentGreen
                            : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(2),
                        border: isToday
                            ? Border.all(color: AppColors.accentGreen, width: 1.5)
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRecentList() {
    final completed = _allLogs
        .where((l) => l['completed'] == true)
        .toList()
        .reversed
        .take(10)
        .toList();

    if (completed.isEmpty) {
      return Text('No completions recorded yet.', style: AppTextStyles.bodyMedium);
    }

    return Column(
      children: completed.map((log) {
        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                log['date'] as String,
                style: AppTextStyles.bodyMedium,
              ),
              const Spacer(),
              Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 18.sp),
            ],
          ),
        );
      }).toList(),
    );
  }
}
