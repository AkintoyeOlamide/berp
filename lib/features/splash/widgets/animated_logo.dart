import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

const String logoWhiteAssetPath = 'assets/images/vmowhite.png';
const String logoColorAssetPath = 'assets/images/VMOAEROlogo.png';

/// Knock near-black pixels out so the mark sits cleanly on any field.
const ColorFilter _knockoutBlack = ColorFilter.matrix(<double>[
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
]);

enum LogoTone { onDark, onLight }

/// Brand wordmark — white on dark fields, color on light fields.
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({
    super.key,
    required this.width,
    required this.scale,
    required this.opacity,
    this.glow = 0.4,
    this.tone = LogoTone.onDark,
  });

  final double width;
  final double scale;
  final double opacity;
  final double glow;
  final LogoTone tone;

  @override
  Widget build(BuildContext context) {
    final height = width / 3.4;
    final asset =
        tone == LogoTone.onLight ? logoColorAssetPath : logoWhiteAssetPath;
    final glowColor = tone == LogoTone.onLight
        ? AppColors.brandBlue.withValues(alpha: 0.12 + glow * 0.1)
        : AppColors.brandBlueGlow.withValues(alpha: 0.2 + glow * 0.15);

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: width,
          height: height * 1.15,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (glow > 0)
                Container(
                  width: width * 0.85,
                  height: height * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 36 + glow * 16,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ColorFiltered(
                colorFilter: _knockoutBlack,
                child: Image.asset(
                  asset,
                  width: width,
                  height: height,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
