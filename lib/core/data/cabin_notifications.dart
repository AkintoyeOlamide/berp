class CabinNotice {
  const CabinNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.timeLabel,
    required this.iconName,
    required this.colorValue,
  });

  final String id;
  final String title;
  final String body;
  final String kind;
  final String timeLabel;
  final String iconName;
  final int colorValue;

  static const items = <CabinNotice>[
    CabinNotice(
      id: 'trip-change',
      title: 'Trip change',
      body:
          'KSAN arrival is now Est. 1:20 PM. Ground handling has been updated.',
      kind: 'Trip',
      timeLabel: '12m ago',
      iconName: 'flight',
      colorValue: 0xFF1F2D90,
    ),
    CabinNotice(
      id: 'catering',
      title: 'Catering',
      body:
          'Your cabin order is confirmed — crew will serve after climb-out.',
      kind: 'Catering',
      timeLabel: '1h ago',
      iconName: 'restaurant',
      colorValue: 0xFFFF9F0A,
    ),
    CabinNotice(
      id: 'boarding',
      title: 'Boarding',
      body:
          'Boarding begins in 20 minutes at the FBO. Please be at the lobby.',
      kind: 'Boarding',
      timeLabel: 'Just now',
      iconName: 'airline',
      colorValue: 0xFF34C759,
    ),
  ];
}
