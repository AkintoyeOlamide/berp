import 'package:flutter/material.dart';

import '../../core/data/app_content.dart';
import '../../core/data/company_profile.dart';
import '../../core/widgets/pattern_page.dart';

class WhyVmoAeroScreen extends StatelessWidget {
  const WhyVmoAeroScreen({
    super.key,
    this.breadcrumb = 'Home > About',
  });

  final String breadcrumb;

  static const _card = Color(0xFF121212);

  IconData _icon(String name) {
    return switch (name) {
      'public' => Icons.public_rounded,
      'handshake' => Icons.handshake_outlined,
      'hub' => Icons.hub_outlined,
      'verified' => Icons.verified_outlined,
      'eco' => Icons.eco_outlined,
      _ => Icons.visibility_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: breadcrumb,
      title: 'Why VMO Aero',
      titleSize: 20,
      subtitle: 'THE VMO AERO ADVANTAGE',
      heroAsset: '${CompanyProfile.dir}/profile_advantage.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CompanyProfile.advantageIntro,
            style: PatternPage.body(
              size: 13,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          for (var i = 0; i < CompanyProfile.advantages.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _AdvantageCard(
              item: CompanyProfile.advantages[i],
              icon: _icon(CompanyProfile.advantages[i].iconName),
            ),
          ],
          const SizedBox(height: 32),
          const PatternSectionLabel('How we work'),
          const SizedBox(height: 12),
          for (var i = 0; i < AppContent.whyChoose.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Material(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppContent.whyChoose[i].title,
                      style: PatternPage.panchang(
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppContent.whyChoose[i].body,
                      style: PatternPage.body(
                        size: 12,
                        color: PatternPage.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdvantageCard extends StatelessWidget {
  const _AdvantageCard({required this.item, required this.icon});

  final ProfileAdvantage item;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: PatternPage.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: PatternPage.blue.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(icon, color: PatternPage.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: PatternPage.panchang(
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: PatternPage.body(
                      size: 12,
                      color: PatternPage.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
