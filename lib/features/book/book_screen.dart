import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_service.dart';
import '../../core/data/airport.dart';
import '../../core/data/airport_catalog.dart';
import '../../core/data/local_store.dart';
import '../../core/data/trip.dart';
import '../../core/widgets/app_asset_image.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/premium_ui.dart';
import '../catering/catering_screen.dart';
import '../trips/sign_in_to_book.dart';
import 'airport_picker_sheet.dart';

class _DraftLeg {
  _DraftLeg({
    required this.origin,
    required this.destination,
    this.depart,
  });

  Airport origin;
  Airport destination;
  DateTime? depart;
}

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  static const _bg = Color(0xFF0A0A0A);
  static const _sheet = Color(0xFF121212);
  static const _muted = Color(0xFF8E8E93);
  static const _blue = Color(0xFF1F2D90);

  TripKind _tripType = TripKind.oneWay;
  late List<_DraftLeg> _legs;
  int? _passengers;
  bool _cateringSelected = false;

  @override
  void initState() {
    super.initState();
    AirportCatalog.all();
    _legs = [
      _DraftLeg(
        origin: AirportCatalog.lagos,
        destination: AirportCatalog.accra,
      ),
    ];
  }

  TextStyle _panchang({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = Colors.white,
    double height = 1.15,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: 'Panchang',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle _body({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double height = 1.3,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  void _syncReturnLeg() {
    if (_tripType != TripKind.roundTrip || _legs.isEmpty) return;
    final outbound = _legs.first;
    if (_legs.length == 1) {
      _legs.add(
        _DraftLeg(
          origin: outbound.destination,
          destination: outbound.origin,
        ),
      );
    } else {
      _legs[1].origin = outbound.destination;
      _legs[1].destination = outbound.origin;
      _legs = _legs.take(2).toList();
    }
  }

  void _applyTripKind(TripKind kind) {
    setState(() {
      _tripType = kind;
      final first = _legs.first;
      if (kind == TripKind.oneWay) {
        _legs = [_DraftLeg(
          origin: first.origin,
          destination: first.destination,
          depart: first.depart,
        )];
      } else if (kind == TripKind.roundTrip) {
        _legs = [
          _DraftLeg(
            origin: first.origin,
            destination: first.destination,
            depart: first.depart,
          ),
          _DraftLeg(
            origin: first.destination,
            destination: first.origin,
            depart: _legs.length > 1 ? _legs[1].depart : null,
          ),
        ];
      } else {
        if (_legs.length < 2) {
          final nextDest = first.destination.code == AirportCatalog.abuja.code
              ? AirportCatalog.accra
              : AirportCatalog.abuja;
          _legs = [
            first,
            _DraftLeg(
              origin: first.destination,
              destination: nextDest.code == first.destination.code
                  ? AirportCatalog.lagos
                  : nextDest,
            ),
          ];
        }
      }
    });
  }

  Future<void> _pickAirport({
    required int legIndex,
    required bool origin,
  }) async {
    final leg = _legs[legIndex];
    final result = await showAirportPicker(
      context: context,
      title: origin ? 'Select origin' : 'Select destination',
      selected: origin ? leg.origin : leg.destination,
      exclude: origin ? leg.destination : leg.origin,
    );
    if (result == null) return;
    setState(() {
      if (origin) {
        leg.origin = result;
      } else {
        leg.destination = result;
        if (_tripType == TripKind.multiLeg &&
            legIndex + 1 < _legs.length) {
          _legs[legIndex + 1].origin = result;
        }
      }
      if (_tripType == TripKind.roundTrip) _syncReturnLeg();
    });
  }

  Future<void> _pickDateTime(int legIndex) async {
    final now = DateTime.now();
    final current = _legs[legIndex].depart;
    DateTime min = now;
    if (legIndex > 0 && _legs[legIndex - 1].depart != null) {
      min = _legs[legIndex - 1].depart!;
    }
    final minDay = DateTime(min.year, min.month, min.day);
    var initial = current ?? minDay.add(const Duration(days: 1));
    if (initial.isBefore(minDay)) initial = minDay;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDay,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _blue,
              surface: _sheet,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        current ?? DateTime(date.year, date.month, date.day, 10, 0),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _blue,
              surface: _sheet,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;

    setState(() {
      _legs[legIndex].depart = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickPassengers() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Total passengers', style: _panchang(size: 16)),
                ),
              ),
              ...List.generate(12, (i) {
                final n = i + 1;
                return ListTile(
                  title: Text(
                    '$n passenger${n == 1 ? '' : 's'}',
                    style: _body(size: 14.5),
                  ),
                  onTap: () => Navigator.pop(context, n),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (result != null) setState(() => _passengers = result);
  }

  Future<void> _openCatering() async {
    await Navigator.of(context).push(premiumRoute(const CateringScreen()));
    if (!mounted) return;
    setState(() => _cateringSelected = true);
  }

  void _addLeg() {
    if (_legs.length >= 6) return;
    final last = _legs.last;
    var nextDest = AirportCatalog.abuja;
    if (nextDest.code == last.destination.code) {
      nextDest = AirportCatalog.accra;
    }
    if (nextDest.code == last.destination.code) {
      nextDest = AirportCatalog.lagos;
    }
    setState(() {
      _legs.add(
        _DraftLeg(origin: last.destination, destination: nextDest),
      );
    });
  }

  void _removeLeg(int index) {
    if (_legs.length <= 2) return;
    setState(() {
      _legs.removeAt(index);
      for (var i = 1; i < _legs.length; i++) {
        _legs[i].origin = _legs[i - 1].destination;
      }
    });
  }

  Future<void> _continue() async {
    for (var i = 0; i < _legs.length; i++) {
      final leg = _legs[i];
      if (leg.origin.code == leg.destination.code) {
        _toast('Each leg needs different airports.');
        return;
      }
      if (leg.depart == null) {
        final label = switch (_tripType) {
          TripKind.roundTrip when i == 0 => 'Select an outbound date.',
          TripKind.roundTrip => 'Select a return date.',
          TripKind.multiLeg => 'Select a date for leg ${i + 1}.',
          TripKind.oneWay => 'Select a date & time.',
        };
        _toast(label);
        return;
      }
    }
    if (_tripType == TripKind.roundTrip &&
        _legs[1].depart!.isBefore(_legs[0].depart!)) {
      _toast('Return must be after the outbound flight.');
      return;
    }
    if (_passengers == null) {
      _toast('Select total passengers.');
      return;
    }

    final first = _legs.first;
    final last = _legs.last;
    final asked = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: _sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Request a quote', style: _panchang(size: 18)),
                const SizedBox(height: 8),
                Text(
                  'We will send a charter quote for this trip. No payment is taken now.',
                  style: _body(
                    size: 13,
                    color: const Color(0xFF8E8E93),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_tripType.label}  ·  ${_legs.first.origin.code} → ${_legs.last.destination.code}',
                  style: _body(size: 13.5, weight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_passengers passenger${_passengers == 1 ? '' : 's'}'
                  '${_cateringSelected ? '  ·  Catering' : ''}',
                  style: _body(size: 12.5, color: const Color(0xFF8E8E93)),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Request a Quote',
                      style: _panchang(size: 11, weight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Not yet',
                      style: _body(
                        size: 13,
                        weight: FontWeight.w500,
                        color: const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (asked != true || !mounted) return;

    HapticFeedback.mediumImpact();
    final dt = first.depart!;
    final segments = [
      for (final leg in _legs)
        TripSegment(
          originCode: leg.origin.code,
          originName: leg.origin.name,
          destCode: leg.destination.code,
          destName: leg.destination.name,
          dateTime: leg.depart!,
        ),
    ];
    final arrive = _tripType == TripKind.roundTrip
        ? 'Return ${_timeLabel(last.depart!)}'
        : 'Arrive Est. ${_timeLabel(last.depart!.add(const Duration(hours: 5)))}';

    await LocalStore.instance.saveTrip(
      Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        originCode: first.origin.code,
        originName: first.origin.name,
        destCode: last.destination.code,
        destName: last.destination.name,
        departLabel: 'Depart ${_timeLabel(dt)}',
        arriveLabel: arrive,
        dateTime: dt,
        tailNumber: 'N313JD',
        aircraftId: '',
        passengerCount: _passengers!,
        kind: _tripType,
        segments: segments,
      ),
    );
    if (!mounted) return;
    _toast('Quote requested');
    Navigator.of(context).pop();
  }

  String _timeLabel(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _body(size: 13.5)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF222222),
      ),
    );
  }

  String get _dateLabel {
    return _formatDate(_legs.first.depart);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select a Date & Time';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month ${dt.day} · $hour:$minute $period';
  }

  List<Widget> _routeFields() {
    if (_tripType == TripKind.roundTrip) {
      final outbound = _legs.first;
      final inbound = _legs[1];
      return [
        Text('Outbound', style: _panchang(size: 10.5, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        _RouteCard(
          origin: outbound.origin.label,
          destination: outbound.destination.label,
          onOrigin: () => _pickAirport(legIndex: 0, origin: true),
          onDestination: () => _pickAirport(legIndex: 0, origin: false),
          body: _body,
        ),
        const SizedBox(height: 12),
        _FieldTile(
          icon: Icons.calendar_today_outlined,
          label: outbound.depart == null
              ? 'Outbound date & time'
              : _formatDate(outbound.depart),
          placeholder: outbound.depart == null,
          trailing: Icons.unfold_more_rounded,
          onTap: () => _pickDateTime(0),
          body: _body,
        ),
        const SizedBox(height: 22),
        Text('Return', style: _panchang(size: 10.5, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        _RouteCard(
          origin: inbound.origin.label,
          destination: inbound.destination.label,
          body: _body,
        ),
        const SizedBox(height: 12),
        _FieldTile(
          icon: Icons.calendar_today_outlined,
          label: inbound.depart == null
              ? 'Return date & time'
              : _formatDate(inbound.depart),
          placeholder: inbound.depart == null,
          trailing: Icons.unfold_more_rounded,
          onTap: () => _pickDateTime(1),
          body: _body,
        ),
      ];
    }

    if (_tripType == TripKind.multiLeg) {
      return [
        for (var i = 0; i < _legs.length; i++) ...[
          if (i > 0) const SizedBox(height: 22),
          Row(
            children: [
              Text(
                'Leg ${i + 1}',
                style: _panchang(size: 10.5, weight: FontWeight.w600),
              ),
              const Spacer(),
              if (_legs.length > 2)
                GestureDetector(
                  onTap: () => _removeLeg(i),
                  child: Text(
                    'Remove',
                    style: _body(size: 11, color: _muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _RouteCard(
            origin: _legs[i].origin.label,
            destination: _legs[i].destination.label,
            onOrigin: i == 0
                ? () => _pickAirport(legIndex: i, origin: true)
                : null,
            onDestination: () => _pickAirport(legIndex: i, origin: false),
            body: _body,
          ),
          const SizedBox(height: 12),
          _FieldTile(
            icon: Icons.calendar_today_outlined,
            label: _legs[i].depart == null
                ? 'Date & time'
                : _formatDate(_legs[i].depart),
            placeholder: _legs[i].depart == null,
            trailing: Icons.unfold_more_rounded,
            onTap: () => _pickDateTime(i),
            body: _body,
          ),
        ],
        const SizedBox(height: 16),
        if (_legs.length < 6)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _addLeg,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Add another leg',
                style: _panchang(size: 10.5, weight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ];
    }

    final leg = _legs.first;
    return [
      _RouteCard(
        origin: leg.origin.label,
        destination: leg.destination.label,
        onOrigin: () => _pickAirport(legIndex: 0, origin: true),
        onDestination: () => _pickAirport(legIndex: 0, origin: false),
        body: _body,
      ),
      const SizedBox(height: 26),
      Text('Date & Time', style: _panchang(size: 10.5, weight: FontWeight.w600)),
      const SizedBox(height: 14),
      _FieldTile(
        icon: Icons.calendar_today_outlined,
        label: _dateLabel,
        placeholder: leg.depart == null,
        trailing: Icons.unfold_more_rounded,
        onTap: () => _pickDateTime(0),
        body: _body,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isSignedIn) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book a trip',
                        style: _panchang(size: 28, weight: FontWeight.w700),
                      ),
                      const Expanded(child: SignInToBookView()),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNav(currentIndex: AppNavIndex.book),
              ),
            ],
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                    child: Text(
                      'Booking',
                      style: _body(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: _muted,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          height: 165,
                          width: double.infinity,
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              0.55, 0, 0, 0, 0,
                              0, 0.55, 0, 0, 0,
                              0, 0, 0.62, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                            child: AppAssetImage(
                              'assets/images/home/why.jpg',
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, -0.2),
                              height: 165,
                              maxCacheWidth: 900,
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 165,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x33000000),
                                Color(0xCC0A0A0A),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        top: 92,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: _sheet,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    22,
                                    20,
                                    22,
                                    16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Book a Trip',
                                              style: _panchang(
                                                size: 20,
                                                weight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          _CloseChip(
                                            onTap: () =>
                                                Navigator.of(context).maybePop(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 22),
                                      _TripKindSelector(
                                        value: _tripType,
                                        onChanged: _applyTripKind,
                                        panchang: _panchang,
                                      ),
                                      const SizedBox(height: 26),
                                      ..._routeFields(),
                                      const SizedBox(height: 26),
                                      Text(
                                        'Passengers',
                                        style: _panchang(
                                          size: 10.5,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      _FieldTile(
                                        icon: Icons.groups_outlined,
                                        label: _passengers == null
                                            ? 'Total Passengers'
                                            : '$_passengers passenger${_passengers == 1 ? '' : 's'}',
                                        placeholder: _passengers == null,
                                        trailing: Icons.unfold_more_rounded,
                                        onTap: _pickPassengers,
                                        body: _body,
                                      ),
                                      const SizedBox(height: 26),
                                      _FieldTile(
                                        icon: null,
                                        label: _cateringSelected
                                            ? 'Catering added'
                                            : 'Catering (Optional)',
                                        placeholder: !_cateringSelected,
                                        trailing: Icons.chevron_right_rounded,
                                        onTap: _openCatering,
                                        body: _body,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: appNavMinimized,
                                builder: (context, minimized, _) {
                                  final navHeight = AppBottomNav.totalHeight(
                                    context,
                                    minimized: minimized,
                                  );
                                  return Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      22,
                                      10,
                                      22,
                                      navHeight + 10,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: FilledButton(
                                        onPressed: _continue,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _blue,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'Request a Quote',
                                          style: _panchang(
                                            size: 10,
                                            weight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(currentIndex: AppNavIndex.book),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseChip extends StatelessWidget {
  const _CloseChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A2A2A),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 30,
          height: 30,
          child: Icon(Icons.close, color: Colors.white, size: 15),
        ),
      ),
    );
  }
}

class _TripKindSelector extends StatelessWidget {
  const _TripKindSelector({
    required this.value,
    required this.onChanged,
    required this.panchang,
  });

  final TripKind value;
  final ValueChanged<TripKind> onChanged;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final kind in TripKind.values)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(kind);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == kind
                        ? const Color(0xFF2A2A2C)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    kind.label,
                    textAlign: TextAlign.center,
                    style: panchang(
                      size: 9.5,
                      weight: FontWeight.w600,
                      color: value == kind
                          ? Colors.white
                          : const Color(0xFF8E8E93),
                      height: 1.1,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.origin,
    required this.destination,
    required this.body,
    this.onOrigin,
    this.onDestination,
  });

  final String origin;
  final String destination;
  final VoidCallback? onOrigin;
  final VoidCallback? onDestination;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _RouteRow(
            icon: Icons.flight_takeoff_rounded,
            label: origin,
            onTap: onOrigin,
            body: body,
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 40,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          _RouteRow(
            icon: Icons.flight_land_rounded,
            label: destination,
            onTap: onDestination,
            body: body,
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.label,
    required this.body,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: body(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.trailing,
    required this.onTap,
    required this.body,
  });

  final IconData? icon;
  final String label;
  final bool placeholder;
  final IconData trailing;
  final VoidCallback onTap;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;

  @override
  Widget build(BuildContext context) {
    final color = placeholder ? const Color(0xFF8E8E93) : Colors.white;
    final style = body(
      size: 12,
      weight: FontWeight.w400,
      color: color,
      height: 1.2,
    );

    return Material(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 11),
              ],
              Expanded(child: Text(label, style: style)),
              Icon(trailing, color: const Color(0xFF8E8E93), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
