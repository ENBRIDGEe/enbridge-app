import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  List<dynamic> _tasks = [];
  List<dynamic> _goals = [];
  List<dynamic> _habits = [];
  Map<String, dynamic>? _profile;
  int _focusMinutes = 0;
  int _habitsDoneToday = 0;

  static const List<String> quotes = [
    "Doubt kills more dreams than failure ever will.",
    "Focus on being productive instead of busy.",
    "Don't wait. The time will never be just right.",
    "Small disciplines repeated with consistency every day lead to great achievements.",
    "What you do today can improve all your tomorrows.",
    "The secret of getting ahead is getting started.",
    "You don't have to be great to start, but you have to start to be great.",
    "Discipline is choosing between what you want now and what you want most.",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Refresh whenever the app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final userId = user.id;
      final todayStr = DateTime.now().toIso8601String().split('T').first;

      final responses = await Future.wait([
        // All incomplete tasks + tasks completed today — no date filter so all show
        supabase
            .from('tasks')
            .select()
            .eq('user_id', userId)
            .or('completed.eq.false,completed_at.gte.$todayStr')
            .order('created_at', ascending: false)
            .limit(20),
        supabase.from('goals').select().eq('user_id', userId).eq('status', 'active').limit(10),
        supabase.from('profiles').select().eq('id', userId).maybeSingle(),
        supabase
            .from('focus_sessions')
            .select('session_duration_minutes')
            .eq('user_id', userId)
            .eq('date', todayStr),
        supabase.from('habits').select().eq('user_id', userId).order('id'),
        supabase
            .from('habit_logs')
            .select()
            .eq('user_id', userId)
            .eq('date', todayStr)
            .eq('completed', true),
      ]);

      if (mounted) {
        setState(() {
          _tasks = responses[0] as List<dynamic>;
          _goals = responses[1] as List<dynamic>;
          _profile = responses[2] as Map<String, dynamic>?;

          final focusSessions = responses[3] as List<dynamic>;
          _focusMinutes = focusSessions.fold<int>(
              0, (prev, e) => prev + ((e['session_duration_minutes'] as int?) ?? 0));

          _habits = responses[4] as List<dynamic>;
          _habitsDoneToday = (responses[5] as List<dynamic>).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTaskCompletion(String taskId, bool currentVal) async {
    try {
      await supabase.from('tasks').update({
        'completed': !currentVal,
        'completed_at': !currentVal ? DateTime.now().toIso8601String() : null,
      }).eq('id', taskId);
      _fetchData();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();

    final completedTasks = _tasks.where((t) => t['completed'] == true).length;
    final totalTasks = _tasks.length;
    final progress = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks);

    final avatarUrl = _profile?['avatar_url'] as String?;
    final name = (_profile?['name'] as String?) ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final quote = quotes[DateTime.now().weekday % quotes.length];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: AppColors.accentGreen,
          backgroundColor: AppColors.bgCard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),

                // ── Top greeting bar ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, $name',
                            style: AppTextStyles.greetingText.copyWith(fontSize: 22.sp),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Let's build your future today.",
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 13.sp),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      width: 48.w,
                      height: 48.w,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: avatarUrl != null
                          ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                initial,
                                style: GoogleFonts.inter(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                SizedBox(height: 28.h),

                // ── Daily Progress card ──
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Daily Progress',
                              style: AppTextStyles.cardTitle.copyWith(fontSize: 17.sp)),
                          Text(
                            '$completedTasks of $totalTasks tasks',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentGreen),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: LinearPercentIndicator(
                          lineHeight: 8.h,
                          percent: progress.clamp(0.0, 1.0),
                          backgroundColor: AppColors.bgElevated,
                          progressColor: AppColors.accentGreen,
                          barRadius: Radius.circular(10.r),
                          padding: EdgeInsets.zero,
                          animation: true,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // ── Stats row ──
                Row(
                  children: [
                    Expanded(child: _buildStatCard(
                      icon: Icons.timer_outlined,
                      label: 'Focus',
                      value: _focusMinutes == 0 ? '0m' : '${_focusMinutes}m',
                      sub: 'today',
                    )),
                    SizedBox(width: 12.w),
                    Expanded(child: _buildStatCard(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Habits',
                      value: '$_habitsDoneToday / ${_habits.length}',
                      sub: 'done today',
                      valueColor: _habitsDoneToday == _habits.length && _habits.isNotEmpty
                          ? AppColors.accentGreen
                          : null,
                    )),
                    SizedBox(width: 12.w),
                    Expanded(child: _buildStatCard(
                      icon: Icons.star_outline_rounded,
                      label: 'Goals',
                      value: '${_goals.length}',
                      sub: 'active',
                    )),
                  ],
                ),
                SizedBox(height: 16.h),

                // ── Quote card ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.format_quote_rounded, color: AppColors.accentGreen, size: 22.sp),
                      SizedBox(height: 8.h),
                      Text(
                        quote,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // ── Today's Tasks ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Tasks",
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 20.sp)),
                    if (_tasks.isNotEmpty)
                      Text('$completedTasks done',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentGreen)),
                  ],
                ),
                SizedBox(height: 16.h),
                if (_tasks.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.accentGreen, size: 20.sp),
                        SizedBox(width: 10.w),
                        Text('All clear! Add tasks from the Tasks tab.',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  )
                else
                  ..._tasks.take(5).map((t) => _buildTaskItem(t)),
                if (_tasks.length > 5)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text('+${_tasks.length - 5} more in Tasks tab',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentGreen)),
                  ),

                SizedBox(height: 32.h),

                // ── Active Habits ──
                Text('Habits Today', style: AppTextStyles.cardTitle.copyWith(fontSize: 20.sp)),
                SizedBox(height: 16.h),
                if (_habits.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Text('No habits yet. Go to the Habits tab to add one.',
                        style: AppTextStyles.bodyMedium),
                  )
                else
                  ..._habits.take(4).map((h) => _buildHabitRow(h)),

                SizedBox(height: 32.h),

                // ── Active Goals ──
                Text('Active Goals', style: AppTextStyles.cardTitle.copyWith(fontSize: 20.sp)),
                SizedBox(height: 16.h),
                if (_goals.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Text('No active goals yet. Dream big and set one up!',
                        style: AppTextStyles.bodyMedium),
                  )
                else
                  SizedBox(
                    height: 140.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _goals.length,
                      clipBehavior: Clip.none,
                      itemBuilder: (context, i) => _buildGoalCard(_goals[i]),
                    ),
                  ),

                SizedBox(height: 80.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    Color? valueColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.textSecondary, size: 14.sp),
            SizedBox(width: 6.w),
            Flexible(child: Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11.sp))),
          ]),
          SizedBox(height: 8.h),
          Text(value,
            style: AppTextStyles.numberMedium.copyWith(
              fontSize: 20.sp,
              color: valueColor ?? AppColors.textPrimary,
            )),
          SizedBox(height: 2.h),
          Text(sub, style: AppTextStyles.bodySmall.copyWith(fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(dynamic t) {
    final isDone = t['completed'] == true;
    final title = (t['title'] as String?) ?? 'Untitled';
    final priority = (t['priority'] as String?) ?? '';
    final priorityColor = priority == 'high' || priority == 'critical'
        ? Colors.redAccent
        : priority == 'medium'
            ? Colors.orangeAccent
            : AppColors.accentGreen;

    return GestureDetector(
      onTap: () => _toggleTaskCompletion(t['id'].toString(), isDone),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDone ? AppColors.border : priorityColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isDone ? AppColors.accentGreen : AppColors.textSecondary,
              size: 22.sp,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
            if (priority.isNotEmpty && !isDone)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor, fontSize: 10.sp, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitRow(dynamic h) {
    final title = (h['title'] as String?) ?? '';
    final streak = (h['streak'] as int?) ?? 0;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: AppColors.accentGreen, size: 20.sp),
          SizedBox(width: 14.w),
          Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
          Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 16.sp),
          SizedBox(width: 4.w),
          Text('$streak', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(dynamic g) {
    final title = (g['title'] as String?) ?? 'Goal';
    final progress = ((g['progress_percentage'] as num?) ?? 0) / 100.0;

    return Container(
      width: 200.w,
      margin: EdgeInsets.only(right: 14.w),
      padding: EdgeInsets.all(18.w),
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
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.flag_rounded, color: AppColors.accentGreen, size: 16.sp),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentGreen),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(title,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 14.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearPercentIndicator(
              lineHeight: 4.h,
              percent: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.bgSurface,
              progressColor: AppColors.accentGreen,
              barRadius: Radius.circular(10.r),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF1A1A1A),
            highlightColor: const Color(0xFF2A2A2A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 160.w, height: 22.h, color: Colors.white),
                        SizedBox(height: 8.h),
                        Container(width: 110.w, height: 14.h, color: Colors.white),
                      ],
                    ),
                    Container(
                      width: 48.w, height: 48.w,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                  ],
                ),
                SizedBox(height: 28.h),
                Container(
                  width: double.infinity, height: 80.h,
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
                ),
                SizedBox(height: 16.h),
                Row(children: List.generate(3, (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 12.w : 0),
                    height: 80.h,
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                  ),
                ))),
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity, height: 70.h,
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
                ),
                SizedBox(height: 32.h),
                Container(width: 130.w, height: 20.h, color: Colors.white),
                SizedBox(height: 16.h),
                ...List.generate(3, (i) => Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  width: double.infinity, height: 52.h,
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14.r)),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}