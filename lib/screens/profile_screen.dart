import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kira_college_ai/constant/messages.dart';
import 'package:kira_college_ai/services/auth_service.dart';
import 'package:kira_college_ai/services/chat_history_service.dart';
import 'package:provider/provider.dart';
import 'package:kira_college_ai/constant/universe_background.dart';
import 'dart:math' as math;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late String _currentTime;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Animation controllers
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _formController;
  late AnimationController _buttonController;
  late AnimationController _waveController;
  late AnimationController _pulseController;

  late Animation<double> _titleAnimation;
  late Animation<double> _subtitleAnimation;
  late Animation<double> _formAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

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

    _formAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeInOut,
    ));

    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _titleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _subtitleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _formController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _buttonController.forward();

    _waveController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('hh:mm a').format(
          DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final auth = context.watch<AuthService>();
    return Scaffold(
      body: UniverseBackground(
        child: Stack(
          children: [
            // Animated background waves
            ...List.generate(5, (index) {
              return AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(screenWidth, screenHeight),
                    painter: WavePainter(
                      animation: _waveAnimation,
                      waveHeight: 30 + (index * 15),
                      waveColor:
                          Colors.white.withOpacity(0.05 - (index * 0.01)),
                      waveSpeed: 1.0 + (index * 0.2),
                    ),
                  );
                },
              );
            }),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Back button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          if (auth.isLoggedIn)
                            TextButton.icon(
                              onPressed: () async {
                                await context.read<AuthService>().signOut();
                                if (mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/login', (r) => false);
                                }
                              },
                              icon: const Icon(Icons.logout, color: Colors.white),
                              label: const Text('Logout',
                                  style: TextStyle(color: Colors.white)),
                            ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Animated KYC title
                      AnimatedBuilder(
                        animation: _titleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _titleAnimation.value,
                            child: Transform.translate(
                              offset:
                                  Offset(0, 20 * (1 - _titleAnimation.value)),
                              child: const Text(
                                'Profile',
                                style: TextStyle(
                                  fontSize: 56,
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

                      const SizedBox(height: 10),

                      // Animated subtitle
                      AnimatedBuilder(
                        animation: _subtitleAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset:
                                Offset(0, 15 * (1 - _subtitleAnimation.value)),
                            child: Opacity(
                              opacity: _subtitleAnimation.value,
                              child: const Text(
                                'Your Information',
                                style: TextStyle(
                                  fontSize: 18,
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

                      // Animated central circle with pulsing effect and avatar
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Colors.white,
                                    Color(0xFFE0E7FF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: auth.currentUser?.avatarUrl != null
                                    ? CircleAvatar(
                                        radius: 60,
                                        backgroundImage: NetworkImage(
                                            auth.currentUser!.avatarUrl!),
                                      )
                                    : const Icon(
                                        Icons.person_outline,
                                        size: 60,
                                        color: Color(0xFF4F46E5),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 50),

                      // Animated user information display
                      AnimatedBuilder(
                        animation: _formAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - _formAnimation.value)),
                            child: Opacity(
                              opacity: _formAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User Name
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Name',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                              Text(
                                                auth.currentUser?.displayName ?? 'Guest User',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // User Email
                                    if (auth.currentUser?.email != null) ...[
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.email,
                                            color: Colors.white70,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Email',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w300,
                                                  ),
                                                ),
                                                Text(
                                                  auth.currentUser!.email!,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 20),
                                    ],
                                    
                                    // User ID
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.fingerprint,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'User ID',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                              Text(
                                                auth.currentUser?.userId ?? 'Unknown',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
                            offset: Offset(0, 20 * (1 - _buttonAnimation.value)),
                            child: Opacity(
                              opacity: _buttonAnimation.value,
                              child: Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Color(0xFFE0E7FF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(30),
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, '/chatScreen');
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '🎯 Start Conversation',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4F46E5),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const Spacer(),

                      // History preview
                      FutureBuilder(
                        future: ChatHistoryService().getAllChatHistories(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final items = snapshot.data!;
                          return Column(
                            children: [
                              const Text('Recent history',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: items.length > 3 ? 3 : items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM dd, hh:mm a')
                                                .format(item.timestamp),
                                            style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wave painter for background animation
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
    final y = size.height * 0.8;
    path.moveTo(0, y);

    for (double x = 0; x <= size.width; x++) {
      path.lineTo(
        x,
        y + math.sin((x / size.width * 2 * math.pi) + (animation.value * waveSpeed)) * waveHeight,
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
