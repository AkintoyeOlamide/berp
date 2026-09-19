import 'package:flutter/material.dart';

import '../../core/data/company_profile.dart';
import '../../core/widgets/app_asset_image.dart';
import '../../core/widgets/pattern_page.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({
    super.key,
    this.breadcrumb = 'Home > About',
  });

  final String breadcrumb;

  static const _card = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: breadcrumb,
      title: 'Company Profile',
      titleSize: 20,
      subtitle: 'VMO AERO  ·  TM',
      heroAsset: CompanyProfile.coverAsset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CompanyProfile.tagline,
            style: PatternPage.panchang(size: 16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            '${CompanyProfile.website}   ${CompanyProfile.handle}',
            style: PatternPage.body(
              size: 12,
              weight: FontWeight.w500,
              color: PatternPage.blue,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in CompanyProfile.credentials)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: PatternPage.blue.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    chip,
                    style: PatternPage.body(
                      size: 10.5,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _Block(block: CompanyProfile.intro, showImage: false),
          const SizedBox(height: 28),
          const _Block(block: CompanyProfile.expertise),
          const SizedBox(height: 28),
          const _Block(block: CompanyProfile.credentialsBody),
          const SizedBox(height: 28),
          const _Block(block: CompanyProfile.ownership),
          const SizedBox(height: 28),
          const _Block(block: CompanyProfile.acquisition),
          const SizedBox(height: 32),
          const PatternSectionLabel('Acquisition models'),
          const SizedBox(height: 12),
          for (var i = 0; i < CompanyProfile.acquisitionModels.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _ModelCard(model: CompanyProfile.acquisitionModels[i]),
          ],
          const SizedBox(height: 32),
          const _Block(block: CompanyProfile.management),
          const SizedBox(height: 14),
          Text(
            CompanyProfile.managementClose,
            style: PatternPage.body(
              size: 13,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          const PatternSectionLabel('Management models'),
          const SizedBox(height: 12),
          for (var i = 0; i < CompanyProfile.models.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _ModelCard(model: CompanyProfile.models[i]),
          ],
          const SizedBox(height: 32),
          const _Block(block: CompanyProfile.visibility),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.block, this.showImage = true});

  final ProfileBlock block;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          block.heading,
          style: PatternPage.panchang(size: 16, weight: FontWeight.w700),
        ),
        if (showImage && block.imageAsset != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: AppAssetImage(
                block.imageAsset!,
                fit: BoxFit.cover,
                maxCacheWidth: 1100,
                errorBuilder: (_, error, stackTrace) =>
                    const ColoredBox(color: Color(0xFF121212)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          block.body,
          style: PatternPage.body(
            size: 13,
            color: Colors.white.withValues(alpha: 0.82),
            height: 1.5,
          ),
        ),
        if (block.bullets.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final bullet in block.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: PatternPage.body(
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.model});

  final ProfileModel model;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AppAssetImage(
              model.imageAsset,
              fit: BoxFit.cover,
              maxCacheWidth: 1100,
              errorBuilder: (_, error, stackTrace) =>
                  const ColoredBox(color: Color(0xFF1A1A1A)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: model.name,
                    style: PatternPage.panchang(
                      size: 15,
                      weight: FontWeight.w700,
                    ),
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
                const SizedBox(height: 10),
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
          ),
        ],
      ),
    );
  }
}
