import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/database.dart';
import 'providers/habit_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HabitProvider(database: database),
        ),
      ],
      child: const WillTrackApp(),
    ),
  );
}

class WillTrackApp extends StatelessWidget {
  const WillTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<HabitProvider, ThemeMode>(
      (p) => p.themeMode,
    );

    return MaterialApp(
      title: 'WillTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
