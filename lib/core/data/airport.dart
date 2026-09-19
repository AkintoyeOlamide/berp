class Airport {
  const Airport({
    required this.iata,
    required this.icao,
    required this.name,
    required this.city,
    required this.country,
    required this.iso,
    this.type = 'medium',
  });

  static const unset = Airport(
    iata: '',
    icao: '',
    name: 'Select airport',
    city: '',
    country: '',
    iso: 'NG',
  );

  bool get isSet => iata.isNotEmpty || icao.isNotEmpty;

  final String iata;
  final String icao;
  final String name;
  final String city;
  final String country;
  final String iso;
  final String type;

  String get code => iata.isNotEmpty ? iata : icao;

  /// Quote style, e.g. `DNMM / LOS`.
  String get icaoIata {
    if (icao.isNotEmpty && iata.isNotEmpty && icao != iata) {
      return '$icao / $iata';
    }
    if (icao.isNotEmpty) return icao;
    return iata;
  }

  /// Airport name without a trailing “Airport”.
  String get quoteName {
    final raw = name.trim();
    return raw.replaceFirst(RegExp(r'\s+Airport$', caseSensitive: false), '');
  }

  String get cityLabel {
    if (city.isEmpty) return name;
    final parts = city
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2 &&
        parts.first.toLowerCase() == parts[1].toLowerCase()) {
      return parts.first;
    }
    return parts.isEmpty ? name : parts.first;
  }

  String get label => '$cityLabel ($code)';

  String get searchBlob =>
      '$iata $icao $name $city $country $iso'.toLowerCase();

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      iata: (json['iata'] ?? '').toString(),
      icao: (json['icao'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      iso: (json['iso'] ?? '').toString(),
      type: (json['type'] ?? 'medium').toString(),
    );
  }
}
