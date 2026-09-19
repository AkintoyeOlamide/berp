import 'package:flutter/material.dart';

/// Decodes [Image.asset] at the size it will actually paint, not full file res.
class AppAssetImage extends StatelessWidget {
  const AppAssetImage(
    this.asset, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.errorBuilder,
    this.gaplessPlayback = true,
    this.maxCacheWidth = 1400,
  });

  final String asset;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;
  final ImageErrorWidgetBuilder? errorBuilder;
  final bool gaplessPlayback;
  final int maxCacheWidth;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logical = width ?? MediaQuery.sizeOf(context).width;
    final cacheWidth = (logical * dpr).round().clamp(64, maxCacheWidth);
    return Image.asset(
      asset,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      color: color,
      colorBlendMode: colorBlendMode,
      errorBuilder: errorBuilder,
      gaplessPlayback: gaplessPlayback,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
    );
  }
}
