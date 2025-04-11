import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      )..repeat(reverse: true),
    );

    for (int i = 0; i < 3; i++) {
      _animations.add(
        Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controllers[i],
            curve: Interval(
              0.2 * i,
              0.2 * i + 0.6, // Adjusted to ensure end <= 1.0
              curve: Curves.easeInOut,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedBuilder(
              animation: _controllers[i],
              builder: (context, child) {
                return Transform.scale(
                  scale: _animations[i].value,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
