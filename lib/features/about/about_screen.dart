import 'package:flutter/material.dart';

import '../../core/data/app_content.dart';
import '../../core/widgets/pattern_page.dart';
import '../../core/widgets/premium_ui.dart';
import '../services/service_detail_screen.dart';
import 'company_profile_screen.dart';
import 'why_vmo_screen.dart';

enum AboutSection { overview, why }

class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    this.initialSection = AboutSection.overview,
    this.breadcrumb = 'Settings > About',
  });

  final AboutSection initialSection;
  final String breadcrumb;

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: breadcrumb,
      title: 'About',
      subtitle: 'VMO AERO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PatternSectionLabel('Company'),
          const SizedBox(height: 8),
          PatternGroup(
            children: [
              PatternListRow(
                title: 'Company Profile',
                subtitle: 'Who we are and how we operate',
                leading: const PatternDocIcon(),
                onTap: () => Navigator.of(context).push(
                  premiumRoute(
                    CompanyProfileScreen(breadcrumb: breadcrumb),
                  ),
                ),
              ),
              PatternListRow(
                title: 'Why VMO Aero',
                subtitle: 'What sets our office apart',
                leading: const PatternDocIcon(icon: Icons.star_outline_rounded),
                onTap: () => Navigator.of(context).push(
                  premiumRoute(
                    WhyVmoAeroScreen(breadcrumb: breadcrumb),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const PatternSectionLabel('Services'),
          const SizedBox(height: 8),
          PatternGroup(
            children: [
              for (final service in AppContent.services)
                PatternListRow(
                  title: service.title,
                  subtitle: service.tagline,
                  onTap: () => Navigator.of(context).push(
                    premiumRoute(ServiceDetailScreen(service: service)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
