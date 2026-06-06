import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Today', 'This Week', 'Completed'];
  
  bool _isLoading = true;
  List<dynamic> _tasks = [];
  List<dynamic> _goals = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      var query = supabase.from('tasks').select().eq('user_id', user.id);
      
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();
      final todayEnd = DateTime(today.year, today.month, today.day, 23, 59).toIso8601String();
      final weekEnd = today.add(const Duration(days: 7)).toIso8601String();

      if (_selectedFilter == 1) {
        query = query.gte('due_date', todayStart).lte('due_date', todayEnd);
      } else if (_selectedFilter == 2) {
        query = query.gte('due_date', todayStart).lte('due_date', weekEnd);
      } else if (_selectedFilter == 3) {
        query = query.eq('completed', true);
      } else {
        query = query.eq('completed', false);
      }

      final responses = await Future.wait([
        query.order('due_date', ascending: true),
        supabase.from('goals').select().eq('user_id', user.id)
      ]);

      if (mounted) {
        setState(() {
          _tasks = responses[0];
          _goals = responses[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(goals: _goals, onSaved: () => _fetchData()),
    );
  }

  Future<void> _deleteTask(String id) async {
    final taskIndex = _tasks.indexWhere((t) => t['id'] == id);
    final task = _tasks[taskIndex];
    
    setState(() => _tasks.removeAt(taskIndex));
    
    try {
      await supabase.from('tasks').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Task deleted'),
          action: SnackBarAction(label: 'Undo', onPressed: () async {
            await supabase.from('tasks').insert({
              'id': task['id'],
              'user_id': task['user_id'],
              'title': task['title'],
              'description': task['description'],
              'due_date': task['due_date'],
              'category': task['category'],
              'priority': task['priority'],
              'completed': task['completed'],
              'reminder': task['reminder'],
            });
            _fetchData();
          }),
        ));
      }
    } catch (_) {
      _fetchData();
    }
  }

  Future<void> _completeTask(String id, bool val) async {
    setState(() {
      final t = _tasks.firstWhere((e) => e['id'] == id);
      t['completed'] = !val;
    });
    try {
      await supabase.from('tasks').update({
        'completed': !val,
        'completed_at': !val ? DateTime.now().toIso8601String() : null,
      }).eq('id', id);
      _fetchData();
    } catch (_) {
      _fetchData();
    }
  }

  Color _priorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'critical': return const Color(0xFFF97316);
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.amber;
      case 'low': return AppColors.accentGreen;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80.h),
        child: GestureDetector(
          onTap: _openAddTask,
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
              Text('Add task', style: AppTextStyles.cardTitle.copyWith(color: AppColors.textPrimary)),
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
              Text('Tasks', style: AppTextStyles.displayHeading.copyWith(fontSize: 28.sp)),
              SizedBox(height: 20.h),
              
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_filters.length, (i) {
                    final isSel = _selectedFilter == i;
                    return GestureDetector(
                      onTap: () {
                        setState(() { _selectedFilter = i; _isLoading = true; });
                        _fetchData();
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 12.w),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.accentGreen : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: isSel ? AppColors.accentGreen : AppColors.border),
                        ),
                        child: Text(_filters[i], style: AppTextStyles.bodySmall.copyWith(
                          color: isSel ? Colors.black : AppColors.textPrimary,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                        )),
                      ),
                    );
                  }),
                ),
              ),
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
    if (_tasks.isEmpty) {
      return Center(child: Text('No tasks found.', style: AppTextStyles.bodyMedium));
    }
    
    return ListView.builder(
      itemCount: _tasks.length,
      padding: EdgeInsets.only(bottom: 100.h),
      itemBuilder: (context, index) {
        final t = _tasks[index];
        final id = t['id'];
        final isDone = t['completed'] == true;
        final priority = t['priority'] as String?;
        final category = t['category'] as String?;
        final description = (t['description'] as String?)?.trim();
        return Dismissible(
          key: Key(id.toString()),
          background: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: AppColors.accentGreen,
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.centerLeft,
            child: Icon(Icons.check_rounded, color: Colors.black, size: 28.sp),
          ),
          secondaryBackground: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.centerRight,
            child: Icon(Icons.delete_rounded, color: Colors.black, size: 28.sp),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              _completeTask(id, isDone);
              return false;
            } else {
              _deleteTask(id);
              return true;
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _completeTask(id, isDone),
                  child: Icon(
                    isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: isDone ? AppColors.accentGreen : AppColors.textSecondary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['title'],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDone
                                ? AppColors.textTertiary
                                : AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (category != null || priority != null) ...[
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            if (category != null)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppColors.bgCard,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(category, style: AppTextStyles.bodySmall.copyWith(fontSize: 11.sp)),
                              ),
                            if (category != null && priority != null) SizedBox(width: 6.w),
                            if (priority != null)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: _priorityColor(priority).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(color: _priorityColor(priority).withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  priority.toUpperCase(),
                                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10.sp, color: _priorityColor(priority), fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (t['due_date'] != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          DateTime.parse(t['due_date']).toIso8601String().split('T').first,
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp),
                        ),
                      ],
                    ],
                  ),
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
        children: List.generate(5, (_) => Container(
          margin: EdgeInsets.only(bottom: 12.h),
          width: double.infinity,
          height: 72.h,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14.r)),
        )),
      ),
    );
  }
}

