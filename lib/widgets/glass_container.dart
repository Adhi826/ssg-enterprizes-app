import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color borderGradientColor1;
  final Color borderGradientColor2;
  final Color bgGradientColor1;
  final Color bgGradientColor2;
  final double padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 15,
    this.borderGradientColor1 = const Color(0x33FFFFFF),
    this.borderGradientColor2 = const Color(0x0DFFFFFF),
    this.bgGradientColor1 = const Color(0x1AFFFFFF),
    this.bgGradientColor2 = const Color(0x08FFFFFF),
    this.padding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgGradientColor1, bgGradientColor2],
            ),
            border: Border.all(
              width: 1.5,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: child,
          ),
        ),
      ),
    );
  }
}
