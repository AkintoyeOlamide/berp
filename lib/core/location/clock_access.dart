import 'package:flutter/material.dart';

import '../auth/staff_access.dart';
import '../data/berp_org.dart';
import '../data/clock_sites.dart';
import '../widgets/pattern_page.dart';
import 'clock_fence.dart';

/// Shared clock-in gate: normal staff use GPS fence; super admin picks a mock site.
abstract final class ClockAccess {
  static Future<ClockFenceResult> prepareClockIn(BuildContext context) async {
    final sites = await BerpOrg.activeSites();
    final places = sites.isEmpty ? clockSites : sites;

    if (StaffAccess.role.value.isSuperAdmin) {
      if (!context.mounted) {
        return ClockFenceResult.blocked('Cancelled.');
      }
      final picked = await showModalBottomSheet<ClockSite>(
        context: context,
        backgroundColor: PatternPage.row,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                  const SizedBox(height: 14),
                  Text(
                    'Choose display location',
                    style: PatternPage.body(
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Super Admin can clock in from anywhere. Pick the office that should appear on Live attendance — GPS is not used.',
                    style: PatternPage.body(
                      size: 12,
                      color: PatternPage.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final site in places)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.place_outlined,
                        color: PatternPage.blue,
                      ),
                      title: Text(
                        site.name,
                        style: PatternPage.body(
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Mock pin · ${site.radiusMeters.round()} m radius',
                        style: PatternPage.body(
                          size: 11,
                          color: PatternPage.muted,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(site),
                    ),
                ],
              ),
            ),
          );
        },
      );
      if (picked == null) {
        return ClockFenceResult.blocked('Clock-in cancelled.');
      }
      return ClockFenceResult.allowed(
        picked,
        latitude: picked.latitude,
        longitude: picked.longitude,
      );
    }

    return ClockFence.checkIn(sites: places);
  }
}
