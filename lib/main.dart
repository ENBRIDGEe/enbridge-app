import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/router/router.dart';
import 'package:enbridge/core/services/notification_service.dart';
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
  
  // Credentials are loaded via --dart-define at build/run time.
  // See .env.example for required keys. Never hardcode secrets here.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Initialize local notifications
  await NotificationService.instance.initialize();

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


