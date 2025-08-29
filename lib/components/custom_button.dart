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

    // Universe theme (only)
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
    textStyle = textStyle.copyWith(color: Colors.white, shadows: const [
      Shadow(blurRadius: 8, color: Colors.black26, offset: Offset(1, 2)),
    ]);

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
