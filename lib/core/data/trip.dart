import 'dart:convert';

import '../data/airport_catalog.dart';

enum TripKind { oneWay, roundTrip, multiLeg }

extension TripKindLabel on TripKind {
  String get label => switch (this) {
        TripKind.oneWay => 'One Way',
        TripKind.roundTrip => 'Round Trip',
        TripKind.multiLeg => 'Multi-leg',
      };
}

class TripSegment {
  const TripSegment({
    required this.originCode,
    required this.originName,
    required this.destCode,
    required this.destName,
    required this.dateTime,
  });

  final String originCode;
  final String originName;
  final String destCode;
  final String destName;
  final DateTime dateTime;

  Map<String, String> toMap() => {
        'originCode': originCode,
        'originName': originName,
        'destCode': destCode,
        'destName': destName,
        'dateTime': dateTime.toIso8601String(),
      };

  factory TripSegment.fromMap(Map<String, dynamic> map) {
    return TripSegment(
      originCode: '${map['originCode'] ?? ''}',
      originName: '${map['originName'] ?? ''}',
      destCode: '${map['destCode'] ?? ''}',
      destName: '${map['destName'] ?? ''}',
      dateTime: DateTime.tryParse('${map['dateTime'] ?? ''}') ?? DateTime.now(),
    );
  }
}

class Trip {
  const Trip({
    required this.id,
    required this.originCode,
    required this.originName,
    required this.destCode,
    required this.destName,
    required this.departLabel,
    required this.arriveLabel,
    required this.dateTime,
    required this.tailNumber,
    required this.aircraftId,
    required this.passengerCount,
    this.kind = TripKind.oneWay,
    this.segments = const [],
    this.isPast = false,
  });

  final String id;
  final String originCode;
  final String originName;
  final String destCode;
  final String destName;
  final String departLabel;
  final String arriveLabel;
  final DateTime dateTime;
  final String tailNumber;
  final String aircraftId;
  final int passengerCount;
  final TripKind kind;
  final List<TripSegment> segments;
  final bool isPast;

  String get routeCodes {
    if (kind == TripKind.roundTrip) {
      return '$originCode → $destCode → $originCode';
    }
    if (segments.length >= 2) {
      final codes = <String>[segments.first.originCode];
      for (final segment in segments) {
        codes.add(segment.destCode);
      }
      return codes.join(' → ');
    }
    return '$originCode → $destCode';
  }

  String get countdownLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final days = day.difference(today).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return '1 Day';
    return '$days Days';
  }

  Map<String, String> toMap() => {
        'id': id,
        'originCode': originCode,
        'originName': originName,
        'destCode': destCode,
        'destName': destName,
        'departLabel': departLabel,
        'arriveLabel': arriveLabel,
        'dateTime': dateTime.toIso8601String(),
        'tailNumber': tailNumber,
        'aircraftId': aircraftId,
        'passengerCount': '$passengerCount',
        'isPast': isPast ? '1' : '0',
        'kind': kind.name,
        'segments': jsonEncode([
          for (final segment in segments) segment.toMap(),
        ]),
      };

  factory Trip.fromMap(Map<String, String> map) {
    final kindName = map['kind'] ?? 'oneWay';
    final kind = TripKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => TripKind.oneWay,
    );
    var segments = const <TripSegment>[];
    final raw = map['segments'];
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        segments = [
          for (final item in decoded)
            if (item is Map)
              TripSegment.fromMap(
                item.map((k, v) => MapEntry(k.toString(), v)),
              ),
        ];
      }
    }

    return Trip(
      id: map['id'] ?? '',
      originCode: map['originCode'] ?? '',
      originName: map['originName'] ?? '',
      destCode: map['destCode'] ?? '',
      destName: map['destName'] ?? '',
      departLabel: map['departLabel'] ?? '',
      arriveLabel: map['arriveLabel'] ?? '',
      dateTime: DateTime.tryParse(map['dateTime'] ?? '') ?? DateTime.now(),
      tailNumber: map['tailNumber'] ?? 'N313JD',
      aircraftId: map['aircraftId'] ?? '',
      passengerCount: int.tryParse(map['passengerCount'] ?? '6') ?? 6,
      kind: kind,
      segments: segments,
      isPast: map['isPast'] == '1',
    );
  }

  static String codeFor(String airportName) {
    final match = AirportCatalog.byCode(airportName);
    if (match != null) return match.code;
    const codes = <String, String>{
      'Teterboro Airport': 'TEB',
      'San Francisco': 'SFO',
      'Los Angeles': 'LAX',
      'Van Nuys': 'VNY',
      'Miami-Opa Locka': 'OPF',
      'Aspen': 'ASE',
      'London Luton': 'LTN',
      'Nice Côte d’Azur': 'NCE',
      'Lagos Murtala Muhammed': 'LOS',
      'Accra Kotoka': 'ACC',
    };
    return codes[airportName] ??
        airportName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .map((p) => p[0])
            .join()
            .toUpperCase();
  }
}
