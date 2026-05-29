import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Providers imports
import 'providers/theme_state.dart';

// Screen imports
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    // Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_BYTES_UNLIMITED,
    );
  } catch (e) {
    debugPrint("Firebase init failed, running in offline fallback mode: $e");
  }
  
  // Running application wrapped with Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: SriSivaGayathriApp(),
    ),
  );
}

class SriSivaGayathriApp extends ConsumerWidget {
  const SriSivaGayathriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeStateProvider);

    return MaterialApp(
      title: 'Sri Siva Gayathri Enterprizes',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Premium Dark Theme Setup
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyan,
          secondary: Colors.cyanAccent,
          background: Color(0xFF0F172A),
          surface: Color(0xFF1E293B),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.cyanAccent),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ),

      // Premium Light Theme Setup
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.cyan,
          background: Color(0xFFF8FAFC),
          surface: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withOpacity(0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent),
          ),
          labelStyle: const TextStyle(color: Colors.black80),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
