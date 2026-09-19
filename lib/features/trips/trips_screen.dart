import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_service.dart';
import '../../core/data/local_store.dart';
import '../../core/data/trip.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/premium_ui.dart';
import '../book/book_screen.dart';
import 'sign_in_to_book.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  static const _bg = Color(0xFF0A0A0A);

  bool _upcoming = true;
  List<Trip> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final trips = await LocalStore.instance.trips();
    if (!mounted) return;
    setState(() {
      _trips = trips;
      _loading = false;
    });
  }

  List<Trip> get _visible {
    return _trips.where((t) => _upcoming ? !t.isPast : t.isPast).toList();
  }

  TextStyle _panchang({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = Colors.white,
    double height = 1.1,
  }) {
    return TextStyle(
      fontFamily: 'Panchang',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
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

  Future<void> _book() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(premiumRoute(const BookScreen()));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = AuthService.isSignedIn;
    final trips = _visible;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: ValueListenableBuilder<bool>(
                valueListenable: appNavMinimized,
                builder: (context, minimized, _) {
                  final navHeight = AppBottomNav.totalHeight(
                    context,
                    minimized: minimized,
                  );
                  return Padding(
                    padding: EdgeInsets.fromLTRB(22, 18, 22, navHeight + 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trips',
                          style: _panchang(size: 28, weight: FontWeight.w700),
                        ),
                        if (!signedIn) ...[
                          const SizedBox(height: 8),
                          const Expanded(child: SignInToBookView()),
                        ] else ...[
                          const SizedBox(height: 16),
                          _Segment(
                            upcoming: _upcoming,
                            onChanged: (v) => setState(() => _upcoming = v),
                            panchang: _panchang,
                          ),
                          const SizedBox(height: 22),
                          if (trips.isNotEmpty)
                            Text(
                              'My Flights',
                              style: _panchang(size: 13, weight: FontWeight.w600),
                            ),
                          if (trips.isNotEmpty) const SizedBox(height: 14),
                          Expanded(
                            child: _loading
                                ? const SizedBox.shrink()
                                : trips.isEmpty
                                    ? _EmptyState(
                                        upcoming: _upcoming,
                                        panchang: _panchang,
                                        body: _body,
                                        onBook: _book,
                                      )
                                    : ListView.separated(
                                        itemCount: trips.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 14),
                                        itemBuilder: (context, index) {
                                          return _TripCard(
                                            trip: trips[index],
                                            panchang: _panchang,
                                            body: _body,
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
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
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.upcoming,
    required this.onChanged,
    required this.panchang,
  });

  final bool upcoming;
  final ValueChanged<bool> onChanged;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) panchang;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _seg('Upcoming', upcoming, () => onChanged(true)),
          _seg('Past', !upcoming, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2A2A2C) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: panchang(
              size: 10.5,
              weight: FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.upcoming,
    required this.panchang,
    required this.body,
    required this.onBook,
  });

  final bool upcoming;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) panchang;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flight_takeoff_rounded,
            size: 54,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 18),
          Text(
            upcoming ? 'Book your first\nflight' : 'No past\nflights',
            textAlign: TextAlign.center,
            style: panchang(size: 22, weight: FontWeight.w700),
          ),
          if (upcoming) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: onBook,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2D90),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Book Flight',
                  style: panchang(size: 11, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.panchang,
    required this.body,
  });

  final Trip trip;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) panchang;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(trip.countdownLabel, style: panchang(size: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trip.kind.label,
                  style: body(size: 10, weight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.flight, color: Color(0xFF4D8CFF), size: 14),
              const SizedBox(width: 6),
              Text(
                trip.tailNumber,
                style: body(size: 12, weight: FontWeight.w500),
              ),
            ],
          ),
          if (trip.kind != TripKind.oneWay) ...[
            const SizedBox(height: 8),
            Text(
              trip.routeCodes,
              style: body(size: 11.5, color: const Color(0xFF8E8E93)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.originCode,
                      style: panchang(size: 22, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.originName,
                      style: body(size: 11, color: const Color(0xFF8E8E93)),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.flight_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      trip.destCode,
                      style: panchang(size: 22, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.destName,
                      textAlign: TextAlign.right,
                      style: body(size: 11, color: const Color(0xFF8E8E93)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _TimeChip(
                icon: Icons.north_east_rounded,
                color: const Color(0xFF34C759),
                label: trip.departLabel,
                body: body,
              ),
              const Spacer(),
              _TimeChip(
                icon: Icons.south_east_rounded,
                color: const Color(0xFFFF9F0A),
                label: trip.arriveLabel,
                body: body,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                icon: Icons.groups_rounded,
                label: '${trip.passengerCount} pax',
                color: const Color(0xFF2F6BFF),
              ),
              const SizedBox(width: 14),
              _Stat(
                icon: Icons.event_outlined,
                label: trip.countdownLabel,
                color: const Color(0xFF8E8E93),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String label;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: body(size: 11.5, weight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Panchang',
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
