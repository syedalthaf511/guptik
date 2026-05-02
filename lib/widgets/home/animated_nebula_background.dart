import 'package:flutter/material.dart';

// ==========================================
// DEEP SPACE NEBULA ANIMATED BACKGROUND
// ==========================================
class AnimatedNebulaBackground extends StatefulWidget {
  const AnimatedNebulaBackground({super.key});

  @override
  State<AnimatedNebulaBackground> createState() => _AnimatedNebulaBackgroundState();
}

class _AnimatedNebulaBackgroundState extends State<AnimatedNebulaBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
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
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0.0,
              endAngle: 3.14159 * 2,
              transform: GradientRotation(_controller.value * 2 * 3.14159),
              colors: const [
                Color(0xFF0A0A0A),
                Color.fromARGB(255, 255, 117, 61),
                Color(0xFF0A0A0A),
                Color.fromARGB(255, 255, 117, 61),
                Color(0xFF0A0A0A),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          child: Opacity(
            opacity: 0.15,
            child: Image.network(
              'https://www.transparenttextures.com/patterns/stardust.png',
              repeat: ImageRepeat.repeat,
            ),
          ),
        );
      },
    );
  }
}