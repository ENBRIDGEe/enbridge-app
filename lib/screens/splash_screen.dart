import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final String _text = "ENBRIDGE";
  bool _startLetters = false;
  bool _startPulse = false;
  bool _fadeToBlack = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    // Wait start
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _startLetters = true);
    
    // letters stagger
    await Future.delayed(Duration(milliseconds: 80 * _text.length));
    // hold
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (!mounted) return;
    setState(() => _startPulse = true);
    _ctrl.forward().then((_) => _ctrl.reverse());
    
    // wait for pulse 600ms
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (!mounted) return;
    setState(() => _fadeToBlack = true);
    // wait fade out 400ms
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardComplete = prefs.getBool('onboarding_complete') ?? false;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      context.go('/dashboard');
    } else {
      if (onboardComplete) {
         context.go('/login');
      } else {
         widget.onComplete();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final pulseOpacity = 1.0 - (_ctrl.value * 0.3); // 1.0 -> 0.7 -> 1.0
                return Opacity(
                  opacity: _startPulse ? pulseOpacity : 1.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_text.length, (index) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: _startLetters ? 1.0 : 0.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        builder: (context, val, child) {
                          // wait for my stagger
                          final effectiveVal = _startLetters ? ((val * 10 - index).clamp(0.0, 1.0).toDouble()) : 0.0;
                          return Opacity(
                            opacity: effectiveVal,
                            child: Transform.scale(
                              scale: 0.5 + (0.5 * effectiveVal),
                              child: Text(
                                _text[index],
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 48.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                );
              },
            ),
          ),
          AnimatedOpacity(
            opacity: _fadeToBlack ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: Container(color: const Color(0xFF0A0A0A)),
          ),
        ],
      ),
    );
  }
}
