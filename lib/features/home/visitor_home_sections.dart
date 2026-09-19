import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/app_content.dart';
import '../../core/widgets/pattern_page.dart';
import '../../core/widgets/premium_ui.dart';
import '../about/about_screen.dart';
import '../about/company_profile_screen.dart';
import '../about/why_vmo_screen.dart';
import '../contact/contact_screen.dart';
import '../entertainment/entertainment_screen.dart';
import '../services/service_detail_screen.dart';
import '../services/services_screen.dart';
import '../team/team_screen.dart';

class VisitorHomeSections extends StatelessWidget {
  const VisitorHomeSections({
    super.key,
    required this.panchang,
    required this.body,
    required this.muted,
  });

  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;
  final Color muted;

  void _open(BuildContext context, Widget page) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(premiumRoute(page));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Our Services',
          action: 'See All',
          panchang: panchang,
          body: body,
          muted: muted,
          onAction: () => _open(context, const ServicesScreen()),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            final service = AppContent.services[index];
            return ServiceColorCard(
              service: service,
              onTap: () => _open(context, ServiceDetailScreen(service: service)),
            );
          },
        ),
        const SizedBox(height: 12),
        _RequestAssistantButton(
          panchang: panchang,
          onTap: () => _open(
            context,
            const ContactScreen(initialIntent: 'assistance'),
          ),
        ),
        const SizedBox(height: 32),
        _SectionHeader(
          title: 'About Us',
          action: 'See All',
          panchang: panchang,
          body: body,
          muted: muted,
          onAction: () => _open(
            context,
            const AboutScreen(breadcrumb: 'Home > About'),
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.92,
          children: [
            _IconCard(
              title: 'Company Profile',
              subtitle: 'Who we are and how we operate',
              icon: Icons.apartment_outlined,
              onTap: () => _open(
                context,
                const CompanyProfileScreen(breadcrumb: 'Home > About'),
              ),
            ),
            _IconCard(
              title: 'Why VMO Aero',
              subtitle: 'What sets our office apart',
              icon: Icons.star_outline_rounded,
              onTap: () => _open(
                context,
                const WhyVmoAeroScreen(breadcrumb: 'Home > About'),
              ),
            ),
            _IconCard(
              title: 'Our Team',
              subtitle: 'People behind the office',
              icon: Icons.groups_outlined,
              accent: const Color(0xFF34C759),
              onTap: () => _open(context, const TeamScreen()),
            ),
            _IconCard(
              title: 'Games',
              subtitle: 'In-flight play and cabin activities',
              icon: Icons.sports_esports_outlined,
              accent: const Color(0xFFFF9F0A),
              onTap: () => _open(context, const EntertainmentScreen()),
            ),
          ],
        ),
      ],
    );
  }
}

class _RequestAssistantButton extends StatelessWidget {
  const _RequestAssistantButton({
    required this.panchang,
    required this.onTap,
  });

  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PatternPage.blue,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Request Assistance',
                textAlign: TextAlign.center,
                style: panchang(
                  size: 11,
                  weight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.panchang,
    required this.body,
    required this.muted,
    required this.onAction,
  });

  final String title;
  final String action;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;
  final Color muted;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: panchang(
            size: 12,
            weight: FontWeight.w600,
            color: Colors.white,
            height: 1.1,
            letterSpacing: 0,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onAction();
          },
          child: Text(
            action,
            style: body(
              size: 10.5,
              weight: FontWeight.w500,
              color: muted,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconCard extends StatelessWidget {
  const _IconCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accent = PatternPage.blue,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: PatternPage.panchang(
                  size: 12,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: PatternPage.body(
                    size: 11,
                    color: PatternPage.muted,
                    height: 1.35,
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

