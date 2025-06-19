import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceWaveVisualization extends StatefulWidget {
  final double soundLevel;
  final bool isActive;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  const VoiceWaveVisualization({
    super.key,
    required this.soundLevel,
    required this.isActive,
    this.primaryColor = const Color(0xFF4F46E5),
    this.secondaryColor = const Color(0xFF7C3AED),
    this.size = 200,
  });

  @override
  State<VoiceWaveVisualization> createState() => _VoiceWaveVisualizationState();
}

class _VoiceWaveVisualizationState extends State<VoiceWaveVisualization>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _rotationController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimations();
      } else {
        _pulseController.stop();
        _waveController.stop();
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _rotationController.dispose();
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
          // Outer wave rings
          if (widget.isActive) ...[
            ...List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  final waveOffset =
                      _waveAnimation.value + (index * math.pi / 3);
                  final waveRadius = (widget.size * 0.4) +
                      (widget.soundLevel * 20) +
                      (index * 15);

                  return Transform.rotate(
                    angle: _rotationAnimation.value * (index + 1) * 0.1,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: WaveRingPainter(
                        radius: waveRadius,
                        waveOffset: waveOffset,
                        color: widget.primaryColor
                            .withOpacity(0.3 - (index * 0.1)),
                        waveHeight: 10 + (widget.soundLevel * 5),
                      ),
                    ),
                  );
                },
              );
            }),
          ],

          // Pulsing blob
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final pulseScale = widget.isActive
                  ? 1.0 +
                      (_pulseAnimation.value * 0.3) +
                      (widget.soundLevel * 0.2)
                  : 1.0;

              return Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.primaryColor.withOpacity(0.8),
                        widget.secondaryColor.withOpacity(0.6),
                        widget.primaryColor.withOpacity(0.3),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.isActive ? Icons.mic : Icons.mic_off,
                      size: widget.size * 0.25,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),

          // Inner ripple effect
          if (widget.isActive) ...[
            ...List.generate(2, (index) {
              return AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final rippleScale =
                      1.0 + (_pulseAnimation.value * 0.5) + (index * 0.2);
                  final rippleOpacity = (1.0 - _pulseAnimation.value) * 0.3;

                  return Transform.scale(
                    scale: rippleScale,
                    child: Container(
                      width: widget.size * 0.4,
                      height: widget.size * 0.4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              widget.secondaryColor.withOpacity(rippleOpacity),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ],
      ),
    );
  }
}

class WaveRingPainter extends CustomPainter {
  final double radius;
  final double waveOffset;
  final Color color;
  final double waveHeight;

  WaveRingPainter({
    required this.radius,
    required this.waveOffset,
    required this.color,
    required this.waveHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();

    for (double angle = 0; angle < 2 * math.pi; angle += 0.1) {
      final waveRadius = radius + math.sin(angle * 3 + waveOffset) * waveHeight;
      final x = center.dx + math.cos(angle) * waveRadius;
      final y = center.dy + math.sin(angle) * waveRadius;

      if (angle == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveRingPainter oldDelegate) => true;
}