class AddTaskSheet extends StatefulWidget {
  final List<dynamic> goals;
  final VoidCallback onSaved;
  const AddTaskSheet({super.key, required this.goals, required this.onSaved});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;
  String? _selectedCategory;
  String _selectedPriority = 'medium';
  bool _reminderEnabled = false;
  bool _saving = false;

  final List<String> _categories = ['Study', 'Personal', 'Chores', 'Health', 'Gym', 'Others'];
  final List<Map<String, dynamic>> _priorities = [
    {'label': 'Low', 'value': 'low'},
    {'label': 'Medium', 'value': 'medium'},
    {'label': 'High', 'value': 'high'},
    {'label': 'Critical', 'value': 'critical'},
  ];

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await supabase.from('tasks').insert({
        'user_id': supabase.auth.currentUser!.id,
        'title': _titleCtrl.text,
        'description': _descCtrl.text.isEmpty ? null : _descCtrl.text,
        'due_date': _dueDate?.toIso8601String(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'completed': false,
        'reminder': _reminderEnabled,
      });
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
            decoration: BoxDecoration(
              color: AppColors.bgSurface.withValues(alpha: 0.6),
              border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 1)),
            ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Heading
              Text(
                'New task',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 24.h),

              // Title input
              TextField(
                controller: _titleCtrl,
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),
              SizedBox(height: 12.h),

              // Description input
              TextField(
                controller: _descCtrl,
                style: TextStyle(color: Colors.white, fontSize: 15.sp),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add more details...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),
              SizedBox(height: 20.h),

              // Category chips
              Text('Category', style: AppTextStyles.bodySmall),
              SizedBox(height: 10.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = isSelected ? null : cat),
                      child: Container(
                        margin: EdgeInsets.only(right: 8.w),
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSelected ? AppColors.accentGreen : const Color(0xFF333330),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected ? AppColors.accentGreen : const Color(0xFF888880),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20.h),

              // Priority chips
              Text('Priority', style: AppTextStyles.bodySmall),
              SizedBox(height: 10.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _priorities.map((p) {
                    final isSelected = _selectedPriority == p['value'];
                    final isCritical = p['value'] == 'critical';
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPriority = p['value']),
                      child: Container(
                        margin: EdgeInsets.only(right: 8.w),
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSelected
                                ? (isCritical ? const Color(0xFFF97316) : AppColors.accentGreen)
                                : const Color(0xFF333330),
                          ),
                        ),
                        child: Text(
                          p['label'],
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? (isCritical ? const Color(0xFFF97316) : AppColors.accentGreen)
                                : const Color(0xFF888880),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20.h),

              // Date picker row
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
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
                  if (d != null) setState(() => _dueDate = d);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 18.sp),
                      SizedBox(width: 12.w),
                      Text(
                        _dueDate == null ? 'Select date' : _dueDate!.toIso8601String().split('T').first,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _dueDate == null ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Reminder toggle
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Set reminder', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
                    Switch(
                      value: _reminderEnabled,
                      activeThumbColor: AppColors.accentGreen,
                      onChanged: (val) => setState(() => _reminderEnabled = val),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Save button
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
                ),
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : Text('Add task', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    ),
    ),
    );
  }
}
