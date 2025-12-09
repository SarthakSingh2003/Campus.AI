import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kira_college_ai/constant/universe_background.dart';
import 'package:kira_college_ai/constant/theme_provider.dart';
import 'package:kira_college_ai/services/auth_service.dart';

class SpaceScaffold extends StatefulWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBack;

  const SpaceScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.showBack = true,
  });

  @override
  State<SpaceScaffold> createState() => _SpaceScaffoldState();
}

class _SpaceScaffoldState extends State<SpaceScaffold>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _glowController;
  late AnimationController _waveController;
  late Animation<double> _titleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _waveController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _titleAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.elasticOut,
    );
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    _waveAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _glowController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.floatingActionButton,
      body: UniverseBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 800;
              final horizontalPadding = isWide ? constraints.maxWidth * 0.12 : 20.0;
              return Stack(
                children: [
                  // Ambient animated glows
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, _) {
                        return Positioned(
                          left: (index * 120) +
                              (math.sin(_waveAnimation.value + index) * 40) +
                              (isWide ? constraints.maxWidth * 0.06 : 0),
                          top: 120.0 * (index + 1) +
                              (math.cos(_waveAnimation.value + index) * 30),
                          child: Container(
                            width: 260,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  theme.accent.withOpacity(0.14),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 16,
                        ),
                        child: _AnimatedAppBar(
                          title: widget.title,
                          showBack: widget.showBack,
                          actions: widget.actions,
                          glowAnimation: _glowAnimation,
                        ),
                      ),

                      // Frosted content container for consistency
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            20,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                child: widget.child,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnimatedAppBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Animation<double> glowAnimation;

  const _AnimatedAppBar({
    required this.title,
    required this.showBack,
    required this.glowAnimation,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                } else {
                  navigator.pushReplacementNamed('/chatScreen');
                }
              },
            ),
          ),
        if (showBack) const SizedBox(width: 16),
        Expanded(
          child: AnimatedBuilder(
            animation: glowAnimation,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.16 + (glowAnimation.value * 0.06)),
                      Colors.white.withOpacity(0.08 + (glowAnimation.value * 0.04)),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (actions != null) ...[
                      const SizedBox(width: 12),
                      ...actions!,
                    ],
                    const SizedBox(width: 12),
                    Consumer<AuthService>(
                      builder: (context, auth, _) {
                        return IconButton(
                          tooltip: 'Profile',
                          icon: const Icon(
                            Icons.account_circle_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // If already on profile, do nothing
                            final routeName = ModalRoute.of(context)?.settings.name;
                            if (routeName == '/profile') return;
                            Navigator.pushNamed(context, '/profile');
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


