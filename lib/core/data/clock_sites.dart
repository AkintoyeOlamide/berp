/// Approved clock-in places used when the database list is unavailable.
/// Radius is metres from the pin.
class ClockSite {
  const ClockSite({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 150,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
}

const clockSites = <ClockSite>[
  ClockSite(
    id: 'los_hq_office',
    name: 'LOS HQ OFFICE',
    latitude: 6.5729595,
    longitude: 3.3523593,
    radiusMeters: 150,
  ),
  ClockSite(
    id: 'abv_office',
    name: 'ABV OFFICE',
    latitude: 8.94743,
    longitude: 7.33386,
    radiusMeters: 150,
  ),
  ClockSite(
    id: 'los_crew_house',
    name: 'LOS CREW HOUSE',
    latitude: 6.5695,
    longitude: 3.3755,
    radiusMeters: 150,
  ),
  ClockSite(
    id: 'los_airport_office',
    name: 'LOS AIRPORT OFFICE',
    latitude: 6.5767897,
    longitude: 3.3256025,
    radiusMeters: 150,
  ),
];
