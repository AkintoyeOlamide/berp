import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AviationArticle {
  const AviationArticle({
    required this.title,
    required this.source,
    required this.url,
    this.summary = '',
    this.published,
  });

  final String title;
  final String source;
  final String url;
  final String summary;
  final DateTime? published;

  Map<String, String> toMap() => {
        'title': title,
        'source': source,
        'url': url,
        'summary': summary,
        'published': published?.toIso8601String() ?? '',
      };

  factory AviationArticle.fromMap(Map<String, dynamic> map) {
    final published = map['published']?.toString();
    return AviationArticle(
      title: map['title']?.toString() ?? '',
      source: map['source']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
      published: published == null || published.isEmpty
          ? null
          : DateTime.tryParse(published),
    );
  }
}

/// Pulls latest aviation headlines from public RSS feeds (no API key).
abstract final class AviationNewsService {
  static const _cacheKey = 'aviation_news_cache';
  static const _cacheAtKey = 'aviation_news_cache_at';
  static const _ttl = Duration(minutes: 25);

  static const _feeds = <String, String>{
    'Google News':
        'https://news.google.com/rss/search?q=aviation+OR+airline+OR+aircraft&hl=en-US&gl=US&ceid=US:en',
    'Simple Flying': 'https://simpleflying.com/feed/',
    'AvWeb': 'https://www.avweb.com/feed/',
    'FAA': 'https://www.faa.gov/newsroom/rss',
    'NASA Aero': 'https://www.nasa.gov/blogs/aeronautics/feed/',
  };

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (compatible; VMOAero/1.0; +https://vmoaero.app) AppleWebKit/537.36',
    'Accept': 'application/rss+xml, application/xml, text/xml, */*',
  };

  static Future<List<AviationArticle>> load({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedAt = DateTime.tryParse(prefs.getString(_cacheAtKey) ?? '');
    final raw = prefs.getString(_cacheKey);
    if (!force &&
        raw != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _ttl) {
      return _decode(raw);
    }

    final results = await Future.wait(
      _feeds.entries.map((e) => _fetchFeed(e.key, e.value)),
    );
    final seen = <String>{};
    final merged = <AviationArticle>[];
    for (final list in results) {
      for (final article in list) {
        final key = article.title.toLowerCase();
        if (key.isEmpty || !seen.add(key)) continue;
        merged.add(article);
      }
    }
    merged.sort((a, b) {
      final da = a.published ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.published ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    final top = merged.take(40).toList();
    if (top.isNotEmpty) {
      await prefs.setString(_cacheKey, jsonEncode(top.map((e) => e.toMap()).toList()));
      await prefs.setString(_cacheAtKey, DateTime.now().toIso8601String());
      return top;
    }
    if (raw != null) return _decode(raw);
    return const [];
  }

  static List<AviationArticle> _decode(String raw) {
    final list = (jsonDecode(raw) as List<dynamic>).cast<Map<dynamic, dynamic>>();
    return list
        .map((m) => AviationArticle.fromMap(m.map((k, v) => MapEntry('$k', v))))
        .toList();
  }

  static Future<List<AviationArticle>> _fetchFeed(
    String source,
    String url,
  ) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      return _parseRss(res.body, fallbackSource: source);
    } catch (_) {
      return const [];
    }
  }

  static List<AviationArticle> _parseRss(
    String xml, {
    required String fallbackSource,
  }) {
    final items = RegExp(
      r'<item\b[\s\S]*?</item>|<entry\b[\s\S]*?</entry>',
      caseSensitive: false,
    ).allMatches(xml);
    final out = <AviationArticle>[];
    for (final m in items) {
      final block = m.group(0) ?? '';
      final title = _unescape(_tag(block, 'title'));
      if (title.isEmpty) continue;
      var link = _tag(block, 'link');
      if (link.isEmpty) {
        link = RegExp(
              r'<link[^>]+href="([^"]+)"',
              caseSensitive: false,
            ).firstMatch(block)?.group(1) ??
            '';
      }
      final desc = _stripHtml(_unescape(_tag(block, 'description')))
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final source = _tag(block, 'source');
      final dateRaw = _tag(block, 'pubDate').isNotEmpty
          ? _tag(block, 'pubDate')
          : _tag(block, 'updated').isNotEmpty
              ? _tag(block, 'updated')
              : _tag(block, 'published');
      out.add(
        AviationArticle(
          title: title,
          source: source.isEmpty ? fallbackSource : source,
          url: link,
          summary: desc.length > 180 ? '${desc.substring(0, 177)}…' : desc,
          published: _parseDate(dateRaw),
        ),
      );
    }
    return out;
  }

  static String _tag(String xml, String name) {
    final cdata = RegExp(
      '<$name\\b[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]></$name>',
      caseSensitive: false,
    ).firstMatch(xml)?.group(1);
    if (cdata != null) return cdata.trim();
    return RegExp(
          '<$name\\b[^>]*>([\\s\\S]*?)</$name>',
          caseSensitive: false,
        ).firstMatch(xml)?.group(1)?.trim() ??
        '';
  }

  static String _unescape(String s) {
    var out = s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
    out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final n = int.tryParse(m.group(1) ?? '');
      return n == null ? m.group(0)! : String.fromCharCode(n);
    });
    return out;
  }

  static String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>'), ' ').trim();

  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw) ?? _parseRfc822(raw);
  }

  static DateTime? _parseRfc822(String raw) {
    try {
      final cleaned = raw.replaceAll(RegExp(r'^[A-Za-z]{3},\s+'), '');
      const months = {
        'Jan': '01',
        'Feb': '02',
        'Mar': '03',
        'Apr': '04',
        'May': '05',
        'Jun': '06',
        'Jul': '07',
        'Aug': '08',
        'Sep': '09',
        'Oct': '10',
        'Nov': '11',
        'Dec': '12',
      };
      final m = RegExp(
        r'(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2})(?::(\d{2}))?',
      ).firstMatch(cleaned);
      if (m == null) return null;
      final month = months[m.group(2)] ?? '01';
      final day = m.group(1)!.padLeft(2, '0');
      final sec = m.group(6) ?? '00';
      return DateTime.parse('${m.group(3)}-$month-${day}T${m.group(4)}:${m.group(5)}:$sec');
    } catch (_) {
      return null;
    }
  }
}
