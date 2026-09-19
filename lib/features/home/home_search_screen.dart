import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/auth_service.dart';
import '../../core/data/app_content.dart';
import '../../core/widgets/pattern_page.dart';
import '../../core/widgets/premium_ui.dart';
import '../book/book_screen.dart';
import '../contact/contact_screen.dart';
import '../services/service_detail_screen.dart';
import '../welcome/welcome_screen.dart';

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  String _query = '';

  List<_Hit> get _hits {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _Hit.shortcuts;
    return [
      ..._Hit.shortcuts.where((h) => h.matches(q)),
      for (final service in AppContent.services)
        if (service.title.toLowerCase().contains(q) ||
            service.tagline.toLowerCase().contains(q))
          _Hit(
            title: service.title,
            subtitle: service.tagline,
            icon: service.icon,
            page: ServiceDetailScreen(service: service),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hits = _hits;
    return PatternPage(
      breadcrumb: 'Home > Search',
      title: 'Search',
      titleSize: 18,
      subtitle: 'BOOK · SERVICES · CONTACT',
      scrollBody: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: PatternPage.body(size: 13),
            cursorColor: PatternPage.blue,
            decoration: InputDecoration(
              hintText: 'Search trips, services, and support',
              hintStyle: PatternPage.body(size: 13, color: PatternPage.muted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: PatternPage.muted,
              ),
              filled: true,
              fillColor: const Color(0xFF121212),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PatternPage.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PatternPage.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PatternPage.blue),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: hits.isEmpty
                ? Text(
                    'No matches for “$_query”.',
                    style: PatternPage.body(
                      size: 13,
                      color: PatternPage.muted,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: hits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final hit = hits[index];
                      return Material(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            final page = hit.title == 'Book a trip' &&
                                    !AuthService.isSignedIn
                                ? const WelcomeScreen()
                                : hit.page;
                            Navigator.of(context).push(premiumRoute(page));
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: PatternPage.blue.withValues(
                                      alpha: 0.22,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    hit.icon,
                                    color: PatternPage.blue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hit.title,
                                        style: PatternPage.panchang(
                                          size: 13,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hit.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: PatternPage.body(
                                          size: 11.5,
                                          color: PatternPage.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: PatternPage.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Hit {
  const _Hit({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;

  bool matches(String q) =>
      title.toLowerCase().contains(q) || subtitle.toLowerCase().contains(q);

  static final shortcuts = <_Hit>[
    _Hit(
      title: 'Book a trip',
      subtitle: 'Choose route, date, and cabin',
      icon: Icons.flight_takeoff_outlined,
      page: const BookScreen(),
    ),
    const _Hit(
      title: 'Contact',
      subtitle: 'Ground desk, offices, and enquiry',
      icon: Icons.support_agent_outlined,
      page: ContactScreen(),
    ),
  ];
}
