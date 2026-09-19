import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/pattern_page.dart';

class ResourceSection {
  const ResourceSection({
    required this.heading,
    this.body,
    this.bullets = const [],
  });

  final String heading;
  final String? body;
  final List<String> bullets;
}

class ResourceDetailScreen extends StatelessWidget {
  const ResourceDetailScreen({
    super.key,
    required this.title,
    required this.sections,
    this.breadcrumb,
  });

  final String title;
  final String? breadcrumb;
  final List<ResourceSection> sections;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: PatternPage.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (breadcrumb != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Text(
                    breadcrumb!,
                    style: PatternPage.body(
                      size: 11,
                      color: PatternPage.muted,
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PatternBackButton(),
                      const SizedBox(height: 18),
                      const PatternDocIcon(size: 52),
                      const SizedBox(height: 28),
                      for (var i = 0; i < sections.length; i++) ...[
                        if (i > 0) const SizedBox(height: 28),
                        Text(
                          sections[i].heading,
                          style: PatternPage.panchang(
                            size: 18,
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (sections[i].body != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            sections[i].body!,
                            style: PatternPage.body(
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.82),
                              height: 1.5,
                            ),
                          ),
                        ],
                        if (sections[i].bullets.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          for (var b = 0;
                              b < sections[i].bullets.length;
                              b++) ...[
                            if (b > 0)
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: PatternPage.divider,
                              ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      sections[i].bullets[b],
                                      style: PatternPage.body(
                                        size: 13,
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
