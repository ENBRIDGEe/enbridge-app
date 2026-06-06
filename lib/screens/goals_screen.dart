import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _isLoading = true;
  List<dynamic> _goals = [];
  List<dynamic> _milestones = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final responses = await Future.wait([
        supabase.from('goals').select().eq('user_id', user.id).order('target_date', ascending: true),
        supabase.from('milestones').select().eq('user_id', user.id),
      ]);

      if (mounted) {
        setState(() {
          _goals = responses[0];
          _milestones = responses[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAddGoal() {
      // simplified to match typical Add modal
      showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGoalSheet(onSaved: () => _fetchData()),
    );
  }

  void _openGoalDeets(Map<String, dynamic> goal) {
      final gMilestones = _milestones.where((e) => e['goal_id'] == goal['id']).toList();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => GoalDetailSheet(goal: goal, milestones: gMilestones, onUpdate: () => _fetchData()),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: GestureDetector(
        onTap: _openAddGoal,
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
              Text('Add goal', style: AppTextStyles.cardTitle.copyWith(color: AppColors.textPrimary)),
            ],
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
              Text('Goals', style: AppTextStyles.displayHeading.copyWith(fontSize: 28.sp)),
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
    if (_goals.isEmpty) {
      return Center(child: Text('No goals set. Aim high!', style: AppTextStyles.bodyMedium));
    }
    
    return ListView.builder(
      itemCount: _goals.length,
      padding: EdgeInsets.only(bottom: 100.h),
      itemBuilder: (context, index) {
        final g = _goals[index];
        final gMilestones = _milestones.where((e) => e['goal_id'] == g['id']).toList();
        final completedM = gMilestones.where((e) => e['completed']).length;
        
        final progress = gMilestones.isNotEmpty ? completedM / gMilestones.length : double.parse((g['progress'] ?? 0.0).toString()) / 100;
        final targetDate = g['target_date'] != null ? DateTime.tryParse(g['target_date']) : null;
        final isLate = targetDate != null && targetDate.isBefore(DateTime.now());

        return GestureDetector(
          onTap: () => _openGoalDeets(g),
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
                    Expanded(child: Text(g['title'], style: AppTextStyles.cardTitle)),
                    if (targetDate != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isLate ? Colors.redAccent.withValues(alpha: 0.1) : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(targetDate.toIso8601String().split('T').first, style: AppTextStyles.bodySmall.copyWith(color: isLate ? Colors.redAccent : AppColors.textSecondary, fontSize: 11.sp)),
                      )
                  ],
                ),
                SizedBox(height: 8.h),
                Text(g['description'] ?? 'No description', style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: LinearPercentIndicator(
                        padding: EdgeInsets.zero,
                        lineHeight: 8.h,
                        percent: progress.clamp(0.0, 1.0),
                        backgroundColor: AppColors.bgSurface,
                        progressColor: AppColors.accentGreen,
                        barRadius: Radius.circular(10.r),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text('${(progress * 100).toInt()}%', style: AppTextStyles.numberMedium.copyWith(fontSize: 14.sp)),
                  ],
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
        children: List.generate(3, (_) => Container(
          margin: EdgeInsets.only(bottom: 16.h),
          width: double.infinity,
          height: 140.h,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
        )),
      ),
    );
  }
}

class AddGoalSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const AddGoalSheet({super.key, required this.onSaved});

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;
  DateTime? _tDate;

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await supabase.from('goals').insert({
        'user_id': supabase.auth.currentUser!.id,
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'target_date': _tDate?.toIso8601String(),
        'progress': 0,
      });
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
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Goal', style: AppTextStyles.cardTitle.copyWith(fontSize: 20.sp)),
            SizedBox(height: 24.h),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              decoration: InputDecoration(hintText: 'Goal Title', hintStyle: TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.bgCard, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none)),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _descCtrl,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              maxLines: 3,
              decoration: InputDecoration(hintText: 'Description', hintStyle: TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.bgCard, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none)),
            ),
            SizedBox(height: 16.h),
            if (_saving) const Center(child: CircularProgressIndicator(color: AppColors.accentGreen)) else 
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 50.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r))),
              child: const Text('Save Goal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalDetailSheet extends StatefulWidget {
  final Map<String, dynamic> goal;
  final List<dynamic> milestones;
  final VoidCallback onUpdate;
  const GoalDetailSheet({super.key, required this.goal, required this.milestones, required this.onUpdate});

  @override
  State<GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends State<GoalDetailSheet> {
  final _mTitleCtrl = TextEditingController();
  late List<dynamic> _localM;

  @override
  void initState() {
    super.initState();
    _localM = List.from(widget.milestones);
  }

  Future<void> _addMilestone() async {
    if (_mTitleCtrl.text.isEmpty) return;
    try {
      final res = await supabase.from('milestones').insert({
        'goal_id': widget.goal['id'],
        'user_id': supabase.auth.currentUser!.id,
        'title': _mTitleCtrl.text,
        'completed': false,
      }).select().single();
      
      setState(() { _localM.add(res); _mTitleCtrl.clear(); });
      _recalcProgress();
      widget.onUpdate();
    } catch (_) {}
  }

  Future<void> _toggleM(dynamic m, bool val) async {
    setState(() {
      m['completed'] = val;
    });
    try {
      await supabase.from('milestones').update({'completed': val}).eq('id', m['id']);
      _recalcProgress();
      widget.onUpdate();
    } catch (_) {}
  }

  Future<void> _recalcProgress() async {
     if (_localM.isEmpty) return;
     int comp = _localM.where((e) => e['completed'] == true).length;
     double pct = (comp / _localM.length) * 100;
     await supabase.from('goals').update({'progress': pct}).eq('id', widget.goal['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.goal['title'], style: AppTextStyles.displayHeading.copyWith(fontSize: 24.sp)),
            SizedBox(height: 8.h),
            Text(widget.goal['description'] ?? '', style: AppTextStyles.bodyMedium),
            SizedBox(height: 32.h),

            // Add Milestone
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mTitleCtrl,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    decoration: InputDecoration(hintText: 'Add milestone', hintStyle: TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.bgCard, contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none)),
                  ),
                ),
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: _addMilestone,
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(color: AppColors.accentGreen, borderRadius: BorderRadius.circular(14.r)),
                    child: Icon(Icons.add, color: Colors.black),
                  ),
                )
              ],
            ),
            SizedBox(height: 24.h),
            Text('Milestones', style: AppTextStyles.cardTitle),
            SizedBox(height: 12.h),
            Expanded(
              child: ListView.builder(
                itemCount: _localM.length,
                itemBuilder: (ctx, i) {
                  final m = _localM[i];
                  final isDone = m['completed'] == true;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _toggleM(m, !isDone),
                    leading: Icon(isDone ? Icons.check_circle_rounded : Icons.circle_outlined, color: isDone ? AppColors.accentGreen : AppColors.textSecondary),
                    title: Text(m['title'], style: TextStyle(color: isDone ? AppColors.textSecondary : Colors.white, decoration: isDone ? TextDecoration.lineThrough : null)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}