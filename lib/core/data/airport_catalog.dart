import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'airport.dart';

List<Airport> _parseAirports(String raw) {
  final list = jsonDecode(raw) as List<dynamic>;
  return [
    for (final item in list)
      if (item is Map<String, dynamic>) Airport.fromJson(item),
  ];
}

abstract final class AirportCatalog {
  static const assetPath = 'assets/data/airports.json';

  static const suggestedCodes = <String>[
    'LOS',
    'ABV',
    'ACC',
    'PHC',
    'KAN',
    'NBO',
    'JNB',
    'CAI',
    'DXB',
    'ADD',
    'LHR',
    'LTN',
    'CDG',
    'NCE',
    'TEB',
    'VNY',
    'LAX',
    'JFK',
    'LAD',
    'ABJ',
    'LFW',
    'COO',
    'DLA',
  ];

  static List<Airport>? _all;
  static Map<String, Airport>? _byCode;
  static Future<List<Airport>>? _loading;

  static const lagos = Airport(
    iata: 'LOS',
    icao: 'DNMM',
    name: 'Murtala Muhammed International Airport',
    city: 'Lagos',
    country: 'Nigeria',
    iso: 'NG',
    type: 'large',
  );

  static const accra = Airport(
    iata: 'ACC',
    icao: 'DGAA',
    name: 'Kotoka International Airport',
    city: 'Accra',
    country: 'Ghana',
    iso: 'GH',
    type: 'large',
  );

  static const abuja = Airport(
    iata: 'ABV',
    icao: 'DNAA',
    name: 'Nnamdi Azikiwe International Airport',
    city: 'Abuja',
    country: 'Nigeria',
    iso: 'NG',
    type: 'large',
  );

  static Future<List<Airport>> warmup() => all();

  static Future<List<Airport>> all() {
    if (_all != null) return Future.value(_all);
    return _loading ??= _load();
  }

  static Future<List<Airport>> _load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final parsed = await compute(_parseAirports, raw);
      _all = parsed;
      _byCode = {};
      for (final airport in parsed) {
        if (airport.iata.isNotEmpty) {
          _byCode![airport.iata.toUpperCase()] = airport;
        }
        if (airport.icao.isNotEmpty) {
          _byCode![airport.icao.toUpperCase()] = airport;
        }
      }
      return parsed;
    } catch (_) {
      _all = const [];
      _byCode = const {};
      _loading = null;
      return _all!;
    }
  }

  static Airport? byCode(String code) => _byCode?[code.toUpperCase()];

  static List<Airport> suggested(List<Airport> all) {
    final map = {for (final a in all) a.code.toUpperCase(): a};
    return [
      for (final code in suggestedCodes)
        if (map[code] != null) map[code]!,
    ];
  }

  static List<Airport> search(List<Airport> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return suggested(all);
    final scored = <(int, Airport)>[];
    for (final airport in all) {
      final code = airport.code.toLowerCase();
      final iata = airport.iata.toLowerCase();
      final icao = airport.icao.toLowerCase();
      final city = airport.cityLabel.toLowerCase();
      final name = airport.name.toLowerCase();
      int score;
      if (iata == q || icao == q || code == q) {
        score = 0;
      } else if (iata.startsWith(q) || code.startsWith(q)) {
        score = 1;
      } else if (city.startsWith(q)) {
        score = 2;
      } else if (name.startsWith(q)) {
        score = 3;
      } else if (airport.searchBlob.contains(q)) {
        score = 4;
      } else {
        continue;
      }
      scored.add((score, airport));
    }
    scored.sort((a, b) {
      final byScore = a.$1.compareTo(b.$1);
      if (byScore != 0) return byScore;
      return a.$2.cityLabel.compareTo(b.$2.cityLabel);
    });
    if (scored.length > 250) {
      return [for (final item in scored.take(250)) item.$2];
    }
    return [for (final item in scored) item.$2];
  }
}
