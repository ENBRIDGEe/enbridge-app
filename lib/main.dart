import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/router/router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF111111),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  await Supabase.initialize(
    url: 'https://utskvawuxkubeehinexf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV0c2t2YXd1eGt1YmVlaGluZXhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyNzgzNTUsImV4cCI6MjA5NDg1NDM1NX0.dogKQJtfJc21hlCsb8HZPKliXUL6beUVHl2bLQ1Tb5s',
  );

  runApp(
    const ProviderScope(
      child: EnbridgeApp(),
    ),
  );
}

class EnbridgeApp extends ConsumerWidget {
  const EnbridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Enbridge',
          debugShowCheckedModeBanner: false,
          theme: appTheme(),
          routerConfig: router,
        );
      },
    );
  }
}


