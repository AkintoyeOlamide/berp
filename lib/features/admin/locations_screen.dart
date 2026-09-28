import 'package:flutter/material.dart';

import '../../core/data/berp_org.dart';
import '../../core/widgets/pattern_page.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  List<OrgClockPlace> _places = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final places = await BerpOrg.locations();
    if (!mounted) return;
    setState(() => _places = places);
  }

  Future<void> _edit([OrgClockPlace? place]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _LocationForm(place: place)),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'More > Locations',
      title: 'Clock-in locations',
      subtitle: '150 METRE DEFAULT',
      actions: [
        IconButton(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ],
      child: _places.isEmpty
          ? Text(
              'No locations yet. Add one, or the Ikeja site stays as the fallback until the database list is available.',
              style: PatternPage.body(size: 13, color: PatternPage.muted, height: 1.4),
            )
          : PatternGroup(
              children: [
                for (final place in _places)
                  PatternListRow(
                    title: place.name,
                    subtitle:
                        '${place.address.isEmpty ? 'No address' : place.address}  ·  ${place.radiusMeters.round()} m  ·  ${place.isActive ? 'Active' : 'Inactive'}',
                    onTap: () => _edit(place),
                  ),
              ],
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
        const SnackBar(content: Text('Name, latitude, and longitude are required.')),
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
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
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

  Widget _field(TextEditingController controller, String hint, {bool number = false}) {
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
