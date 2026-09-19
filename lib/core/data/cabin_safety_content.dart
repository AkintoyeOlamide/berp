class SafetyTip {
  const SafetyTip({
    required this.title,
    required this.body,
    required this.iconName,
  });

  final String title;
  final String body;
  final String iconName;
}

abstract final class CabinSafetyContent {
  static const onboard = <SafetyTip>[
    SafetyTip(
      title: 'Seat belt',
      body:
          'Keep your belt fastened whenever you are seated. Turbulence can hit without warning, even in clear air.',
      iconName: 'airline_seat_recline_normal',
    ),
    SafetyTip(
      title: 'Brace position',
      body:
          'On command, lean forward, head against the seat in front, hands over your head or holding the seatback. Feet flat on the floor.',
      iconName: 'accessibility_new',
    ),
    SafetyTip(
      title: 'Exits & lights',
      body:
          'Count the rows to the nearest two exits after you sit. Floor-path lights lead to exits if the cabin is dark or smoky.',
      iconName: 'exit_to_app',
    ),
    SafetyTip(
      title: 'Oxygen masks',
      body:
          'If masks drop, pull yours on first, then help others. The bag may not inflate — oxygen still flows.',
      iconName: 'masks',
    ),
    SafetyTip(
      title: 'Cabin baggage',
      body:
          'Stow bags fully in the bin or under the seat. Nothing in the aisle. Heavier items go under the seat so bins stay latched.',
      iconName: 'luggage',
    ),
    SafetyTip(
      title: 'Electronics',
      body:
          'Follow crew calls for airplane mode and large-device stowage on taxi, takeoff, and landing.',
      iconName: 'phone_android',
    ),
    SafetyTip(
      title: 'Hydration & movement',
      body:
          'Cabin air is dry. Drink water, limit alcohol, and flex ankles on longer sectors to stay sharp on arrival.',
      iconName: 'water_drop',
    ),
    SafetyTip(
      title: 'Listen to crew',
      body:
          'Crew briefings override habit. If instructions change, follow the latest call from the cabin team.',
      iconName: 'campaign',
    ),
  ];

  static const emergency = <SafetyTip>[
    SafetyTip(
      title: 'Leave it',
      body:
          'In an evacuation, leave bags. Seconds matter. Move to the exit, then away from the aircraft.',
      iconName: 'directions_run',
    ),
    SafetyTip(
      title: 'Smoke in cabin',
      body:
          'Stay low, cover nose and mouth with cloth, follow floor lights. Do not open overhead bins.',
      iconName: 'dehaze',
    ),
    SafetyTip(
      title: 'Ditching',
      body:
          'Life vest is under or beside your seat. Put it on, but inflate only after you leave the aircraft unless crew say otherwise.',
      iconName: 'pool',
    ),
    SafetyTip(
      title: 'Slide use',
      body:
          'Jump feet first, arms crossed, then move clear so the next person can follow. Do not sit at the bottom of the slide.',
      iconName: 'south',
    ),
    SafetyTip(
      title: 'Fire / heat',
      body:
          'Do not open a hot door. Crew will choose a usable exit. If you see fire outside a window, tell crew immediately.',
      iconName: 'local_fire_department',
    ),
    SafetyTip(
      title: 'Medical event',
      body:
          'Alert crew first. They have kits, oxygen, and ground medical link. Do not crowd the aisle.',
      iconName: 'medical_services',
    ),
    SafetyTip(
      title: 'Security threat',
      body:
          'Stay seated unless crew move you. Report unusual behaviour quietly to crew. Follow their instructions exactly.',
      iconName: 'security',
    ),
    SafetyTip(
      title: 'After landing hard',
      body:
          'Wait for the “evacuate” or “remain seated” call. Unbuckle only when told. Help those next to you if you can do so safely.',
      iconName: 'flight_land',
    ),
  ];
}
