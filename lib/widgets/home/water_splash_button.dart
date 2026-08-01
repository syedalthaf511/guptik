import 'dart:math'; // Needed for sin and pi in the shake effect

import 'package:flutter/material.dart';

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
      screenSize.width / 2 - widget.size.width / 2,
      screenSize.height / 2 - widget.size.height / 2,
    );

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {},
        child: Material(
          color: Colors.black.withValues(alpha: 0.8), // Dark backdrop
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double progress = _controller.value;

              // Shake effect during the first 15% of the animation
              double shakeX = 0;
              if (progress < 0.15) {
                shakeX = sin(progress * pi * 40) * 4; // sin and pi are now available
              }

              // Move the button from its original position to the screen center
              double moveProgress = ((progress - 0.15) / 0.20).clamp(0.0, 1.0);
              moveProgress = Curves.easeOutCubic.transform(moveProgress);
              Offset currentPosition = Offset.lerp(widget.startPosition, centerPosition, moveProgress)!;

              // Fade out the button near the end
              double iconOpacity = progress > 0.85 ? 1.0 - ((progress - 0.85) * 6.66).clamp(0.0, 1.0) : 1.0;

              return Stack(
                children: [
                  // Only the dark background – no particles
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