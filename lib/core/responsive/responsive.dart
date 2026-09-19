import 'package:flutter/material.dart';

/// Breakpoints tuned for phones and tablets (portrait + landscape).
enum AppBreakpoint { phone, tablet, desktop }

/// Responsive helpers for VMO Aero — use instead of hard-coded sizes.
class R {
  R._(this.context, this.size);

  factory R.of(BuildContext context) {
    return R._(context, MediaQuery.sizeOf(context));
  }

  final BuildContext context;
  final Size size;

  double get width => size.width;
  double get height => size.height;
  double get shortest => size.shortestSide;
  double get longest => size.longestSide;

  bool get isPhone => shortest < 600;
  bool get isTablet => shortest >= 600 && shortest < 1100;
  bool get isDesktop => shortest >= 1100;
  bool get isLandscape => width > height;
  bool get isCompact => isPhone && !isLandscape;
  bool get isWide => width >= 700 || isTablet || isDesktop;

  /// Phone landscape or any landscape tablet/desktop — use split chrome.
  bool get useLandscapeChrome => isLandscape;

  AppBreakpoint get breakpoint {
    if (isDesktop) return AppBreakpoint.desktop;
    if (isTablet) return AppBreakpoint.tablet;
    return AppBreakpoint.phone;
  }

  /// Scales a design value from a 390pt phone baseline (gentler on tablets).
  double scale(double value) {
    final factor = (shortest / 390).clamp(0.88, 1.45);
    // In landscape, keep vertical rhythm tighter.
    final landscapeTighten = isLandscape ? 0.88 : 1.0;
    return value * factor * landscapeTighten;
  }

  /// Font size that grows gently on tablets without becoming huge.
  double font(double phone, {double? tablet, double? desktop}) {
    final base = switch (breakpoint) {
      AppBreakpoint.phone => phone,
      AppBreakpoint.tablet => tablet ?? phone * 1.14,
      AppBreakpoint.desktop => desktop ?? tablet ?? phone * 1.22,
    };
    return isLandscape ? base * 0.92 : base;
  }

  /// Horizontal page padding that breathes on larger screens.
  EdgeInsets get pagePadding {
    final horizontal = switch (breakpoint) {
      AppBreakpoint.phone => isLandscape ? width * 0.04 : 22.0,
      AppBreakpoint.tablet => isLandscape ? width * 0.05 : 40.0,
      AppBreakpoint.desktop => width * 0.08,
    };
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  /// Max readable content width for long-form / form screens.
  double get contentMaxWidth => switch (breakpoint) {
        AppBreakpoint.phone => isLandscape ? width : width,
        AppBreakpoint.tablet => isLandscape ? 1080.0 : 780.0,
        AppBreakpoint.desktop => 1180.0,
      };

  /// Useful width inside page padding, capped by [contentMaxWidth].
  double get contentWidth {
    final padded = width - pagePadding.horizontal;
    return padded.clamp(0.0, contentMaxWidth);
  }

  /// Grid columns for card catalogs (fleet, catering, team, briefs).
  int get gridColumns {
    if (isDesktop) return isLandscape ? 3 : 3;
    if (isTablet) return isLandscape ? 3 : 2;
    if (isLandscape) return width >= 780 ? 3 : 2;
    return 1;
  }

  /// Tighter catalog grids (meals, library tiles).
  int get denseGridColumns {
    if (isDesktop) return isLandscape ? 4 : 3;
    if (isTablet) return isLandscape ? 3 : 2;
    if (isLandscape) return width >= 800 ? 3 : 2;
    return 1;
  }

  double get gridGutter => scale(isPhone ? 10 : 14);

  /// Home discover carousel peek fraction.
  double get carouselViewportFraction {
    if (isDesktop) return 0.4;
    if (isTablet) return isLandscape ? 0.38 : 0.5;
    if (isLandscape) return 0.48;
    return 0.82;
  }

  /// Home award-card height.
  double get homeCardHeight {
    if (isLandscape) {
      return (height * 0.62).clamp(220.0, 340.0);
    }
    if (isTablet || isDesktop) {
      return (height * 0.36).clamp(300.0, 420.0);
    }
    return (width * 0.72).clamp(250.0, 360.0);
  }

  /// Whether home should use a side-by-side landscape layout.
  bool get homeSplitLayout => isLandscape;

  /// Wide wordmark width for splash / branding moments.
  double get splashLogoWidth {
    if (isLandscape && isPhone) return (width * 0.36).clamp(200.0, 340.0);
    return switch (breakpoint) {
      AppBreakpoint.phone => width * 0.72,
      AppBreakpoint.tablet => (width * 0.4).clamp(260.0, 400.0),
      AppBreakpoint.desktop => (width * 0.3).clamp(300.0, 480.0),
    };
  }

  double get splashLogoSize => splashLogoWidth * 0.38;

  /// Compact app-bar height for landscape pages.
  double get appBarHeight => isLandscape ? 48.0 : 56.0;

  T value<T>({required T phone, T? tablet, T? desktop}) {
    return switch (breakpoint) {
      AppBreakpoint.phone => phone,
      AppBreakpoint.tablet => tablet ?? phone,
      AppBreakpoint.desktop => desktop ?? tablet ?? phone,
    };
  }
}

/// Centers children and caps width for tablet/desktop readability.
class ContentConstraint extends StatelessWidget {
  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final cap = maxWidth ?? r.contentMaxWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, cap);
        final boundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        return Align(
          alignment: alignment,
          child: SizedBox(
            width: width,
            height: boundedHeight ? constraints.maxHeight : null,
            child: child,
          ),
        );
      },
    );
  }
}

/// Simple responsive grid using Wrap — good for heterogeneous card heights.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.columns,
    this.spacing,
    this.runSpacing,
  });

  final List<Widget> children;
  final int? columns;
  final double? spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final cols = (columns ?? r.gridColumns).clamp(1, 4);
    final gap = spacing ?? r.gridGutter;
    final vGap = runSpacing ?? r.gridGutter;

    if (cols <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) SizedBox(height: vGap),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = (width - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: vGap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Rebuilds when size/orientation changes — wrap screens that need layout adaptation.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, R r) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, R.of(context));
  }
}
