import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_asset_image.dart';

/// Calm brand-blue field — soft light only, no busy particles or photos.
class LivingSkyBackdrop extends StatefulWidget {
  const LivingSkyBackdrop({super.key, this.imageAsset});

  /// Optional; when set, kept very veiled so it never competes with content.
  final String? imageAsset;

  @override
  State<LivingSkyBackdrop> createState() => _LivingSkyBackdropState();
}

class _LivingSkyBackdropState extends State<LivingSkyBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final pulse = _pulse.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (widget.imageAsset != null)
              Opacity(
                opacity: 0.22,
                child: AppAssetImage(
                  widget.imageAsset!,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.2),
                  maxCacheWidth: 900,
                ),
              ),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF243EA8),
                    AppColors.brandBlue,
                    AppColors.brandBlueDeep,
                    Color(0xFF0A1438),
                  ],
                  stops: [0.0, 0.35, 0.75, 1.0],
                ),
              ),
            ),

            // One soft glow — quiet atmosphere
            Align(
              alignment: const Alignment(-0.4, -0.75),
              child: Container(
                width: 260 + pulse * 30,
                height: 260 + pulse * 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6B92FF).withValues(alpha: 0.16 + pulse * 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
