import 'package:flutter/material.dart';

import '../../core/data/app_content.dart';
import '../../core/data/company_profile.dart';
import '../../core/widgets/pattern_page.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Services',
      title: service.title,
      titleSize: 16,
      subtitle: service.tagline.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.body,
            style: PatternPage.body(
              size: 13,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.5,
            ),
          ),
          if (service.bullets.isNotEmpty) ...[
            const SizedBox(height: 28),
            const PatternSectionLabel('Included'),
            const SizedBox(height: 8),
            PatternGroup(
              children: [
                for (final bullet in service.bullets)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check,
                          size: 14,
                          color: service.color,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bullet,
                            style: PatternPage.body(
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (service.steps.isNotEmpty) ...[
            const SizedBox(height: 28),
            const PatternSectionLabel('How we work'),
            const SizedBox(height: 12),
            for (var i = 0; i < service.steps.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _StepCard(index: i + 1, step: service.steps[i], color: service.color),
            ],
          ],
          if (_modelsFor(service).isNotEmpty) ...[
            const SizedBox(height: 28),
            PatternSectionLabel(_modelsLabel(service)),
            const SizedBox(height: 12),
            for (var i = 0; i < _modelsFor(service).length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _ModelCopyCard(model: _modelsFor(service)[i]),
            ],
          ],
        ],
      ),
    );
  }

  static List<ProfileModel> _modelsFor(ServiceItem service) {
    if (service.title.contains('Acquisition')) {
      return CompanyProfile.acquisitionModels;
    }
    if (service.title.contains('Management')) {
      return CompanyProfile.models;
    }
    return const [];
  }

  static String _modelsLabel(ServiceItem service) {
    if (service.title.contains('Acquisition')) return 'Acquisition models';
    return 'Management models';
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.step,
    required this.color,
  });

  final int index;
  final (String, String) step;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PatternPage.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index.toString().padLeft(2, '0'),
            style: PatternPage.panchang(
              size: 13,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.$1,
                  style: PatternPage.panchang(
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.$2,
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
    );
  }
}

class _ModelCopyCard extends StatelessWidget {
  const _ModelCopyCard({required this.model});

  final ProfileModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PatternPage.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: model.name,
              style: PatternPage.panchang(size: 14, weight: FontWeight.w700),
              children: [
                if (model.mark.isNotEmpty)
                  TextSpan(
                    text: model.mark,
                    style: PatternPage.panchang(
                      size: 10,
                      weight: FontWeight.w600,
                      color: PatternPage.blue,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            model.body,
            style: PatternPage.body(
              size: 12.5,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
