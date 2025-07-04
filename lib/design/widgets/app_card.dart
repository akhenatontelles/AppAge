import 'package:flutter/material.dart';
import '../app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          if (elevation != 0)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: elevation ?? 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: onTap != null ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            highlightColor: onTap != null ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );

    return card;
  }
}
