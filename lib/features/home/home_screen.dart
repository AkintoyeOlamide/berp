import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_service.dart';
import '../../core/boot.dart';
import '../../core/data/cabin_notifications.dart';
import '../../core/data/local_store.dart';
import '../../core/data/trip.dart';
import '../../core/widgets/app_asset_image.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/premium_ui.dart';
import '../book/book_screen.dart';
import '../briefing/briefing_screen.dart';
import '../contact/contact_screen.dart';
import '../services/services_screen.dart';
import '../trips/trips_screen.dart';
import '../welcome/welcome_screen.dart';
import 'home_search_screen.dart';
import 'notifications_screen.dart';
import 'visitor_home_sections.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _bg = Color(0xFF0A0A0A);
  static const _muted = Color(0xFF8E8E93);
  static const _card = Color(0xFF1A1A1A);
  static const _blue = Color(0xFF1F2D90);
  static const _green = Color(0xFF34C759);
  static const _amber = Color(0xFFFF9F0A);

  StreamSubscription<AuthState>? _authSub;
  List<Trip> _trips = [];

  @override
  void initState() {
    super.initState();
    unawaited(_ready());
  }

  Future<void> _ready() async {
    try {
      await AppBoot.supabase;
    } catch (_) {}
    if (!mounted) return;
    _authSub = AuthService.onAuthStateChange.listen((_) {
      if (!mounted) return;
      setState(() {});
      _loadTrips();
    });
    await _loadTrips();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    try {
      if (!AuthService.isSignedIn) {
        if (mounted) setState(() => _trips = []);
        return;
      }
    } catch (_) {
      if (mounted) setState(() => _trips = []);
      return;
    }
    final trips = await LocalStore.instance.trips();
    if (!mounted) return;
    setState(() => _trips = trips);
  }

  Trip? get _nextTrip {
    final upcoming = _trips.where((t) => !t.isPast).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  String get _greetingName {
    final user = AuthService.currentUser;
    final meta = user?.userMetadata;
    final raw = (meta?['full_name'] ?? meta?['name'])?.toString().trim();
    if (raw != null && raw.isNotEmpty) {
      final parts = raw.split(RegExp(r'\s+'));
      return parts.length > 1 ? parts.last : parts.first;
    }
    final email = user?.email;
    if (email != null && email.contains('@')) {
      final local = email.split('@').first;
      if (local.isNotEmpty) {
        return local[0].toUpperCase() + local.substring(1);
      }
    }
    return AuthService.isSignedIn ? 'Guest' : '';
  }

  void _openWelcome() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const WelcomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _bookTrip() async {
    HapticFeedback.selectionClick();
    if (!AuthService.isSignedIn) {
      _openWelcome();
      return;
    }
    await Navigator.of(context).push(premiumRoute(const BookScreen()));
    await _loadTrips();
  }

  void _open(Widget page) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(premiumRoute(page));
  }

  TextStyle _panchang({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = Colors.white,
    double height = 1.1,
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

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroHeader(
                    greetingName: _greetingName,
                    signedIn: AuthService.isSignedIn,
                    topInset: top,
                    panchang: _panchang,
                    unreadCount: CabinNotice.items.length,
                    onWeather: () => _open(const BriefingScreen()),
                    onMap: () => _open(const ContactScreen()),
                    onSignIn: _openWelcome,
                    onNotifications: () =>
                        _open(const NotificationsScreen()),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SearchBar(
                          body: _body,
                          muted: _muted,
                          onTap: () => _open(const HomeSearchScreen()),
                        ),
                        const SizedBox(height: 14),
                        _QuickActions(
                          panchang: _panchang,
                          onBook: _bookTrip,
                          onFleet: () => _open(const ServicesScreen()),
                          onContact: () => _open(const ContactScreen()),
                        ),
                        const SizedBox(height: 32),
                        if (AuthService.isSignedIn) ...[
                          _BookTripCard(
                            panchang: _panchang,
                            body: _body,
                            muted: _muted,
                            blue: _blue,
                            onBook: _bookTrip,
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Text(
                                'Trip details',
                                style: _panchang(size: 12),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _open(const TripsScreen()),
                                child: Text(
                                  'See All',
                                  style: _body(
                                    size: 10.5,
                                    weight: FontWeight.w500,
                                    color: _muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_nextTrip != null)
                            _MyFlightCard(
                              flight: _OngoingFlight.fromTrip(_nextTrip!),
                              panchang: _panchang,
                              body: _body,
                              onAssist: () => _open(const TripsScreen()),
                              assistLabel: 'View details',
                              blue: _blue,
                              green: _green,
                              amber: _amber,
                              card: _card,
                              muted: _muted,
                            )
                          else
                            _EmptyTripCard(
                              panchang: _panchang,
                              body: _body,
                              muted: _muted,
                              onBook: _bookTrip,
                            ),
                          const SizedBox(height: 36),
                        ],
                        VisitorHomeSections(
                          panchang: _panchang,
                          body: _body,
                          muted: _muted,
                        ),
                        const AppBottomNavSpacer(extra: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(
                currentIndex: AppNavIndex.home,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OngoingFlight {
  const _OngoingFlight({
    required this.tailNumber,
    required this.departCode,
    required this.departName,
    required this.departTime,
    required this.arriveCode,
    required this.arriveName,
    required this.arriveTime,
  });

  factory _OngoingFlight.fromTrip(Trip trip) {
    return _OngoingFlight(
      tailNumber: trip.tailNumber,
      departCode: trip.originCode,
      departName: trip.originName,
      departTime: trip.departLabel,
      arriveCode: trip.destCode,
      arriveName: trip.destName,
      arriveTime: trip.arriveLabel,
    );
  }

  final String tailNumber;
  final String departCode;
  final String departName;
  final String departTime;
  final String arriveCode;
  final String arriveName;
  final String arriveTime;
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.greetingName,
    required this.signedIn,
    required this.topInset,
    required this.panchang,
    required this.unreadCount,
    required this.onWeather,
    required this.onMap,
    required this.onSignIn,
    required this.onNotifications,
  });

  final String greetingName;
  final bool signedIn;
  final double topInset;
  final int unreadCount;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;
  final VoidCallback onWeather;
  final VoidCallback onMap;
  final VoidCallback onSignIn;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300 + topInset,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.55, 0, 0, 0, 0,
              0, 0.55, 0, 0, 0,
              0, 0, 0.62, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: AppAssetImage(
              'assets/images/home/hero_jet.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.1, -0.2),
              maxCacheWidth: 1200,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55000000),
                  Color(0x77000000),
                  Color(0xF20A0A0A),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: topInset + 8,
            right: 14,
            child: Row(
              children: [
                _NotifyBell(
                  count: unreadCount,
                  onTap: onNotifications,
                ),
                const SizedBox(width: 8),
                signedIn
                    ? _UtilityPill(
                        onWeather: onWeather,
                        onMap: onMap,
                      )
                    : _SignInChip(panchang: panchang, onTap: onSignIn),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/splashlogo.png',
                  height: 18,
                  fit: BoxFit.contain,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.flight_takeoff_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Text(
                  greetingName.isEmpty ? 'Welcome' : 'Hello $greetingName',
                  style: panchang(
                    size: 20,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.08,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifyBell extends StatelessWidget {
  const _NotifyBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 18,
              ),
              if (count > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.body,
    required this.muted,
    required this.onTap,
  });

  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: muted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search trips, services, and support',
                  style: body(
                    size: 13,
                    weight: FontWeight.w400,
                    color: muted,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.panchang,
    required this.onBook,
    required this.onFleet,
    required this.onContact,
  });

  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;
  final VoidCallback onBook;
  final VoidCallback onFleet;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            label: 'Book',
            icon: Icons.flight_takeoff_rounded,
            accent: const Color(0xFF1F2D90),
            panchang: panchang,
            onTap: onBook,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickTile(
            label: 'Services',
            icon: Icons.workspace_premium_outlined,
            accent: const Color(0xFF34C759),
            panchang: panchang,
            onTap: onFleet,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickTile(
            label: 'Contact',
            icon: Icons.support_agent_rounded,
            accent: const Color(0xFFFF9F0A),
            panchang: panchang,
            onTap: onContact,
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.label,
    required this.icon,
    required this.accent,
    required this.panchang,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: panchang(
                  size: 10,
                  weight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UtilityPill extends StatelessWidget {
  const _UtilityPill({required this.onWeather, required this.onMap});

  final VoidCallback onWeather;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.42),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onWeather,
              child: const SizedBox(
                width: 32,
                height: 28,
                child: Icon(
                  Icons.cloud_outlined,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            Container(
              width: 12,
              height: 1,
              color: Colors.white.withValues(alpha: 0.22),
            ),
            InkWell(
              onTap: onMap,
              child: const SizedBox(
                width: 32,
                height: 28,
                child: Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInChip extends StatelessWidget {
  const _SignInChip({required this.panchang, required this.onTap});

  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1F2D90),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            'Sign In',
            style: panchang(
              size: 10.5,
              weight: FontWeight.w600,
              color: Colors.white,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookTripCard extends StatelessWidget {
  const _BookTripCard({
    required this.panchang,
    required this.body,
    required this.muted,
    required this.blue,
    required this.onBook,
  });

  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;
  final Color muted;
  final Color blue;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Book a trip',
            style: panchang(
              size: 16,
              weight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose your route, date, and cabin for your next mission.',
            style: body(size: 12, color: muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: onBook,
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Book a trip',
                style: panchang(
                  size: 10,
                  weight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTripCard extends StatelessWidget {
  const _EmptyTripCard({
    required this.panchang,
    required this.body,
    required this.muted,
    required this.onBook,
  });

  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;
  final Color muted;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No trips yet',
            style: panchang(
              size: 14,
              weight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Book your first flight to see route and timing here.',
            style: body(size: 12, color: muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onBook,
            child: Text(
              'Book a trip  >',
              style: body(
                size: 12,
                weight: FontWeight.w600,
                color: const Color(0xFF4D8CFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyFlightCard extends StatelessWidget {
  const _MyFlightCard({
    required this.flight,
    required this.panchang,
    required this.body,
    required this.onAssist,
    this.assistLabel = 'Request Assistance',
    required this.blue,
    required this.green,
    required this.amber,
    required this.card,
    required this.muted,
  });

  final _OngoingFlight flight;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;
  final VoidCallback onAssist;
  final String assistLabel;
  final Color blue;
  final Color green;
  final Color amber;
  final Color card;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.airplanemode_active, color: blue, size: 13),
              const SizedBox(width: 8),
              Text(
                flight.tailNumber,
                style: panchang(
                  size: 10.5,
                  weight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Text(
                'Upcoming',
                style: body(
                  size: 10.5,
                  weight: FontWeight.w500,
                  color: muted,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Endpoint(
                    badgeColor: green,
                    badgeIcon: Icons.north_east_rounded,
                    code: flight.departCode,
                    name: flight.departName,
                    time: flight.departTime,
                    panchang: panchang,
                    body: body,
                    muted: muted,
                    alignEnd: false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.flight_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 14,
                  ),
                ),
                Expanded(
                  child: _Endpoint(
                    badgeColor: amber,
                    badgeIcon: Icons.south_east_rounded,
                    code: flight.arriveCode,
                    name: flight.arriveName,
                    time: flight.arriveTime,
                    panchang: panchang,
                    body: body,
                    muted: muted,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onAssist,
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                assistLabel,
                style: panchang(
                  size: 9.5,
                  weight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.badgeColor,
    required this.badgeIcon,
    required this.code,
    required this.name,
    required this.time,
    required this.panchang,
    required this.body,
    required this.muted,
    required this.alignEnd,
  });

  final Color badgeColor;
  final IconData badgeIcon;
  final String code;
  final String name;
  final String time;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) panchang;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;
  final Color muted;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      children: [
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignEnd) ...[
              _Badge(color: badgeColor, icon: badgeIcon),
              const SizedBox(width: 8),
            ],
            Text(
              code,
              style: panchang(
                size: 13,
                weight: FontWeight.w700,
                color: Colors.white,
                height: 1.05,
                letterSpacing: 0.2,
              ),
            ),
            if (alignEnd) ...[
              const SizedBox(width: 8),
              _Badge(color: badgeColor, icon: badgeIcon),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: body(
            size: 9.5,
            weight: FontWeight.w400,
            color: muted,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: body(
            size: 10.5,
            weight: FontWeight.w500,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 10, color: Colors.white),
    );
  }
}
