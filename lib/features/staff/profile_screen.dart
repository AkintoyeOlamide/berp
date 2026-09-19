import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/berp_cloud.dart';
import '../../core/data/staff_profile.dart';
import '../../core/data/staff_store.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StaffProfile? _profile;
  bool _loading = true;
  bool _editing = true;
  bool _saving = false;
  String? _error;

  final _name = TextEditingController();
  final _department = TextEditingController();
  final _designation = TextEditingController();
  String _company = StaffProfile.companies.first;
  late int _joinedYear;
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    _joinedYear = DateTime.now().year;
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _department.dispose();
    _designation.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await BerpCloud.fetchProfile();
      if (!mounted) return;
      _apply(profile);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
        _editing = true;
      });
    }
  }

  void _apply(StaffProfile? profile) {
    final fallback = StaffProfile(
      id: StaffIdentity.userId,
      fullName: StaffIdentity.name,
      email: StaffIdentity.email,
    );
    final next = profile ?? fallback;
    _name.text = next.fullName;
    _department.text = next.department;
    _designation.text = next.designation;
    _company = StaffProfile.companies.contains(next.company)
        ? next.company
        : StaffProfile.companies.first;
    _joinedYear = next.joinedYear ?? DateTime.now().year;
    _photoBytes = null;
    setState(() {
      _profile = next;
      _loading = false;
      _editing = !next.isComplete;
    });
  }

  List<int> get _years {
    final now = DateTime.now().year;
    return [for (var year = now; year >= 1990; year--) year];
  }

  Future<void> _save() async {
    final current = _profile;
    if (current == null || _saving) return;
    final next = current.copyWith(
      fullName: _name.text.trim(),
      department: _department.text.trim(),
      company: _company,
      designation: _designation.text.trim(),
      joinedYear: _joinedYear,
    );
    final hasPhoto = _photoBytes != null || next.avatarUrl.isNotEmpty;
    if (next.fullName.isEmpty ||
        next.department.isEmpty ||
        !StaffProfile.companies.contains(next.company) ||
        next.designation.isEmpty ||
        next.joinedYear == null ||
        !hasPhoto) {
      setState(() => _error = 'Fill in every field and add a profile photo.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await BerpCloud.saveProfile(
        next,
        photoBytes: _photoBytes,
      );
      if (!mounted) return;
      if (saved == null) {
        setState(() {
          _saving = false;
          _error = 'Sign in to save your profile.';
        });
        return;
      }
      _apply(saved);
      setState(() => _saving = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  InputDecoration _field(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: PatternPage.body(size: 13, color: PatternPage.muted),
      filled: true,
      fillColor: const Color(0xFF121212),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PatternPage.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PatternPage.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PatternPage.blue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Profile',
      title: 'Profile',
      subtitle: _editing ? 'SAVE TO YOUR STAFF RECORD' : 'YOUR STAFF RECORD',
      bottom: const AppBottomNav(currentIndex: AppNavIndex.settings),
      child: _loading
          ? Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: CircularProgressIndicator(color: PatternPage.blue),
              ),
            )
          : _editing
              ? _form()
              : _details(),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) ...[
          Text(
            _error!,
            style: PatternPage.body(size: 12, color: const Color(0xFFFF453A)),
          ),
          const SizedBox(height: 16),
        ],
        Center(child: _photoButton()),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap to add a profile photo',
            style: PatternPage.body(size: 12, color: PatternPage.muted),
          ),
        ),
        const SizedBox(height: 22),
        const PatternSectionLabel('Full name'),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          style: PatternPage.body(size: 14),
          cursorColor: PatternPage.blue,
          decoration: _field('Your name'),
        ),
        const SizedBox(height: 22),
        const PatternSectionLabel('Company'),
        const SizedBox(height: 8),
        PatternGroup(
          children: [
            for (final company in StaffProfile.companies)
              PatternListRow(
                title: company,
                selected: _company == company,
                onTap: () => setState(() => _company = company),
              ),
          ],
        ),
        const SizedBox(height: 22),
        const PatternSectionLabel('Department'),
        const SizedBox(height: 8),
        TextField(
          controller: _department,
          textCapitalization: TextCapitalization.words,
          style: PatternPage.body(size: 14),
          cursorColor: PatternPage.blue,
          decoration: _field('HR, Maintenance, Operations…'),
        ),
        const SizedBox(height: 22),
        const PatternSectionLabel('Designation'),
        const SizedBox(height: 8),
        TextField(
          controller: _designation,
          textCapitalization: TextCapitalization.words,
          style: PatternPage.body(size: 14),
          cursorColor: PatternPage.blue,
          decoration: _field('Job title'),
        ),
        const SizedBox(height: 22),
        const PatternSectionLabel('Year joined'),
        const SizedBox(height: 8),
        PatternGroup(
          children: [
            PatternListRow(
              title: '$_joinedYear',
              subtitle: 'Tap to change',
              onTap: _pickYear,
            ),
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: PatternPage.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: PatternPage.blue.withValues(alpha: 0.4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _saving ? 'Saving…' : 'Save profile',
              style: PatternPage.panchang(size: 12, weight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoButton() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: _avatar(size: 96, editing: true),
    );
  }

  Widget _avatar({required double size, bool editing = false}) {
    final photo = _photoBytes;
    final url = _profile?.avatarUrl ?? '';
    ImageProvider? image;
    if (photo != null) {
      image = MemoryImage(photo);
    } else if (url.isNotEmpty) {
      image = NetworkImage(url);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: const Color(0xFF1A1A1A),
          backgroundImage: image,
          child: image == null
              ? Icon(
                  Icons.person_rounded,
                  size: size * 0.46,
                  color: PatternPage.muted,
                )
              : null,
        ),
        if (editing)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: PatternPage.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    HapticFeedback.selectionClick();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: Colors.white),
                  title: Text('Photo library', style: PatternPage.body(size: 15)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.photo_camera_outlined, color: Colors.white),
                  title: Text('Camera', style: PatternPage.body(size: 15)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _photoBytes = bytes);
  }

  Future<void> _pickYear() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 360,
            child: ListView(
              children: [
                for (final year in _years)
                  ListTile(
                    title: Text(
                      '$year',
                      style: PatternPage.body(size: 15),
                    ),
                    trailing: year == _joinedYear
                        ? const Icon(Icons.check, color: Color(0xFF1F2D90))
                        : null,
                    onTap: () => Navigator.pop(context, year),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() => _joinedYear = picked);
  }

  Widget _details() {
    final profile = _profile;
    if (profile == null) return const SizedBox.shrink();
    final rows = [
      ('Name', profile.fullName),
      ('Email', profile.email),
      ('Company', profile.company),
      ('Department', profile.department),
      ('Designation', profile.designation),
      ('Year joined', '${profile.joinedYear ?? '—'}'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _avatar(size: 108)),
        const SizedBox(height: 22),
        PatternGroup(
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 118,
                      child: Text(
                        row.$1,
                        style: PatternPage.body(
                          size: 12,
                          color: PatternPage.muted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2.isEmpty ? '—' : row.$2,
                        style: PatternPage.body(
                          size: 14,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => setState(() => _editing = true),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: PatternPage.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Edit profile',
              style: PatternPage.panchang(size: 12, weight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
