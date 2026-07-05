import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Wajib ada biar Flutter siap ngejalanin fungsi di luar UI
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://xtlfhvjsozvuighjuumw.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0bGZodmpzb3p2dWlnaGp1dW13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMyNTAxODMsImV4cCI6MjA5ODgyNjE4M30.vX87FM5Aus6jCECRMdHoJSgco5fSisE6KSFSiFmA-J8',
  );

  runApp(
    ChangeNotifierProvider(create: (_) => AppProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, bool>(
      selector: (_, p) => p.isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'E-Ticketing Helpdesk',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          // Halaman pertama yang dibuka
          home: const SplashScreen(),
        );
      },
    );
  }
}
