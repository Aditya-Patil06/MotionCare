// lib/core/widgets/motioncare_logo.dart
import 'package:flutter/material.dart';

import '../theme.dart';

class MotionCareLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;

  const MotionCareLogo({
    super.key,
    this.fontSize = 28,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Motion',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                  letterSpacing: -0.5,
                  fontFamily: 'sans-serif',
                ),
              ),
              TextSpan(
                text: 'Care',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryGreen,
                  letterSpacing: -0.5,
                  fontFamily: 'sans-serif',
                ),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'MOVE  •  RECOVER  •  LIVE BETTER',
            style: TextStyle(
              fontSize: (fontSize * 0.32).clamp(8.0, 11.0),
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted.withOpacity(0.8),
              letterSpacing: 2.2,
            ),
          ),
        ],
      ],
    );
  }
}
