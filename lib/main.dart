import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'db.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const WeyBirreApp());
}

class WeyBirreApp extends StatefulWidget {
  const WeyBirreApp({super.key});

  @override
  State<WeyBirreApp> createState() => _WeyBirreAppState();
}

class _WeyBirreAppState extends State<WeyBirreApp> {
  bool _loading = true;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final completed = await Db.getSetting('onboarding_completed');

    _hasCompletedOnboarding = completed == 'true';

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wey Birre',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: _loading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _hasCompletedOnboarding
              ? const MainShell()
              : OnboardingScreen(
                  onComplete: () {
                    setState(() => _hasCompletedOnboarding = true);
                  },
                ),
    );
  }
}
