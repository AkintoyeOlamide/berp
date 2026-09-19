import 'package:flutter/material.dart';

import '../../core/data/cabin_safety_content.dart';
import '../../core/widgets/pattern_page.dart';

class SafetyTipsScreen extends StatefulWidget {
  const SafetyTipsScreen({super.key, this.emergency = false});

  final bool emergency;

  @override
  State<SafetyTipsScreen> createState() => _SafetyTipsScreenState();
}

class _SafetyTipsScreenState extends State<SafetyTipsScreen> {
  late bool _emergency = widget.emergency;

  static const _icons = <String, IconData>{
    'airline_seat_recline_normal': Icons.airline_seat_recline_normal_rounded,
    'accessibility_new': Icons.accessibility_new_rounded,
    'exit_to_app': Icons.exit_to_app_rounded,
    'masks': Icons.masks_outlined,
    'luggage': Icons.luggage_rounded,
    'phone_android': Icons.phone_android_rounded,
    'water_drop': Icons.water_drop_outlined,
    'campaign': Icons.campaign_outlined,
    'directions_run': Icons.directions_run_rounded,
    'dehaze': Icons.dehaze_rounded,
    'pool': Icons.pool_rounded,
    'south': Icons.south_rounded,
    'local_fire_department': Icons.local_fire_department_rounded,
    'medical_services': Icons.medical_services_outlined,
    'security': Icons.security_rounded,
    'flight_land': Icons.flight_land_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final tips = _emergency
        ? CabinSafetyContent.emergency
        : CabinSafetyContent.onboard;

    return PatternPage(
      breadcrumb: 'Entertainment > Safety',
      title: _emergency ? 'Emergency Tips' : 'Onboard Safety',
      titleSize: 18,
      subtitle: _emergency ? 'IF NEEDED' : 'BEFORE TAXI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Seg(
                  label: 'Onboard',
                  selected: !_emergency,
                  onTap: () => setState(() => _emergency = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Seg(
                  label: 'Emergency',
                  selected: _emergency,
                  onTap: () => setState(() => _emergency = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tips.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Material(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _icons[tip.iconName] ?? Icons.info_outline,
                        color: _emergency
                            ? const Color(0xFFFF6B6B)
                            : PatternPage.blue,
                        size: 22,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tip.title,
                        style: PatternPage.panchang(
                          size: 12,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          tip.body,
                          style: PatternPage.body(
                            size: 11,
                            color: PatternPage.muted,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? PatternPage.blue.withValues(alpha: 0.35)
          : const Color(0xFF121212),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? PatternPage.blue.withValues(alpha: 0.55)
                  : PatternPage.divider,
            ),
          ),
          child: Text(
            label,
            style: PatternPage.body(
              size: 12,
              weight: FontWeight.w600,
              color: selected ? Colors.white : PatternPage.muted,
            ),
          ),
        ),
      ),
    );
  }
}
