import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:voice_chatbot_assistant/services/onboarding_service.dart';
import 'package:provider/provider.dart';
import '../constant/theme_provider.dart';
import '../constant/theme.dart';
import '../components/custom_button.dart';

class OnboardingAskScreen extends StatefulWidget {
  const OnboardingAskScreen({super.key});

  @override
  State<OnboardingAskScreen> createState() => _OnboardingAskScreenState();
}

class _OnboardingAskScreenState extends State<OnboardingAskScreen>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _iconController;
  late AnimationController _buttonController;
  late AnimationController _floatingController;

  late Animation<double> _titleAnimation;
  late Animation<double> _subtitleAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
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

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.bounceOut,
    ));

    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Start animations with delays
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _titleController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _subtitleController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _iconController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _buttonController.forward();

    // Start floating animation
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _iconController.dispose();
    _buttonController.dispose();
    _floatingController.dispose();
    super.dispose();
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
                  animation: _floatingController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(screenWidth, screenHeight),
                      painter: WavePainter(
                        animation: _floatingAnimation,
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
                  animation: _floatingController,
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
            SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextButton(
                          onPressed: () async {
                            await OnboardingService.markOnboardingCompleted();
                            Navigator.pushReplacementNamed(
                                context, '/homeScreen');
                          },
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated title
                        AnimatedBuilder(
                          animation: _titleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _titleAnimation.value,
                              child: Transform.translate(
                                offset:
                                    Offset(0, 20 * (1 - _titleAnimation.value)),
                                child: const Text(
                                  'ASK',
                                  style: TextStyle(
                                    fontSize: 72,
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
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // Animated subtitle
                        AnimatedBuilder(
                          animation: _subtitleAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                  0, 30 * (1 - _subtitleAnimation.value)),
                              child: Opacity(
                                opacity: _subtitleAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  child: const Text(
                                    'Ask anything to your AI assistant and get instant, intelligent responses tailored just for you.',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      height: 1.5,
                                      fontWeight: FontWeight.w300,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 50),

                        // Animated icon
                        AnimatedBuilder(
                          animation: _iconAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _iconAnimation.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Animated continue button
                  Expanded(
                    flex: 1,
                    child: AnimatedBuilder(
                      animation: _buttonAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - _buttonAnimation.value)),
                          child: Opacity(
                            opacity: _buttonAnimation.value,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ThemedButton(
                                  text: 'Continue',
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context, '/onboardingLearn');
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
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
