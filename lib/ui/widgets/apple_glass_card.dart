import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Apple Liquid / Frosted Glass container
class AppleGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blur;
  final Color? tintColor;
  final double opacity;
  final Border? border;
  final VoidCallback? onTap;

  const AppleGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 22,
    this.blur = 25.0,
    this.tintColor,
    this.opacity = 0.70,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBaseColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFFFFFFF);

    final glassColor = (tintColor ?? defaultBaseColor).withValues(
      alpha: isDark ? 0.65 : 0.75,
    );

    final defaultBorder = Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.8),
      width: 1.2,
    );

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? defaultBorder,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFF64748B).withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    if (margin != EdgeInsets.zero) {
      return Padding(padding: margin, child: content);
    }

    return content;
  }
}

/// Dynamic ambient gradient backdrop characteristic of iOS
class AppleGlassBackground extends StatelessWidget {
  final Widget child;

  const AppleGlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Subtle ambient blur orbs
        Positioned.fill(
          child: Container(
            color: isDark ? const Color(0xFF090D16) : const Color(0xFFF1F5F9),
          ),
        ),
        // Ambient Top-Right Orb
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? const Color(0xFF059669) : const Color(0xFF34D399))
                  .withValues(alpha: isDark ? 0.22 : 0.35),
            ),
          ),
        ),
        // Ambient Bottom-Left Orb
        Positioned(
          bottom: 40,
          left: -100,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? const Color(0xFF0284C7) : const Color(0xFF38BDF8))
                  .withValues(alpha: isDark ? 0.18 : 0.30),
            ),
          ),
        ),
        // Ambient Center Accent
        Positioned(
          top: 300,
          left: 60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? const Color(0xFF6366F1) : const Color(0xFFA855F7))
                  .withValues(alpha: isDark ? 0.14 : 0.22),
            ),
          ),
        ),
        // Heavy background blur to create silky mesh
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(color: Colors.transparent),
          ),
        ),
        // Main Foreground Child
        child,
      ],
    );
  }
}
