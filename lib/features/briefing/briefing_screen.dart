import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/app_content.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/premium_ui.dart';

class BriefingScreen extends StatelessWidget {
  const BriefingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);

    return PremiumPage(
      title: 'BRIEFING ROOM',
      leading: const BackChip(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: r.scale(8)),
          const Eyebrow('VMO Intelligence'),
          SizedBox(height: r.scale(8)),
          const DisplayTitle('Briefing Room'),
          SizedBox(height: r.scale(12)),
          const BodyCopy(
            'Acquisition, management, and regulatory perspective for private '
            'aviation in Nigeria and West Africa — published as discrete briefs.',
          ),
          SizedBox(height: r.scale(28)),
          ResponsiveGrid(
            children: [
              for (final b in AppContent.briefs)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(r.scale(22)),
                  decoration: premiumCardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.category.toUpperCase(),
                        style: GoogleFonts.sora(
                          color: p.eyebrow,
                          fontSize: 11,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: r.scale(8)),
                      Text(
                        b.title,
                        style: GoogleFonts.fraunces(
                          color: p.title,
                          fontSize: r.font(22, tablet: 26),
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: r.scale(8)),
                      Text(
                        '${b.date} · ${b.readMins} min read',
                        style: GoogleFonts.sora(color: p.body, fontSize: 12.5),
                      ),
                      SizedBox(height: r.scale(10)),
                      BodyCopy(b.excerpt),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: r.scale(8)),
          const PremiumDivider(),
          SizedBox(height: r.scale(20)),
          Text(
            'Client guide',
            style: GoogleFonts.fraunces(
              color: p.title,
              fontSize: r.font(24, tablet: 28),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: r.scale(8)),
          const BodyCopy(
            'Direct answers on charter, ownership, and management.',
          ),
          SizedBox(height: r.scale(16)),
          ...AppContent.faqs.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: r.scale(10)),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.only(bottom: r.scale(12)),
                  title: Text(
                    f.question,
                    style: GoogleFonts.sora(
                      color: p.title,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  iconColor: p.eyebrow,
                  collapsedIconColor: p.body,
                  children: [BodyCopy(f.answer)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
