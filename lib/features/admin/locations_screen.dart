import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/staff_access.dart';
import '../../core/data/berp_org.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pattern_page.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  List<OrgClockPlace> _places = [];
  bool _loading = true;

  bool get _canManage => StaffAccess.role.value.isOrgAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final places = await BerpOrg.locations();
    if (!mounted) return;
    setState(() {
      _places = places;
      _loading = false;
    });
  }

  Future<void> _edit([OrgClockPlace? place]) async {
    if (!_canManage) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _LocationForm(place: place)),
    );
    if (saved == true) await _load();
  }

  Future<void> _toggleActive(OrgClockPlace place) async {
    if (!_canManage) return;
    await BerpOrg.setLocationActive(place.id, !place.isActive);
    await _load();
  }

  Future<void> _openMap(OrgClockPlace place) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final active = _places.where((place) => place.isActive).length;
    return PatternPage(
      breadcrumb: 'More > Locations',
      title: 'Clock-in locations',
      subtitle: _loading
          ? 'LOADING'
          : '$active ACTIVE  ·  ${_places.length} TOTAL',
      actions: [
        if (_canManage)
          IconButton(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
          ),
      ],
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : _places.isEmpty
          ? Text(
              'No locations in the database yet. Run 031_clock_offices.sql, or the app will use the four built-in offices until then.',
              style: PatternPage.body(
                size: 13,
                color: PatternPage.muted,
                height: 1.4,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff can clock in within 150 metres of any active office.',
                  style: PatternPage.body(
                    size: 12,
                    color: PatternPage.muted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                for (final place in _places) ...[
                  _LocationCard(
                    place: place,
                    canManage: _canManage,
                    onOpen: () => _openMap(place),
                    onEdit: () => _edit(place),
                    onToggle: () => _toggleActive(place),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.place,
    required this.canManage,
    required this.onOpen,
    required this.onEdit,
    required this.onToggle,
  });

  final OrgClockPlace place;
  final bool canManage;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PatternPage.row,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: canManage ? onEdit : onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      place.name,
                      style: PatternPage.body(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (place.isActive ? AppColors.green : AppColors.orange)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      place.isActive ? 'Active' : 'Inactive',
                      style: PatternPage.body(
                        size: 10,
                        weight: FontWeight.w700,
                        color: place.isActive
                            ? AppColors.green
                            : AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                place.address.isEmpty ? 'No address' : place.address,
                style: PatternPage.body(
                  size: 12,
                  color: PatternPage.muted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}  ·  ${place.radiusMeters.round()} m radius',
                style: PatternPage.body(size: 11, color: PatternPage.muted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed: onOpen,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Open map',
                      style: PatternPage.body(
                        size: 12,
                        color: AppColors.secondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: onToggle,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        place.isActive ? 'Deactivate' : 'Activate',
                        style: PatternPage.body(
                          size: 12,
                          color: place.isActive
                              ? AppColors.orange
                              : AppColors.green,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationForm extends StatefulWidget {
  const _LocationForm({this.place});

  final OrgClockPlace? place;

  @override
  State<_LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<_LocationForm> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _radius;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final place = widget.place;
    _name = TextEditingController(text: place?.name ?? '');
    _address = TextEditingController(text: place?.address ?? '');
    _lat = TextEditingController(text: place == null ? '' : '${place.latitude}');
    _lng = TextEditingController(text: place == null ? '' : '${place.longitude}');
    _radius = TextEditingController(
      text: '${place?.radiusMeters.round() ?? 150}',
    );
    _active = place?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _radius.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    final radius = double.tryParse(_radius.text.trim()) ?? 150;
    if (_name.text.trim().isEmpty || lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name, latitude, and longitude are required.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await BerpOrg.saveLocation(
        id: widget.place?.id,
        name: _name.text.trim(),
        address: _address.text.trim(),
        latitude: lat,
        longitude: lng,
        radiusMeters: radius,
        isActive: _active,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Locations > Edit',
      title: widget.place == null ? 'Add location' : 'Edit location',
      child: Column(
        children: [
          _field(_name, 'Name'),
          const SizedBox(height: 10),
          _field(_address, 'Address'),
          const SizedBox(height: 10),
          _field(_lat, 'Latitude', number: true),
          const SizedBox(height: 10),
          _field(_lng, 'Longitude', number: true),
          const SizedBox(height: 10),
          _field(_radius, 'Radius in metres', number: true),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Active', style: PatternPage.body(size: 14)),
            value: _active,
            activeThumbColor: PatternPage.blue,
            onChanged: (value) => setState(() => _active = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _saving ? 'Saving' : 'Save location',
                style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    bool number = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      style: PatternPage.body(size: 13),
      cursorColor: PatternPage.blue,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: PatternPage.body(size: 13, color: PatternPage.muted),
        filled: true,
        fillColor: PatternPage.row,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PatternPage.divider),
        ),
      ),
    );
  }
}
