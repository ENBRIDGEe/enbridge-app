import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with WidgetsBindingObserver {
  int _totalSeconds = 25 * 60;
  int _remaining = 25 * 60;
  bool _running = false;
  Timer? _timer;
  
  late ConfettiController _confettiController;
  
  int _todayTotalMinutes = 0;
  int _sessionsCount = 0;
  int _longestSession = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _fetchStats();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final sessions = await supabase.from('focus_sessions').select().eq('user_id', user.id).eq('date', todayStr);
      
      int total = 0;
      int longest = 0;
      for (var s in sessions) {
        int m = (s['session_duration_minutes'] as int?) ?? 0;
        total += m;
        if (m > longest) longest = m;
      }
      
      if (mounted) {
        setState(() {
          _todayTotalMinutes = total;
          _sessionsCount = sessions.length;
          _longestSession = longest;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_running && _remaining > 0) {
        setState(() => _remaining--);
      } else if (_remaining == 0) {
        _timer?.cancel();
        _running = false;
        _completeSession();
      }
    });
  }
  
  Future<void> _completeSession() async {
    _confettiController.play();
    final mins = _totalSeconds ~/ 60;
    try {
      await supabase.from('focus_sessions').insert({
        'user_id': supabase.auth.currentUser!.id,
        'session_duration_minutes': mins,
        'completed_at': DateTime.now().toIso8601String(),
        'date': DateTime.now().toIso8601String().split('T').first,
      });
      _fetchStats();
      if (mounted) {
        _showCompletionDialog(mins);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save session')));
    }
  }
  
  void _showCompletionDialog(int mins) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text('Session complete!', style: AppTextStyles.cardTitle),
      content: Text('+$mins min added to your focus time today.', style: AppTextStyles.bodyMedium),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              _remaining = _totalSeconds;
            });
          },
          child: Text('Done', style: TextStyle(color: AppColors.accentGreen)),
        )
      ],
    ));
  }

  void _openSessionSettings() {
    int focusMins = _totalSeconds ~/ 60;
    int breakMins = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 40.h),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  SizedBox(height: 24.h),
                  Text(
                    'Session settings',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Focus duration
                  Text('Focus duration', style: AppTextStyles.bodySmall),
                  SizedBox(height: 12.h),
                  _durationRow(
                    value: focusMins,
                    min: 5,
                    max: 120,
                    step: 5,
                    onDecrement: () => setSheetState(() {
                      if (focusMins > 5) focusMins -= 5;
                    }),
                    onIncrement: () => setSheetState(() {
                      if (focusMins < 120) focusMins += 5;
                    }),
                  ),
                  SizedBox(height: 24.h),

                  // Break duration
                  Text('Break duration', style: AppTextStyles.bodySmall),
                  SizedBox(height: 12.h),
                  _durationRow(
                    value: breakMins,
                    min: 5,
                    max: 30,
                    step: 5,
                    onDecrement: () => setSheetState(() {
                      if (breakMins > 5) breakMins -= 5;
                    }),
                    onIncrement: () => setSheetState(() {
                      if (breakMins < 30) breakMins += 5;
                    }),
                  ),
                  SizedBox(height: 36.h),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _totalSeconds = focusMins * 60;
                        _remaining = focusMins * 60;
                        _running = false;
                        _timer?.cancel();
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: Size(double.infinity, 56.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
                    ),
                    child: Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _durationRow({
    required int value,
    required int min,
    required int max,
    required int step,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleBtn(Icons.remove_rounded, onDecrement),
          Text(
            '$value min',
            style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          _circleBtn(Icons.add_rounded, onIncrement),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20.sp),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  String get _timeString {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => _remaining / _totalSeconds;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 32.h),
                  Text('Focus session', style: AppTextStyles.bodySmall.copyWith(letterSpacing: 1.5)),
                  SizedBox(height: 48.h),

                  // Circular timer
                  CircularPercentIndicator(
                    radius: 140.r,
                    lineWidth: 10.w,
                    percent: _progress.clamp(0.0, 1.0),
                    center: Text(_timeString, style: AppTextStyles.displayHeading.copyWith(fontSize: 56.sp)),
                    progressColor: AppColors.accentGreen,
                    backgroundColor: AppColors.bgElevated,
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: false,
                  ),
                  SizedBox(height: 48.h),

                  // Quote
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      '"Focus is the art of knowing what to ignore."',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 48.h),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionBtn(
                        icon: Icons.refresh_rounded,
                        onTap: () {
                          setState(() {
                            _running = false;
                            _remaining = _totalSeconds;
                          });
                          _timer?.cancel();
                        },
                      ),
                      SizedBox(width: 24.w),
                      GestureDetector(
                        onTap: () {
                          if (_running) {
                            setState(() => _running = false);
                            _timer?.cancel();
                          } else {
                            setState(() {});
                            _startTimer();
                          }
                        },
                        child: Container(
                          width: 72.w, height: 72.w,
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 36.sp),
                        ),
                      ),
                      SizedBox(width: 24.w),
                      _actionBtn(
                        icon: Icons.settings_rounded,
                        onTap: _openSessionSettings,
                      ),
                    ],
                  ),
                  SizedBox(height: 64.h),

                  // Stats row
                  if (!_isLoading)
                    Row(
                      children: [
                        Expanded(child: _statCard(
                          label: 'Focus today',
                          value: _todayTotalMinutes == 0
                              ? '0m'
                              : _todayTotalMinutes < 60
                                  ? '${_todayTotalMinutes}m'
                                  : '${_todayTotalMinutes ~/ 60}h ${_todayTotalMinutes % 60}m',
                        )),
                        SizedBox(width: 12.w),
                        Expanded(child: _statCard(label: 'Sessions', value: '$_sessionsCount')),
                        SizedBox(width: 12.w),
                        Expanded(child: _statCard(
                          label: 'Longest',
                          value: _longestSession == 0 ? '0m' : '${_longestSession}m',
                        )),
                      ],
                    ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [AppColors.accentGreen, Colors.white, Colors.greenAccent],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.w, height: 56.w,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 24.sp),
      ),
    );
  }

  Widget _statCard({required String label, required String value}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.numberMedium.copyWith(fontSize: 20.sp)),
          SizedBox(height: 4.h),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11.sp)),
        ],
      ),
    );
  }
}

