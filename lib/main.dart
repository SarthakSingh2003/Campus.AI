import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:kira_college_ai/constant/theme_provider.dart';
import 'package:kira_college_ai/constant/theme.dart';
import 'package:kira_college_ai/screens/chat_screen.dart';
// Removed HomeScreen, route directly to ChatScreen after auth
import 'package:kira_college_ai/screens/profile_screen.dart';
import 'package:kira_college_ai/screens/chat_history_screen.dart';
// Removed onboarding screens
import 'package:kira_college_ai/services/auth_service.dart';
import 'package:kira_college_ai/screens/login_screen.dart';
import 'package:kira_college_ai/screens/signup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Allow app to start even if Firebase isn't configured yet
  }
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AuthService()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appTheme = themeProvider.currentTheme;
    return MaterialApp(
      title: 'KIRA - UIT Prayagraj AI Assistant',
      theme: ThemeData(
        brightness: appTheme.brightness,
        scaffoldBackgroundColor: appTheme.background,
        primaryColor: appTheme.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appTheme.primary,
          brightness: appTheme.brightness,
        ),
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: appTheme.textColor,
              displayColor: appTheme.textColor,
            ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
      routes: {
        '/chatScreen': (context) => const ChatScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/chatHistory': (context) => const ChatHistoryScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}

// SplashScreen removed; app starts at LoginScreen.
