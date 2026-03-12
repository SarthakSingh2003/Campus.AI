import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kira_college_ai/constant/theme_provider.dart';
import 'package:provider/provider.dart';

class UniverseBackground extends StatelessWidget {
  final Widget child;
  const UniverseBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradient,
        ),
      ),
      child: Stack(
        children: [
          if (theme.showSpaceElements) const _StarsLayer(),
          child,
        ],
      ),
    );
  }
}

// Simple white stars with subtle twinkling
class _StarsLayer extends StatefulWidget {
  const _StarsLayer();
  @override
  State<_StarsLayer> createState() => _StarsLayerState();
}

class _StarsLayerState extends State<_StarsLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _StarsPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _StarsPainter extends CustomPainter {
  final double progress;
  _StarsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    
    // Simple white stars with subtle twinkling
    for (int i = 0; i < 120; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final twinkle = math.sin(progress * 2 * math.pi + i) * 0.3 + 0.7;
      final baseSize = rnd.nextDouble() * 1.5;
      final r = baseSize * twinkle;
      
      // Simple white stars
      final starPaint = Paint()..color = Colors.white.withOpacity(0.6 * twinkle);
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => true;
}
