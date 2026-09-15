import 'dart:io';
import 'package:cer_time/screens/login_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'screens/main_navigation.dart';
import 'screens/onboarding_screen.dart';
import 'services/settings_service.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await SettingsService.instance.init();
  await SessionService.instance.init();

  runApp(const CerTimeApp());
}

class CerTimeApp extends StatefulWidget {
  const CerTimeApp({super.key});

  @override
  State<CerTimeApp> createState() => _CerTimeAppState();
}

class _CerTimeAppState extends State<CerTimeApp> {
  @override
  void initState() {
    super.initState();
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  Widget _resolveHome() {
    if(!SettingsService.instance.onboardingDone) return const OnboardingScreen();
    if(!SessionService.instance.isLoggedIn) return const LoginScreen();
    return const MainNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'CerTime',
        themeMode: SettingsService.instance.themeMode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: _resolveHome(),
    );
  }
}
