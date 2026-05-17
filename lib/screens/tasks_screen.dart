import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/widgets/shared_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  void _openAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      builder: (_) => const AddTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: GestureDetector(
        onTap: _openAddTask,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('+', style: GoogleFonts.inter(
                  fontSize: 20, color: AppColors.accentGreen, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('Add task', style: AppTextStyles.cardTitle.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const EyebrowLabel('Your tasks'),
              const SizedBox(height: 10),
              Text('Task list.', style: AppTextStyles.displayHeading),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: const [
                    _TaskItem(title: 'Physics chapter 4 review', category: 'Study',
                        priority: 'High', done: false),
                    SizedBox(height: 10),
                    _TaskItem(title: 'Morning workout', category: 'Gym',
                        priority: 'Medium', done: true),
                    SizedBox(height: 10),
                    _TaskItem(title: 'Grocery shopping', category: 'Chores',
                        priority: 'Low', done: false),
                    SizedBox(height: 10),
                    _TaskItem(title: 'Call team lead', category: 'Personal',
                        priority: 'Critical', done: false),
                    SizedBox(height: 10),
                    _TaskItem(title: 'Submit assignment', category: 'Study',
                        priority: 'Critical', done: false),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final String category;
  final String priority;
  final bool done;
  const _TaskItem({
    required this.title,
    required this.category,
    required this.priority,
    required this.done,
  });

  Color get _priorityColor {
    switch (priority) {
      case 'Critical': return AppColors.accentOrange;
      case 'High': return const Color(0xFFFF6B6B);
      case 'Medium': return AppColors.accentGreen;
      default: return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: 16),
      child: Row(
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.accentGreen : Colors.transparent,
              border: Border.all(
                color: done ? AppColors.accentGreen : AppColors.textTertiary,
                width: 1.5,
              ),
            ),
            child: done
                ? const Icon(Icons.check, size: 13, color: AppColors.bgPrimary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.cardTitle.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? AppColors.textTertiary : AppColors.textPrimary,
                    )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Chip(text: category),
                    const SizedBox(width: 6),
                    _Chip(text: priority, color: _priorityColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color? color;
  const _Chip({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color?.withValues(alpha: 0.4) ?? AppColors.border),
      ),
      child: Text(text,
          style: AppTextStyles.tagLabel.copyWith(
              color: color ?? AppColors.textSecondary, fontSize: 11)),
    );
  }
}

// ─── Add Task Sheet ───────────────────────────────────────────────────────────
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  int _selectedCat = 0;
  int _selectedPriority = 1;

  static const _categories = ['Study', 'Personal', 'Chores', 'Health', 'Gym'];
  static const _priorities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New task', style: AppTextStyles.displayHeading),
                      const SizedBox(height: 28),
                      _fieldLabel('Task title'),
                      const SizedBox(height: 8),
                      TextField(
                        style: AppTextStyles.inputText,
                        decoration: AppDecorations.inputDecoration(hint: 'What needs to be done?'),
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel('Description'),
                      const SizedBox(height: 8),
                      TextField(
                        style: AppTextStyles.inputText,
                        maxLines: 3,
                        decoration: AppDecorations.inputDecoration(
                            hint: 'Add more details...'),
                      ),
                      const SizedBox(height: 20),
                      _fieldLabel('Category'),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_categories.length, (i) {
                            final sel = _selectedCat == i;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCat = i),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                decoration: BoxDecoration(
                                  color: AppColors.bgElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel ? AppColors.accentGreen : AppColors.border,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(_categories[i],
                                    style: AppTextStyles.tagLabel.copyWith(
                                        color: sel ? AppColors.accentGreen : AppColors.textSecondary)),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _fieldLabel('Priority'),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(_priorities.length, (i) {
                          final sel = _selectedPriority == i;
                          final isC = _priorities[i] == 'Critical';
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedPriority = i),
                              child: Container(
                                margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.bgElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel
                                        ? (isC ? AppColors.accentOrange : AppColors.accentGreen)
                                        : AppColors.border,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(_priorities[i],
                                      style: AppTextStyles.tagLabel.copyWith(
                                          color: sel
                                              ? (isC ? AppColors.accentOrange : AppColors.accentGreen)
                                              : AppColors.textSecondary)),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      // Date row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: AppDecorations.card(radius: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: AppColors.textTertiary, size: 18),
                            const SizedBox(width: 12),
                            Text('Select date', style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Reminder toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: AppDecorations.card(radius: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Set reminder', style: AppTextStyles.cardTitle),
                            Switch(
                              value: true,
                              onChanged: (_) {},
                              activeThumbColor: AppColors.accentGreen,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'Add task',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500));
}
