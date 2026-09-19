import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_asset_image.dart';
import 'app_bottom_nav.dart';

/// Shared dark hero + sheet chrome used across Settings, Portal, Entertainment.
class PatternPage extends StatelessWidget {
  const PatternPage({
    super.key,
    required this.title,
    required this.child,
    this.breadcrumb,
    this.subtitle,
    this.heroAsset = 'assets/images/home/why.jpg',
    this.bottom,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(22, 0, 22, 28),
    this.titleSize = 26,
    this.scrollBody = true,
  });

  final String title;
  final double titleSize;
  final bool scrollBody;
  final String? breadcrumb;
  final String? subtitle;
  final String heroAsset;
  final Widget child;
  final Widget? bottom;
  final List<Widget>? actions;
  final EdgeInsets padding;

  static const bg = Color(0xFF0A0A0A);
  static const sheet = Color(0xFF0B0B0B);
  static const muted = Color(0xFF8E8E93);
  static const row = Color(0xFF121212);
  static const divider = Color(0xFF2C2C2E);
  static const blue = Color(0xFF3044C4);

  static TextStyle panchang({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = Colors.white,
    double height = 1.1,
  }) {
    return TextStyle(
      fontFamily: 'Panchang',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle body({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double height = 1.35,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            if (breadcrumb != null)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Text(breadcrumb!, style: body(size: 11, color: muted)),
                ),
              ),
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.45,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0.45,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0.52,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: AppAssetImage(
                    heroAsset,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.3),
                    maxCacheWidth: 1100,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: Color(0xFF121212)),
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0xDD0A0A0A)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: 100,
              child: Container(
                decoration: const BoxDecoration(
                  color: sheet,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: appNavMinimized,
                        builder: (context, minimized, _) {
                          final bottomHeight = bottom == null
                              ? 0.0
                              : AppBottomNav.totalHeight(
                                      context,
                                      minimized: minimized,
                                    ) +
                                    8;
                          final header = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const PatternBackButton(),
                                  const Spacer(),
                                  ...?actions,
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                title,
                                style: panchang(
                                  size: titleSize,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  subtitle!,
                                  style: body(
                                    size: 10,
                                    weight: FontWeight.w500,
                                    color: muted,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                            ],
                          );
                          if (!scrollBody) {
                            return Padding(
                              padding: padding.copyWith(
                                bottom: padding.bottom + bottomHeight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  header,
                                  Expanded(child: child),
                                ],
                              ),
                            );
                          }
                          return SingleChildScrollView(
                            padding: padding.copyWith(
                              bottom: padding.bottom + bottomHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [header, child],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (bottom != null)
              Positioned(left: 0, right: 0, bottom: 0, child: bottom!),
          ],
        ),
      ),
    );
  }
}

class PatternBackButton extends StatelessWidget {
  const PatternBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A1A),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          if (onTap != null) {
            onTap!();
          } else {
            Navigator.of(context).maybePop();
          }
        },
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class PatternSectionLabel extends StatelessWidget {
  const PatternSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: PatternPage.body(
        size: 10.5,
        weight: FontWeight.w500,
        color: PatternPage.muted,
        height: 1.2,
      ),
    );
  }
}

class PatternGroup extends StatelessWidget {
  const PatternGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, thickness: 1, color: PatternPage.divider),
          children[i],
        ],
      ],
    );
  }
}

class PatternListRow extends StatelessWidget {
  const PatternListRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PatternPage.body(
                        size: 14,
                        weight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: PatternPage.body(
                          size: 11.5,
                          color: PatternPage.muted,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  (selected
                      ? Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: PatternPage.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 13,
                          ),
                        )
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: PatternPage.muted,
                          size: 22,
                        )),
            ],
          ),
        ),
      ),
    );
  }
}

class PatternDocIcon extends StatelessWidget {
  const PatternDocIcon({
    super.key,
    this.size = 42,
    this.icon = Icons.description_outlined,
  });

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF152A55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3044C4), width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.42),
    );
  }
}
