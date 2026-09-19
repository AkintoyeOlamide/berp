import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/app_content.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/premium_ui.dart';

class CertificationScreen extends StatelessWidget {
  const CertificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);

    return PremiumPage(
      title: 'CERTIFICATION',
      leading: const BackChip(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: r.scale(8)),
          const Eyebrow('Compliance'),
          SizedBox(height: r.scale(8)),
          const DisplayTitle('VMO Aero Certification'),
          SizedBox(height: r.scale(12)),
          BodyCopy(AppContent.certificationNote),
          SizedBox(height: r.scale(24)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(r.scale(22)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.brandBlueSoft.withValues(alpha: 0.35),
              ),
              color: AppColors.brandBlue.withValues(alpha: 0.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: AppColors.brandBlueSoft,
                  size: r.scale(28),
                ),
                SizedBox(height: r.scale(12)),
                Text(
                  'Regulatory & operational standards',
                  style: GoogleFonts.fraunces(
                    color: p.title,
                    fontSize: r.font(22, tablet: 26),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: r.scale(10)),
                const BodyCopy(
                  'NCAA airworthiness, crew certification, insurance, and '
                  'regulatory filings are monitored continuously under our '
                  'management programmes — not discovered at the wrong moment.',
                ),
              ],
            ),
          ),
          SizedBox(height: r.scale(20)),
          const ContentBlock(
            title: 'What principals can request',
            body:
                'Operator credentials, insurance certificates, and programme '
                'documentation through the Ground Desk or Principal Portal.',
          ),
        ],
      ),
    );
  }
}
