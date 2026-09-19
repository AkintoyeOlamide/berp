import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import 'app_asset_image.dart';

/// Premium page chrome — landscape-aware header + atmosphere wash.
class PremiumPage extends StatelessWidget {
  const PremiumPage({
    super.key,
    required this.child,
    this.title,
    this.leading,
    this.actions,
    this.floatingActionButton,
    this.bottom,
    this.padding,
    this.scrollable = true,
  });

  final Widget child;
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottom;
  final EdgeInsets? padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);
    final landscape = r.useLandscapeChrome;
    final pad = padding ??
        r.pagePadding.copyWith(
          top: landscape ? r.scale(8) : r.scale(14),
          bottom: landscape ? r.scale(20) : r.scale(36),
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: p.scaffold,
        floatingActionButton: floatingActionButton,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _AtmosphereBackdrop(),
            SafeArea(
              bottom: false,
              child: ContentConstraint(
                maxWidth: landscape ? r.width : r.contentMaxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null || leading != null || actions != null)
                      _PageHeader(
                        title: title,
                        leading: leading,
                        actions: actions,
                        compact: landscape,
                      ),
                    Expanded(
                      child: scrollable
                          ? SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: pad,
                              child: child,
                            )
                          : Padding(padding: pad, child: child),
                    ),
                    ?bottom,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    this.title,
    this.leading,
    this.actions,
    required this.compact,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);

    return Container(
      margin: EdgeInsets.fromLTRB(
        r.pagePadding.left,
        compact ? r.scale(4) : r.scale(6),
        r.pagePadding.right,
        compact ? r.scale(6) : r.scale(10),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: r.scale(10),
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.card.withValues(alpha: p.isDark ? 0.55 : 0.72),
        border: Border.all(color: p.cardBorder),
      ),
      child: Row(
        children: [
          ?leading,
          if (leading != null) SizedBox(width: r.scale(8)),
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: GoogleFonts.sora(
                  color: p.title,
                  fontSize: r.font(13, tablet: 14),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
            )
          else
            const Spacer(),
          ...?actions,
        ],
      ),
    );
  }
}

class _AtmosphereBackdrop extends StatelessWidget {
  const _AtmosphereBackdrop();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: p.pageWash)),
        Opacity(
          opacity: p.isDark ? 0.22 : 0.12,
          child: AppAssetImage(
            'assets/images/map_backdrop.png',
            fit: BoxFit.cover,
            maxCacheWidth: 900,
            errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                p.mapScrimTop,
                p.mapScrimMid,
                p.mapScrimBottom,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class BackChip extends StatelessWidget {
  const BackChip({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
      color: p.title,
      style: IconButton.styleFrom(
        backgroundColor: p.chipFill,
        minimumSize: const Size(40, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.sora(
        color: p.eyebrow,
        fontSize: r.font(10.5, tablet: 11.5),
        fontWeight: FontWeight.w600,
        letterSpacing: 2.2,
      ),
    );
  }
}

class DisplayTitle extends StatelessWidget {
  const DisplayTitle(this.text, {super.key, this.maxLines});

  final String text;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);
    final size = r.isLandscape
        ? r.font(26, tablet: 32, desktop: 36)
        : r.font(32, tablet: 40, desktop: 46);
    return Text(
      text,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: GoogleFonts.fraunces(
        color: p.title,
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.1,
        letterSpacing: -0.3,
      ),
    );
  }
}

class BodyCopy extends StatelessWidget {
  const BodyCopy(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);
    return Text(
      text,
      style: GoogleFonts.sora(
        color: p.body,
        fontSize: r.font(14, tablet: 15),
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class PremiumDivider extends StatelessWidget {
  const PremiumDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      height: 1,
      color: p.hairline.withValues(alpha: 0.9),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 650),
  });

  final Widget child;
  final int delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + Duration(milliseconds: delay),
      curve: Interval(
        (delay / (duration.inMilliseconds + delay)).clamp(0.0, 0.85),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class DestinationTile extends StatelessWidget {
  const DestinationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: r.scale(16),
            vertical: r.scale(16),
          ),
          decoration: premiumCardDecoration(context),
          child: Row(
            children: [
              Container(
                width: r.scale(44),
                height: r.scale(44),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.brandBlue.withValues(alpha: 0.85),
                      AppColors.brandBlueDeep,
                    ],
                  ),
                ),
                child: Icon(icon, color: p.iconOnBrand, size: r.scale(20)),
              ),
              SizedBox(width: r.scale(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.sora(
                        color: p.title,
                        fontSize: r.font(15, tablet: 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: r.scale(4)),
                    Text(
                      subtitle,
                      style: GoogleFonts.sora(
                        color: p.body,
                        fontSize: r.font(12.5, tablet: 13),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: r.scale(18),
                color: p.accentRail.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContentBlock extends StatelessWidget {
  const ContentBlock({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r.scale(r.isLandscape ? 18 : 28)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(r.scale(18)),
        decoration: premiumCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.fraunces(
                color: p.title,
                fontSize: r.font(22, tablet: 26),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: r.scale(10)),
            BodyCopy(body),
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    return SizedBox(
      width: double.infinity,
      height: r.scale(50),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.sora(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            fontSize: r.font(13.5, tablet: 14.5),
          ),
        ),
      ),
    );
  }
}

/// Shared card shell — accent rail + soft panel.
BoxDecoration premiumCardDecoration(BuildContext context) {
  final p = AppPalette.of(context);
  return BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: p.cardBorder),
    color: p.card,
    boxShadow: p.isDark
        ? null
        : [
            BoxShadow(
              color: const Color(0xFF1A2F8C).withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
  );
}

/// Filter / tab chip used across feature screens.
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? AppColors.brandBlue.withValues(alpha: 0.38)
              : p.chipFill,
          border: Border.all(
            color: selected
                ? AppColors.brandBlueSoft.withValues(alpha: 0.55)
                : p.hairline,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.sora(
            color: selected ? p.title : p.body,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

PageRouteBuilder<T> premiumRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 160),
    reverseTransitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
