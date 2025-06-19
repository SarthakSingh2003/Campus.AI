import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_chatbot_assistant/constant/messages.dart'; // Import shared_preferences
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:voice_chatbot_assistant/constant/theme_provider.dart';
import 'package:voice_chatbot_assistant/constant/theme.dart';
import '../components/custom_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _storedName;

  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _botController;
  late AnimationController _buttonController;
  late AnimationController _particleController;
  late AnimationController _glowController;

  late Animation<double> _titleAnimation;
  late Animation<double> _subtitleAnimation;
  late Animation<double> _botAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _botController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Define animations
    _titleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.elasticOut,
    ));

    _subtitleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeInOut,
    ));

    _botAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _botController,
      curve: Curves.bounceOut,
    ));

    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _titleController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _subtitleController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _botController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _buttonController.forward();

    // Start continuous animations
    _particleController.repeat();
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _botController.dispose();
    _buttonController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // Load stored name from SharedPreferences
  void _checkStoredName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedName = prefs.getString('userName');

    if (storedName != null) {
      setState(() {
        _storedName = storedName;
      });
      updateMessage(storedName);
      Navigator.pushReplacementNamed(context, '/chatScreen');
    } else {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appTheme = themeProvider.currentTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: appTheme.gradient,
          ),
        ),
        child: Stack(
          children: [
            if (appTheme.showSpaceElements) ...[
              ...List.generate(5, (index) {
                return AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(screenWidth, screenHeight),
                      painter: WavePainter(
                        animation: _particleAnimation,
                        waveHeight: 30 + (index * 15),
                        waveColor:
                            Colors.white.withOpacity(0.05 - (index * 0.01)),
                        waveSpeed: 1.0 + (index * 0.2),
                      ),
                    );
                  },
                );
              }),
            ],
            if (appTheme.showRainbowElements) ...[
              ...List.generate(5, (index) {
                return AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return Positioned(
                      left: 0,
                      top: screenHeight * 0.2 * index,
                      child: Container(
                        width: screenWidth,
                        height: screenHeight * 0.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.primaries[
                                  (index * 2) % Colors.primaries.length],
                              Colors.primaries[
                                  (index * 2 + 1) % Colors.primaries.length],
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Animated title
                    AnimatedBuilder(
                      animation: _titleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _titleAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - _titleAnimation.value)),
                            child: const Text(
                              'KYC',
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 12,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2, 2),
                                    blurRadius: 15,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // Animated subtitle
                    AnimatedBuilder(
                      animation: _subtitleAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset:
                              Offset(0, 20 * (1 - _subtitleAnimation.value)),
                          child: Opacity(
                            opacity: _subtitleAnimation.value,
                            child: const Text(
                              'Know Your College',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    // Animated KYC text with multiple effects
                    AnimatedBuilder(
                      animation: _botAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _botAnimation.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow effect
                              AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.2 + (_glowAnimation.value * 0.1),
                                    child: Container(
                                      width: screenWidth * 0.8,
                                      height: screenHeight * 0.4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            blurRadius: 50,
                                            spreadRadius: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Main KYC text without rotation
                              AnimatedBuilder(
                                animation: _particleController,
                                builder: (context, child) {
                                  return Container(
                                    width: screenWidth * 0.7,
                                    height: screenHeight * 0.35,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.9),
                                          Colors.white.withOpacity(0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Animated KYC letters
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: ['K', 'Y', 'C']
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              int index = entry.key;
                                              String letter = entry.value;
                                              return AnimatedBuilder(
                                                animation: _glowController,
                                                builder: (context, child) {
                                                  return Transform.scale(
                                                    scale: 1.0 +
                                                        (_glowAnimation.value *
                                                            0.1 *
                                                            (index + 1)),
                                                    child: Transform.translate(
                                                      offset: Offset(
                                                        0,
                                                        math.sin(
                                                                _particleAnimation
                                                                        .value +
                                                                    index) *
                                                            5,
                                                      ),
                                                      child: Text(
                                                        letter,
                                                        style: TextStyle(
                                                          fontSize: 48,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color.lerp(
                                                            const Color(
                                                                0xFF4F46E5),
                                                            const Color(
                                                                0xFF7C3AED),
                                                            (math.sin(_particleAnimation
                                                                            .value +
                                                                        index) +
                                                                    1) /
                                                                2,
                                                          ),
                                                          letterSpacing: 8,
                                                          shadows: [
                                                            Shadow(
                                                              offset:
                                                                  const Offset(
                                                                      2, 2),
                                                              blurRadius: 10,
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.3),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }).toList(),
                                          ),

                                          const SizedBox(height: 20),

                                          // Animated subtitle
                                          AnimatedBuilder(
                                            animation: _glowController,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale: 1.0 +
                                                    (_glowAnimation.value *
                                                        0.05),
                                                child: Text(
                                                  'AI Assistant',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        const Color(0xFF4F46E5),
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // Animated welcome text
                    AnimatedBuilder(
                      animation: _subtitleAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset:
                              Offset(0, 20 * (1 - _subtitleAnimation.value)),
                          child: Opacity(
                            opacity: _subtitleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Your AI Assistant is Ready!',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Animated button
                    AnimatedBuilder(
                      animation: _buttonAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - _buttonAnimation.value)),
                          child: Opacity(
                            opacity: _buttonAnimation.value,
                            child: Container(
                              width: double.infinity,
                              height: 65,
                              child: ThemedButton(
                                text: '🚀 Get Started',
                                onPressed: _checkStoredName,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wave painter for animated background
class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final double waveHeight;
  final Color waveColor;
  final double waveSpeed;

  WavePainter({
    required this.animation,
    required this.waveHeight,
    required this.waveColor,
    required this.waveSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final y = size.height * 0.5;
    path.moveTo(0, y);

    for (double x = 0; x <= size.width; x++) {
      path.lineTo(
        x,
        y +
            math.sin((x / size.width * 2 * math.pi) +
                    (animation.value * waveSpeed)) *
                waveHeight,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}
