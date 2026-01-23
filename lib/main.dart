import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wod_timer/core/presentation/theme/app_theme.dart';
import 'package:wod_timer/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const ProviderScope(child: WodTimerApp()));
}

class WodTimerApp extends StatelessWidget {
  const WodTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WOD Timer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const Scaffold(
        body: Center(
          child: Text('WOD Timer - Coming Soon'),
        ),
      ),
    );
  }
}
