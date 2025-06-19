import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_chatbot_assistant/constant/theme_provider.dart';
import 'package:voice_chatbot_assistant/constant/theme.dart';
import 'package:voice_chatbot_assistant/screens/chat_screen.dart';
import 'package:voice_chatbot_assistant/screens/home_screen.dart';
import 'package:voice_chatbot_assistant/screens/profile_screen.dart';
import 'package:voice_chatbot_assistant/screens/chat_history_screen.dart';
import 'package:voice_chatbot_assistant/screens/onboarding_ask_screen.dart';
import 'package:voice_chatbot_assistant/screens/onboarding_learn_screen.dart';
import 'package:voice_chatbot_assistant/screens/onboarding_connect_screen.dart';
import 'package:voice_chatbot_assistant/services/onboarding_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appTheme = themeProvider.currentTheme;
    return MaterialApp(
      title: 'KYC - Know Your College',
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
      home: const SplashScreen(),
      routes: {
        '/onboardingAsk': (context) => const OnboardingAskScreen(),
        '/onboardingLearn': (context) => const OnboardingLearnScreen(),
        '/onboardingConnect': (context) => const OnboardingConnectScreen(),
        '/homeScreen': (context) => const HomeScreen(),
        '/chatScreen': (context) => const ChatScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/chatHistory': (context) => const ChatHistoryScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // Add a small delay for splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Always show onboarding screens
      final isCompleted = await OnboardingService.forceShowOnboarding();

      if (isCompleted) {
        Navigator.pushReplacementNamed(context, '/homeScreen');
      } else {
        Navigator.pushReplacementNamed(context, '/onboardingAsk');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4F46E5),
              Color(0xFF7C3AED),
              Color(0xFFEC4899),
              Color(0xFFF59E0B),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/botImage.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              const Text(
                'KYC',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 10,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Know Your College',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
