import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/screens/splash_screen.dart';
import 'package:enbridge/screens/onboarding_screen.dart';
import 'package:enbridge/screens/login_screen.dart';
import 'package:enbridge/screens/register_screen.dart';
import 'package:enbridge/screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF111111),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const EnbridgeApp());
}

class EnbridgeApp extends StatelessWidget {
  const EnbridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enbridge',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const _AppRoot(),
    );
  }
}

enum _AppRoute { splash, onboarding, login, register, main }

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  _AppRoute _route = _AppRoute.splash;

  void _go(_AppRoute next) => setState(() => _route = next);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: _buildRoute(),
    );
  }

  Widget _buildRoute() {
    switch (_route) {
      case _AppRoute.splash:
        return SplashScreen(
          key: const ValueKey('splash'),
          onComplete: () => _go(_AppRoute.onboarding),
        );
      case _AppRoute.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          onComplete: () => _go(_AppRoute.login),
        );
      case _AppRoute.login:
        return LoginScreen(
          key: const ValueKey('login'),
          onLogin: () => _go(_AppRoute.main),
          onRegister: () => _go(_AppRoute.register),
          onBack: () => _go(_AppRoute.onboarding),
        );
      case _AppRoute.register:
        return RegisterScreen(
          key: const ValueKey('register'),
          onRegister: () => _go(_AppRoute.main),
          onLogin: () => _go(_AppRoute.login),
          onBack: () => _go(_AppRoute.login),
        );
      case _AppRoute.main:
        return const MainShell(key: ValueKey('main'));
    }
  }
}
