import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
    this.height = 70,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isEnabled = onTap != null;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(isDark ? 0.4 : 0.9),
              color.withOpacity(isDark ? 0.2 : 0.7),
            ],
          ),
          boxShadow: [
            if (isEnabled)
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: Colors.white),
                  const SizedBox(width: 16),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
