import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/app_content.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/premium_ui.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);

    return PremiumPage(
      title: 'TEAM',
      leading: const BackChip(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: r.scale(12)),
          const Eyebrow('Private aviation office'),
          SizedBox(height: r.scale(12)),
          const DisplayTitle('Our Team'),
          SizedBox(height: r.scale(16)),
          const BodyCopy(
            'Lagos head office, airport operations, and UK representation — '
            'one accountable team for charter and ownership.',
          ),
          SizedBox(height: r.scale(36)),
          ResponsiveGrid(
            children: [
              for (final m in AppContent.team)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(r.scale(24)),
                  decoration: premiumCardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: GoogleFonts.fraunces(
                          color: p.title,
                          fontSize: r.font(24, tablet: 28),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: r.scale(10)),
                      Text(
                        m.role,
                        style: GoogleFonts.sora(
                          color: p.eyebrow,
                          fontSize: r.font(14),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: r.scale(28)),
          const PremiumDivider(),
          SizedBox(height: r.scale(28)),
          Text(
            'Client stories',
            style: GoogleFonts.fraunces(
              color: p.title,
              fontSize: r.font(26, tablet: 30),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: r.scale(18)),
          ResponsiveGrid(
            children: [
              for (final s in AppContent.stories)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(r.scale(24)),
                  decoration: premiumCardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“${s.quote}”',
                        style: GoogleFonts.fraunces(
                          color: p.title,
                          fontSize: r.font(19, tablet: 21),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: r.scale(16)),
                      Text(
                        s.name,
                        style: GoogleFonts.sora(
                          color: p.title,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: r.scale(4)),
                      Text(
                        s.title,
                        style: GoogleFonts.sora(
                          color: p.body,
                          fontSize: r.font(13),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
