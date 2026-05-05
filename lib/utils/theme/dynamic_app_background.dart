import 'package:flutter/material.dart';
import 'theme_manager.dart';
import  'package:guptik/widgets/home/animated_nebula_background.dart';

class DynamicAppBackground extends StatelessWidget {
  const DynamicAppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final mode = ThemeManager.instance.currentMode;

        if (mode == AppThemeMode.nebula) {
          // 1. Animated Nebula Theme
          return const AnimatedNebulaBackground();
        } else if (mode == AppThemeMode.dark) {
          // 2. Solid Dark Theme
          return Container(color: const Color(0xFF0A0A0A));
        } else {
          // 3. Classic Theme (Original Light Grey)
          return Container(color: const Color.fromARGB(255, 57, 47, 31));
        }
      },
    );
  }
}