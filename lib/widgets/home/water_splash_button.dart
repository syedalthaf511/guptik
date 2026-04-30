import 'dart:math';
import 'package:flutter/material.dart';

const Color _ancientGold = Color(0xFFD4AF37);

class _WaterParticle {
  final double angle;
  final double velocity;
  final double size;
  final Color color;

  _WaterParticle({required this.angle, required this.velocity, required this.size, required this.color});
}

class WaterSplashButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const WaterSplashButton({super.key, required this.child, required this.onTap});

  @override
  State<WaterSplashButton> createState() => _WaterSplashButtonState();
}

class _WaterSplashButtonState extends State<WaterSplashButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_WaterParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        widget.onTap(); 
      }
    });
    _generateParticles();
  }

  void _generateParticles() {
    for (int i = 0; i < 25; i++) {
      _particles.add(
        _WaterParticle(
          angle: _random.nextDouble() * 2 * pi,
          velocity: 40 + _random.nextDouble() * 60,
          size: 2 + _random.nextDouble() * 3,
          color: _random.nextBool() ? _ancientGold.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.6),
        ),
      );
    }
  }

  void _handleTap() {
    if (!_controller.isAnimating) _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        fit: StackFit.passthrough,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double scale = 1.0;
              if (_controller.value > 0.0 && _controller.value < 0.3) {
                scale = 1.0 + (_controller.value / 0.3) * 0.08; 
              } else if (_controller.value >= 0.3 && _controller.value < 0.6) {
                scale = 1.08 - ((_controller.value - 0.3) / 0.3) * 0.08; 
              }

              double shakeX = 0.0;
              if (_controller.value > 0.1 && _controller.value < 0.7) {
                shakeX = sin((_controller.value - 0.1) * pi * 12) * 3.0; 
              }

              return Transform.translate(
                offset: Offset(shakeX, 0),
                child: Transform.scale(scale: scale, child: widget.child),
              );
            },
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(painter: _WaterSplashPainter(progress: _controller.value, particles: _particles));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterSplashPainter extends CustomPainter {
  final double progress;
  final List<_WaterParticle> particles;

  _WaterSplashPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final double opacity = 1.0 - progress;

    for (var particle in particles) {
      double dx = cos(particle.angle) * particle.velocity * progress;
      double dy = sin(particle.angle) * particle.velocity * progress;
      dy += 150 * progress * progress;

      paint.color = particle.color.withValues(alpha: opacity * particle.color.a);
      canvas.drawCircle(center + Offset(dx, dy), particle.size * (1.0 - (progress * 0.3)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterSplashPainter oldDelegate) => oldDelegate.progress != progress;
}