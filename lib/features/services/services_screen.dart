import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/app_content.dart';
import '../../core/widgets/pattern_page.dart';
import '../../core/widgets/premium_ui.dart';
import 'service_detail_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Services',
      title: 'Our Services',
      titleSize: 18,
      subtitle: AppContent.serviceStrip.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'One coordinated partner from sourcing and purchase through '
            'operations and maintenance — acquire the aircraft, operate with authority.',
            style: PatternPage.body(
              size: 13,
              color: PatternPage.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppContent.services.length,
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
                onTap: () => Navigator.of(context).push(
                  premiumRoute(ServiceDetailScreen(service: service)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ServiceColorCard extends StatelessWidget {
  const ServiceColorCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: service.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withValues(alpha: 0.18),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(service.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                service.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: PatternPage.panchang(
                  size: 12,
                  weight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  service.tagline,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: PatternPage.body(
                    size: 11,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.3,
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
