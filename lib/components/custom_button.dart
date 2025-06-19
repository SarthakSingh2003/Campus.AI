import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constant/theme_provider.dart';
import '../constant/theme.dart';

class ThemedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;
  final double borderRadius;
  final IconData? icon;

  const ThemedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 55,
    this.borderRadius = 25,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = Provider.of<ThemeProvider>(context).currentTheme;
    BoxDecoration decoration;
    TextStyle textStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: appTheme.textColor,
      letterSpacing: 1,
    );

    if (appTheme.type == ThemeType.universe) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [appTheme.primary, appTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: appTheme.primary.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      );
      textStyle = textStyle.copyWith(color: Colors.white, shadows: [
        const Shadow(
            blurRadius: 8, color: Colors.black26, offset: Offset(1, 2)),
      ]);
    } else if (appTheme.type == ThemeType.rainbow) {
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFe66465),
            Color(0xFFf6b73c),
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
            Color(0xFFEC4899),
            Color(0xFFF59E0B),
            Color(0xFF10B981),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      );
      textStyle =
          textStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w900);
    } else {
      // Glass
      decoration = BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      );
      textStyle = textStyle.copyWith(color: Colors.white.withOpacity(0.95));
    }

    return Container(
      height: height,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textStyle.color, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(text, style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
