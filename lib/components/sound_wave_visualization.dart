// lib/components/sound_wave_visualization.dart
import 'dart:math';
import 'package:flutter/material.dart';

class SoundWaveVisualization extends StatefulWidget {
  final bool isActive;
  final bool isUserSpeaking; // true for user, false for assistant

  const SoundWaveVisualization({
    Key? key,
    required this.isActive,
    required this.isUserSpeaking,
  }) : super(key: key);

  @override
  State<SoundWaveVisualization> createState() => _SoundWaveVisualizationState();
}

class _SoundWaveVisualizationState extends State<SoundWaveVisualization> with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;
  final Random _random = Random();
  final int _barCount = 30; // Number of sound bars

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      _barCount,
          (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + _random.nextInt(700)),
      ),
    );

    _animations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Start animations if active
    if (widget.isActive) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (var controller in _animationControllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimations() {
    for (var controller in _animationControllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void didUpdateWidget(SoundWaveVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color barColor = widget.isUserSpeaking
        ? Colors.blue
        : Colors.green;

    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedOpacity(
        opacity: widget.isActive ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 300),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            _barCount,
                (index) => AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                double height = widget.isActive
                    ? 20.0 + _animations[index].value * 80
                    : 10.0;

                return Container(
                  width: 5,
                  height: height,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
