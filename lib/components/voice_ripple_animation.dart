// lib/components/voice_ripple_animation.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceRippleAnimation extends StatefulWidget {
  final double soundLevel;
  final bool isActive;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  const VoiceRippleAnimation({
    super.key,
    required this.soundLevel,
    required this.isActive,
    this.primaryColor = const Color(0xFF4F46E5),
    this.secondaryColor = const Color(0xFF7C3AED),
    this.size = 200,
  });

  @override
  State<VoiceRippleAnimation> createState() => _VoiceRippleAnimationState();
}

class _VoiceRippleAnimationState extends State<VoiceRippleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _pulseController;
  late Animation<double> _rippleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
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

  void _startAnimations() {
    _rippleController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Multiple ripple circles
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                final delay = index * 0.3;
                final animationValue = (_rippleAnimation.value + delay) % 1.0;
                final scale = 0.3 + (animationValue * 0.7);
                final opacity = (1.0 - animationValue) * 0.6;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isActive
                            ? widget.primaryColor.withOpacity(opacity)
                            : Colors.white.withOpacity(opacity * 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Central pulsing circle
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final pulseScale = widget.isActive
                  ? _pulseAnimation.value * (1.0 + widget.soundLevel * 0.3)
                  : _pulseAnimation.value;

              return Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: widget.isActive
                          ? [
                              widget.primaryColor.withOpacity(0.8),
                              widget.secondaryColor.withOpacity(0.6),
                            ]
                          : [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                            ],
                    ),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: widget.primaryColor.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    widget.isActive ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: widget.size * 0.15,
                  ),
                ),
              );
            },
          ),

          // Sound level indicator
          if (widget.isActive)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: SoundLevelPainter(
                    soundLevel: widget.soundLevel,
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class SoundLevelPainter extends CustomPainter {
  final double soundLevel;
  final Color primaryColor;
  final Color secondaryColor;

  SoundLevelPainter({
    required this.soundLevel,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.4;
    final maxRadius = size.width / 2 * 0.8;

    // Draw sound level bars
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final barLength = radius + (soundLevel * maxRadius * 0.3);
      final barWidth = 3.0 + (soundLevel * 5.0);

      final startPoint = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final endPoint = Offset(
        center.dx + math.cos(angle) * barLength,
        center.dy + math.sin(angle) * barLength,
      );

      final paint = Paint()
        ..color = Color.lerp(primaryColor, secondaryColor, i / 8)!
            .withOpacity(0.6 + soundLevel * 0.4)
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(SoundLevelPainter oldDelegate) {
    return oldDelegate.soundLevel != soundLevel;
  }
}
