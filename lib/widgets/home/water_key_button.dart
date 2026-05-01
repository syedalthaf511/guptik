import 'dart:math';
import 'package:flutter/material.dart';

const Color _ancientGold = Color(0xFFD4AF37);

// ==========================================
// THE FLYING KEY BUTTON WRAPPER
// ==========================================
class WaterKeyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const WaterKeyButton({super.key, required this.child, required this.onTap});

  @override
  State<WaterKeyButton> createState() => _WaterKeyButtonState();
}

class _WaterKeyButtonState extends State<WaterKeyButton> {
  bool _isHidden = false;

  void _handleTap() {
    if (_isHidden) return;

    // Get the exact location of the icon on the screen
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset startPosition = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    setState(() {
      _isHidden = true; // Hide the original widget while animating
    });

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return _FullScreenFlyingKeyOverlay(
          iconPosition: startPosition,
          iconSize: size,
          childWidget: widget.child,
          onComplete: () {
            overlayEntry.remove();
            if (mounted) {
              setState(() {
                _isHidden = false;
              });
              widget.onTap(); // Navigate to the next screen
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
      child: Opacity(
        opacity: _isHidden ? 0.0 : 1.0,
        child: widget.child,
      ),
    );
  }
}

// ==========================================
// THE FULL SCREEN OVERLAY ANIMATION
// ==========================================
class _FullScreenFlyingKeyOverlay extends StatefulWidget {
  final Offset iconPosition;
  final Size iconSize;
  final Widget childWidget;
  final VoidCallback onComplete;

  const _FullScreenFlyingKeyOverlay({
    required this.iconPosition,
    required this.iconSize,
    required this.childWidget,
    required this.onComplete,
  });

  @override
  State<_FullScreenFlyingKeyOverlay> createState() => _FullScreenFlyingKeyOverlayState();
}

class _FullScreenFlyingKeyOverlayState extends State<_FullScreenFlyingKeyOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  
  // Data for the water splash when the key hits the icon
  final List<double> _burstAngles = [];
  final List<double> _burstSpeeds = [];
  final List<double> _burstSizes = [];

  @override
  void initState() {
    super.initState();
    // Slightly longer duration (2.4s) to allow for the sequential staging
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    // Pre-calculate 30 random water droplets for the impact splash
    for (int i = 0; i < 30; i++) {
      _burstAngles.add(_random.nextDouble() * pi * 2);
      _burstSpeeds.add(80 + _random.nextDouble() * 250);
      _burstSizes.add(3 + _random.nextDouble() * 6);
    }

    _controller.forward();
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
      screenSize.width / 2 - widget.iconSize.width / 2,
      screenSize.height / 2 - widget.iconSize.height / 2,
    );
    final iconCenter = Offset(
      centerPosition.dx + widget.iconSize.width / 2,
      centerPosition.dy + widget.iconSize.height / 2,
    );

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // Prevent taps while animating
        child: Material(
          color: Colors.black.withValues(alpha: 0.65), // Dim the background slightly
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double progress = _controller.value;

              double iconShake = 0.0;
              double iconOpacity = 1.0;

              // ----------------------------------------------------
              // PHASE 1: Icon flies to center FIRST (0.0 to 0.25)
              // ----------------------------------------------------
              double moveProgress = (progress / 0.25).clamp(0.0, 1.0);
              moveProgress = Curves.easeOutCubic.transform(moveProgress);
              Offset currentPosition = Offset.lerp(widget.iconPosition, centerPosition, moveProgress)!;
              
              // Scale the icon up slightly when it hits the center so it looks prominent
              double iconScale = 1.0 + (moveProgress * 0.5); 

              // ----------------------------------------------------
              // PHASE 3: The Key Turns & Icon Rattles (0.6 to 0.8)
              // ----------------------------------------------------
              if (progress > 0.6 && progress < 0.8) {
                // Rattle the icon violently as the key forces it open
                iconShake = sin((progress - 0.6) * pi * 60) * 4; 
              } 
              
              // ----------------------------------------------------
              // PHASE 4: The Portal Opens & Transitions (0.8 to 1.0)
              // ----------------------------------------------------
              else if (progress >= 0.8) {
                double openProgress = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
                iconScale = 1.5 + (openProgress * 5.0); // Blow the icon up massive from its current 1.5x state
                iconOpacity = 1.0 - openProgress; // Fade it out into the new page
              }

              return Stack(
                children: [
                  // 1. The Original Icon 
                  Positioned(
                    left: currentPosition.dx + iconShake,
                    top: currentPosition.dy,
                    width: widget.iconSize.width,
                    height: widget.iconSize.height,
                    child: Opacity(
                      opacity: iconOpacity,
                      child: Transform.scale(
                        scale: iconScale,
                        child: widget.childWidget,
                      ),
                    ),
                  ),

                  // 2. The Flying Key Custom Painter
                  CustomPaint(
                    size: screenSize,
                    painter: _FlyingWaterKeyPainter(
                      progress: progress,
                      iconCenter: iconCenter,
                      screenSize: screenSize,
                      burstAngles: _burstAngles,
                      burstSpeeds: _burstSpeeds,
                      burstSizes: _burstSizes,
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
// THE FLYING KEY PAINTER
// ==========================================
class _FlyingWaterKeyPainter extends CustomPainter {
  final double progress;
  final Offset iconCenter;
  final Size screenSize;
  final List<double> burstAngles;
  final List<double> burstSpeeds;
  final List<double> burstSizes;

  _FlyingWaterKeyPainter({
    required this.progress,
    required this.iconCenter,
    required this.screenSize,
    required this.burstAngles,
    required this.burstSpeeds,
    required this.burstSizes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ----------------------------------------------------
    // PHASE 2: Key Flies in AFTER icon arrives (0.25 to 0.6)
    // ----------------------------------------------------
    double flyProgress = 0.0;
    if (progress > 0.25) {
      flyProgress = ((progress - 0.25) / 0.35).clamp(0.0, 1.0);
      flyProgress = Curves.easeOutBack.transform(flyProgress); 
    }

    // Origin point: Way off the top-right of the screen
    Offset keyOrigin = Offset(screenSize.width + 200, -200);
    
    // Current position of the key
    Offset currentKeyPos = Offset.lerp(keyOrigin, iconCenter, flyProgress)!;

    // ----------------------------------------------------
    // PHASE 3: Key Turns 90 Degrees (0.6 to 0.8)
    // ----------------------------------------------------
    double turnProgress = 0.0;
    if (progress > 0.6) {
      turnProgress = ((progress - 0.6) / 0.2).clamp(0.0, 1.0);
      turnProgress = Curves.easeInOutCubic.transform(turnProgress);
    }

    // Key is invisible before 0.25 (while icon is moving), and fades out during explosion (>0.8)
    double keyOpacity = 0.0;
    if (progress >= 0.25 && progress <= 0.8) {
      keyOpacity = 1.0;
    } else if (progress > 0.8) {
      keyOpacity = 1.0 - ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
    }

    // Render the Key
    if (keyOpacity > 0.0) {
      canvas.save();
      canvas.translate(currentKeyPos.dx, currentKeyPos.dy);

      // Key points diagonally while flying, then turns 90 degrees horizontally to unlock
      double rotation = (-pi / 4) * (1.0 - flyProgress) + (turnProgress * (pi / 2));
      canvas.rotate(rotation);

      // Key starts massive (3x) to look like it's in the foreground, shrinks to 1x as it hits the screen
      double keyScale = 3.0 - (flyProgress * 2.0);
      canvas.scale(keyScale);

      // --- Draw the Water Key ---
      final Paint keyGlow = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.6 * keyOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      final Paint keyCore = Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * keyOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeJoin = StrokeJoin.round;

      Path keyPath = Path();
      
      // Key Ring (Head)
      keyPath.addArc(Rect.fromCenter(center: const Offset(0, -30), width: 30, height: 30), 0, pi * 2);
      keyPath.addArc(Rect.fromCenter(center: const Offset(0, -30), width: 10, height: 10), 0, pi * 2);

      // Key Shaft
      keyPath.moveTo(0, -15);
      keyPath.lineTo(0, 40);

      // Key Teeth
      keyPath.moveTo(0, 20);
      keyPath.lineTo(20, 20);
      keyPath.moveTo(0, 35);
      keyPath.lineTo(12, 35);

      canvas.drawPath(keyPath, keyGlow);
      canvas.drawPath(keyPath, keyCore);
      canvas.restore();
    }

    // ----------------------------------------------------
    // PHASE 4: Water Burst & Shockwave on Impact (0.8 to 1.0)
    // ----------------------------------------------------
    if (progress > 0.8) {
      double burstProgress = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
      double burstFade = 1.0 - burstProgress;

      // 1. The Expanding Shockwave Ring
      final Paint shockwavePaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: burstFade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15.0 * burstFade
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      double ringRadius = burstProgress * (screenSize.width * 0.8);
      canvas.drawCircle(iconCenter, ringRadius, shockwavePaint);

      // 2. The Exploding Water Droplets
      final Paint dropPaint = Paint()..color = Colors.white.withValues(alpha: burstFade)..style = PaintingStyle.fill;
      final Paint dropGlow = Paint()..color = Colors.cyanAccent.withValues(alpha: burstFade)..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      for (int i = 0; i < burstAngles.length; i++) {
        double angle = burstAngles[i];
        double speed = burstSpeeds[i];
        double size = burstSizes[i];

        // Drops shoot outwards from the center
        double distance = speed * burstProgress;
        Offset dropPos = iconCenter + Offset(cos(angle) * distance, sin(angle) * distance);

        canvas.drawCircle(dropPos, size, dropGlow);
        canvas.drawCircle(dropPos, size * 0.6, dropPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlyingWaterKeyPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}