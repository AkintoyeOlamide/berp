import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/aviation_news_service.dart';
import '../../core/widgets/pattern_page.dart';

class AviationNewsScreen extends StatefulWidget {
  const AviationNewsScreen({super.key});

  @override
  State<AviationNewsScreen> createState() => _AviationNewsScreenState();
}

class _AviationNewsScreenState extends State<AviationNewsScreen> {
  List<AviationArticle> _articles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await AviationNewsService.load(force: force);
      if (!mounted) return;
      setState(() {
        _articles = items;
        _loading = false;
        if (items.isEmpty) {
          _error = 'No headlines right now. Pull to refresh over wifi.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not reach news feeds.';
      });
    }
  }

  Future<void> _open(AviationArticle article) async {
    final uri = Uri.tryParse(article.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _when(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${local.day}/${local.month}';
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Entertainment > Aviation News',
      title: 'Aviation News',
      titleSize: 18,
      subtitle: 'LIVE BRIEFING',
      scrollBody: false,
      child: RefreshIndicator(
        color: PatternPage.blue,
        onRefresh: () => _load(force: true),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: PatternPage.blue),
              )
            : _articles.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 48),
                      Text(
                        _error ?? 'No stories yet.',
                        style: PatternPage.body(
                          size: 13,
                          color: PatternPage.muted,
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: _articles.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final a = _articles[index];
                      return Material(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => _open(a),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      a.source.toUpperCase(),
                                      style: PatternPage.body(
                                        size: 10,
                                        weight: FontWeight.w500,
                                        color: PatternPage.blue,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _when(a.published),
                                      style: PatternPage.body(
                                        size: 10,
                                        color: PatternPage.muted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  a.title,
                                  style: PatternPage.panchang(
                                    size: 13,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                if (a.summary.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    a.summary,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: PatternPage.body(
                                      size: 12,
                                      color: PatternPage.muted,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
