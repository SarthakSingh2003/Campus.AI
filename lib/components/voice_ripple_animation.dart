// lib/components/voice_ripple_animation.dart
import 'package:flutter/material.dart';

class VoiceRippleAnimation extends StatefulWidget {
  final bool isActive;
  final Color color;

  const VoiceRippleAnimation({
    Key? key,
    required this.isActive,
    required this.color,
  }) : super(key: key);

  @override
  State<VoiceRippleAnimation> createState() => _VoiceRippleAnimationState();
}

class _VoiceRippleAnimationState extends State<VoiceRippleAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceRippleAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.3),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Multiple ripple effects
                ...List.generate(3, (index) {
                  double delayedValue = (_animation.value - (index * 0.3)).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: 1.0 - delayedValue,
                    child: Transform.scale(
                      scale: widget.isActive ? 0.5 + (delayedValue * 0.8) : 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.color,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Center mic icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isActive ? widget.color : widget.color.withOpacity(0.5),
                  ),
                  child: Icon(
                    widget.isActive ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
