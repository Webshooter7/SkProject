import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:skproject/auth_sevice/auth_service.dart';
import 'package:skproject/firebase_options.dart';
import 'package:skproject/screens/home_screen.dart';
import 'package:skproject/screens/login_screen.dart';
import 'package:skproject/screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // Primary color scheme - sky blue tones
        primaryColor: Color(0xFF29B6F6), // Light Blue 400
        primaryColorDark: Color(0xFF039BE5), // Light Blue 600
        primaryColorLight: Color(0xFF4FC3F7), // Light Blue 300

        // Secondary color (accent)
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xFF03A9F4), // Light Blue 500
          onSecondary: Colors.white,
          primary: Color(0xFF29B6F6), // Light Blue 400
          onPrimary: Colors.white,
          background: Colors.white,
          onBackground: Color(0xFF424242), // Slightly softer dark gray for text
          surface: Colors.white,
          onSurface: Color(0xFF424242),
        ),

        // Overall background
        scaffoldBackgroundColor: Colors.white,

        // Card theme
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        // AppBar theme
        appBarTheme: AppBarTheme(
          color: Color(0xFF29B6F6), // Light Blue 400
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF29B6F6), // Light Blue 400
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        // Text theme
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Color(0xFF424242)),
          titleSmall: TextStyle(color: Color(0xFF424242)),
          bodyLarge: TextStyle(color: Color(0xFF424242)),
          bodyMedium: TextStyle(color: Color(0xFF424242)),
          bodySmall: TextStyle(color: Color(0xFF757575)),
        ),

        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFBDBDBD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF29B6F6), width: 2), // Light Blue 400
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFBDBDBD)),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // Use FutureBuilder to determine the initial route based on login status
      home: FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          // Show a loading spinner while checking login status
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Route to the appropriate screen based on login status
          final bool isLoggedIn = snapshot.data ?? false;
          // If already logged in, skip welcome/login screens
          return isLoggedIn ? const HomeScreen() : const WelcomeScreen();
        },
      ),
      routes: {
        LoginScreen.id: (context) => const LoginScreen(role: "admin"), // default fallback
      },
    );
  }
}