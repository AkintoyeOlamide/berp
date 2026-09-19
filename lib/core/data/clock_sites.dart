/// Approved clock-in places. Replace or add pins as needed.
/// Radius is metres from the pin.
class ClockSite {
  const ClockSite({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 120,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
}

const clockSites = <ClockSite>[
  ClockSite(
    id: 'oduduwa_47a',
    name: '47a Oduduwa Crescent — Ikeja GRA',
    latitude: 6.5729595,
    longitude: 3.3523593,
    radiusMeters: 150,
  ),
];
