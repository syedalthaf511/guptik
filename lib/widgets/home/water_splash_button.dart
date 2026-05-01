import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

const Color _ancientGold = Color(0xFFD4AF37);

// ==========================================
// THE BUTTON WRAPPER
// ==========================================
class WaterSplashButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const WaterSplashButton({super.key, required this.child, required this.onTap});

  @override
  State<WaterSplashButton> createState() => _WaterSplashButtonState();
}

class _WaterSplashButtonState extends State<WaterSplashButton> {
  bool _isHidden = false;

  void _handleTap() {
    if (_isHidden) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset startPosition = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    setState(() {
      _isHidden = true;
    });

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return _FullScreenSplashOverlay(
          startPosition: startPosition,
          size: size,
          childWidget: widget.child,
          onComplete: () {
            overlayEntry.remove();
            if (mounted) {
              setState(() {
                _isHidden = false;
              });
              widget.onTap();
            }
          },
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
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
            animation: ModalRoute.of(context)?.animation ?? const AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              return Opacity(
                opacity: _isHidden ? 0.0 : 1.0,
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// THE FULL SCREEN OVERLAY ANIMATION
// ==========================================
class _FullScreenSplashOverlay extends StatefulWidget {
  final Offset startPosition;
  final Size size;
  final Widget childWidget;
  final VoidCallback onComplete;

  const _FullScreenSplashOverlay({
    required this.startPosition,
    required this.size,
    required this.childWidget,
    required this.onComplete,
  });

  @override
  State<_FullScreenSplashOverlay> createState() => _FullScreenSplashOverlayState();
}

class _FullScreenSplashOverlayState extends State<_FullScreenSplashOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_WaterDrop> _drops = [];
  final List<_IceCube> _iceCubes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _generateParticles();
    _controller.forward();
  }

  void _generateParticles() {
    // 1. Generate Realistic Rain Drops
    for (int i = 0; i < 70; i++) {
      _drops.add(_WaterDrop(
        startX: (_random.nextDouble() - 0.5) * widget.size.width,
        startY: (_random.nextDouble() - 0.5) * widget.size.height,
        speedX: (_random.nextDouble() - 0.5) * 120, // Tighter splash
        speedY: 100 + _random.nextDouble() * 300,
        size: 2.0 + _random.nextDouble() * 4.0, 
        delay: _random.nextDouble() * 0.25,
      ));
    }

    // 2. Generate Cinematic Ice Cubes (Guaranteed NO overlaps)
    int numCubes = 8; // Exactly 8 cubes across the bottom
    double availableScreenWidthPercentage = 0.85; // Use 85% of the screen width
    double startXPercentage = 0.075; // Start 7.5% from the left edge
    double slotWidth = availableScreenWidthPercentage / numCubes; // Divide space into 8 equal slots

    for (int i = 0; i < numCubes; i++) {
      double cubeSize = 35 + _random.nextDouble() * 15; // 35px to 50px size

      // Create internal frosted planes to simulate shattered ice core
      List<Path> internalPlanes = [];
      int numPlanes = 1 + _random.nextInt(2);
      for (int c = 0; c < numPlanes; c++) {
        Path plane = Path()
          ..moveTo((_random.nextDouble() - 0.5) * cubeSize, (_random.nextDouble() - 0.5) * cubeSize)
          ..lineTo((_random.nextDouble() - 0.5) * cubeSize, (_random.nextDouble() - 0.5) * cubeSize)
          ..lineTo((_random.nextDouble() - 0.5) * cubeSize, (_random.nextDouble() - 0.5) * cubeSize)
          ..close();
        internalPlanes.add(plane);
      }

      // Calculate exact position: Base slot position + a tiny bit of random jitter INSIDE its own slot
      double basePositionX = startXPercentage + (i * slotWidth);
      double jitter = _random.nextDouble() * (slotWidth * 0.6); // Random position strictly inside its boundary
      double finalPositionX = basePositionX + jitter;

      _iceCubes.add(_IceCube(
        screenPositionX: finalPositionX, 
        rotation: (_random.nextDouble() - 0.5) * 0.8, // Random tilt
        size: cubeSize,
        internalPlanes: internalPlanes,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerPosition = Offset(
      screenSize.width / 2 - widget.size.width / 2,
      screenSize.height / 2 - widget.size.height / 2,
    );

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {},
        child: Material(
          color: Colors.black.withValues(alpha: 0.8), // Darker backdrop to make the glass pop
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double progress = _controller.value;

              double shakeX = 0;
              if (progress < 0.15) {
                shakeX = sin(progress * pi * 40) * 4;
              }

              double moveProgress = ((progress - 0.15) / 0.20).clamp(0.0, 1.0);
              moveProgress = Curves.easeOutCubic.transform(moveProgress);

              Offset currentPosition = Offset.lerp(widget.startPosition, centerPosition, moveProgress)!;

              double iconOpacity = progress > 0.85 ? 1.0 - ((progress - 0.85) * 6.66).clamp(0.0, 1.0) : 1.0;

              return Stack(
                children: [
                  CustomPaint(
                    size: screenSize,
                    painter: _CinematicWaterIcePainter(
                      progress: progress,
                      drops: _drops,
                      iceCubes: _iceCubes,
                      iconCenter: Offset(centerPosition.dx + widget.size.width / 2, centerPosition.dy + widget.size.height / 2),
                      screenSize: screenSize,
                    ),
                  ),
                  Positioned(
                    left: currentPosition.dx + shakeX,
                    top: currentPosition.dy,
                    width: widget.size.width,
                    height: widget.size.height,
                    child: Opacity(
                      opacity: iconOpacity,
                      child: Transform.scale(
                        scale: 1.0 + (moveProgress * 0.6),
                        child: widget.childWidget,
                      ),
                    ),
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

// ==========================================
// PARTICLE DATA & CUSTOM PAINTER
// ==========================================

class _WaterDrop {
  final double startX;
  final double startY;
  final double speedX;
  final double speedY;
  final double size;
  final double delay;

  _WaterDrop({required this.startX, required this.startY, required this.speedX, required this.speedY, required this.size, required this.delay});
}

class _IceCube {
  final double screenPositionX;
  final double rotation;
  final double size;
  final List<Path> internalPlanes;

  _IceCube({required this.screenPositionX, required this.rotation, required this.size, required this.internalPlanes});
}

class _CinematicWaterIcePainter extends CustomPainter {
  final double progress;
  final List<_WaterDrop> drops;
  final List<_IceCube> iceCubes;
  final Offset iconCenter;
  final Size screenSize;

  _CinematicWaterIcePainter({
    required this.progress,
    required this.drops,
    required this.iceCubes,
    required this.iconCenter,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ==========================================
    // PHASE 1: REALISTIC GLASSY RAIN
    // ==========================================
    if (progress > 0.35) {
      double waterProgress = ((progress - 0.35) / 0.40).clamp(0.0, 1.0);
      
      final Paint dropBodyPaint = Paint()..style = PaintingStyle.fill;
      final Paint dropHighlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.9)..style = PaintingStyle.fill;

      for (var drop in drops) {
        double dropP = (waterProgress - drop.delay).clamp(0.0, 1.0);
        if (dropP <= 0) continue;

        Offset startPos = iconCenter + Offset(drop.startX, drop.startY);

        double currentSpeedY = drop.speedY + (900 * dropP); // Gravity
        double dx = drop.speedX * dropP;
        double dy = (drop.speedY * dropP) + (450 * dropP * dropP);

        Offset dropPos = startPos + Offset(dx, dy);

        if (dropPos.dy < screenSize.height) {
          double alphaFade = 1.0 - dropP;
          dropBodyPaint.color = const Color(0xFFB3E5FC).withValues(alpha: 0.4 * alphaFade); 
          dropHighlightPaint.color = Colors.white.withValues(alpha: 0.9 * alphaFade);

          double angle = atan2(currentSpeedY, drop.speedX);

          canvas.save();
          canvas.translate(dropPos.dx, dropPos.dy);
          canvas.rotate(angle);

          double stretchFactor = 2.0 + (currentSpeedY / 250);
          Rect dropRect = Rect.fromCenter(center: Offset.zero, width: drop.size * stretchFactor, height: drop.size);
          canvas.drawOval(dropRect, dropBodyPaint);

          Rect highlightRect = Rect.fromCenter(center: Offset(drop.size * 0.4, -drop.size * 0.2), width: drop.size * stretchFactor * 0.5, height: drop.size * 0.4);
          canvas.drawOval(highlightRect, dropHighlightPaint);

          canvas.restore();
        }
      }
    }

    // ==========================================
    // PHASE 2: REALISTIC CINEMATIC ICE CUBES
    // ==========================================
    if (progress > 0.55) {
      double iceProgress = ((progress - 0.55) / 0.30).clamp(0.0, 1.0);
      
      double iceScale = Curves.bounceOut.transform(iceProgress);

      for (var cube in iceCubes) {
        canvas.save();
        
        // Cubes are now perfectly spaced using screenPositionX
        Offset cubeCenter = Offset(screenSize.width * cube.screenPositionX, screenSize.height - (cube.size / 2) - 5);
        
        canvas.translate(cubeCenter.dx, cubeCenter.dy);
        canvas.rotate(cube.rotation);
        canvas.scale(iceScale);

        Rect rect = Rect.fromCenter(center: Offset.zero, width: cube.size, height: cube.size);
        RRect roundedRect = RRect.fromRectAndRadius(rect, Radius.circular(cube.size * 0.2)); 

        // 0. Soft Floor Shadow
        final Paint shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawRRect(roundedRect.shift(const Offset(0, 10)), shadowPaint);

        // 1. Deep Frost Base Gradient
        final Paint basePaint = Paint()
          ..shader = ui.Gradient.linear(
            rect.topLeft,
            rect.bottomRight,
            [
              Colors.white.withValues(alpha: 0.6), 
              const Color(0xFFE0F7FA).withValues(alpha: 0.3), 
              const Color(0xFF81D4FA).withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.4),
            ],
            [0.0, 0.4, 0.8, 1.0],
          );
        canvas.drawRRect(roundedRect, basePaint);

        // 2. Internal Refractive Planes
        final Paint internalPlanePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        for (var plane in cube.internalPlanes) {
          canvas.drawPath(plane, internalPlanePaint);
        }

        // 3. Thick Glass Rim
        Rect innerRect = rect.deflate(cube.size * 0.10);
        RRect innerRounded = RRect.fromRectAndRadius(innerRect, Radius.circular(cube.size * 0.15));
        final Paint innerPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRRect(innerRounded, innerPaint);

        // 4. Specular Edges
        final Paint highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.0;
        
        Path highlightPath = Path()
          ..moveTo(rect.bottomLeft.dx, rect.bottomLeft.dy - (cube.size * 0.3))
          ..lineTo(rect.topLeft.dx, rect.topLeft.dy)
          ..lineTo(rect.topRight.dx - (cube.size * 0.3), rect.topRight.dy);
        canvas.drawPath(highlightPath, highlightPaint);

        // 5. Diagonal Face Reflection
        Path reflectionPath = Path()
          ..moveTo(rect.topLeft.dx + (cube.size * 0.1), rect.topLeft.dy)
          ..lineTo(rect.bottomRight.dx - (cube.size * 0.4), rect.bottomRight.dy)
          ..lineTo(rect.bottomRight.dx - (cube.size * 0.2), rect.bottomRight.dy)
          ..lineTo(rect.topLeft.dx + (cube.size * 0.3), rect.topLeft.dy)
          ..close();
        
        final Paint reflectionPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawPath(reflectionPath, reflectionPaint);

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicWaterIcePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}