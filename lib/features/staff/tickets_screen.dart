import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/staff_access.dart';
import '../../core/data/staff_store.dart';
import '../../core/notifications/push_inbox.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<SupportTicket> _tickets = [];
  bool _loading = true;
  TicketStatus? _filter;
  TicketCategory? _categoryFilter;

  bool get _isAdmin => StaffAccess.role.value.isOrgAdmin;

  int get _navIndex {
    final role = StaffAccess.role.value;
    if (role.isOrgAdmin) return 4;
    if (role == BerpRole.manager) return 2;
    return AppNavIndex.leave;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tickets = await StaffStore.instance.tickets(mineOnly: !_isAdmin);
    if (!mounted) return;
    setState(() {
      _tickets = tickets;
      _loading = false;
    });
  }

  List<SupportTicket> get _visible {
    return [
      for (final ticket in _tickets)
        if ((_filter == null || ticket.status == _filter) &&
            (_categoryFilter == null || ticket.category == _categoryFilter))
          ticket,
    ];
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _CreateTicketPage()),
    );
    if (created == true) await _load();
  }

  Future<void> _openDetail(SupportTicket ticket) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _TicketDetailPage(ticket: ticket, isAdmin: _isAdmin),
      ),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final pending = _tickets
        .where((t) => t.status == TicketStatus.pending)
        .length;
    final progress = _tickets
        .where((t) => t.status == TicketStatus.inProgress)
        .length;
    final done = _tickets.where((t) => t.status == TicketStatus.done).length;

    return PatternPage(
      breadcrumb: _isAdmin ? 'Dashboard > Tickets' : 'Home > Tickets',
      title: _isAdmin ? 'Work orders' : 'My tickets',
      subtitle: _isAdmin
          ? 'IT & FACILITY ISSUES'
          : 'TRACK YOUR REQUESTS',
      bottom: AppBottomNav(currentIndex: _navIndex),
      actions: [
        Material(
          color: PatternPage.blue,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _openCreate,
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  value: '$pending',
                  label: 'Pending',
                  color: const Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  value: '$progress',
                  label: 'In progress',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  value: '$done',
                  label: 'Done',
                  color: const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == null && _categoryFilter == null,
                  onTap: () => setState(() {
                    _filter = null;
                    _categoryFilter = null;
                  }),
                ),
                const SizedBox(width: 8),
                for (final status in TicketStatus.values) ...[
                  _FilterChip(
                    label: status.label,
                    selected: _filter == status,
                    onTap: () => setState(() {
                      _filter = _filter == status ? null : status;
                    }),
                  ),
                  const SizedBox(width: 8),
                ],
                _FilterChip(
                  label: 'IT',
                  selected: _categoryFilter == TicketCategory.it,
                  onTap: () => setState(() {
                    _categoryFilter = _categoryFilter == TicketCategory.it
                        ? null
                        : TicketCategory.it;
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Facility',
                  selected: _categoryFilter == TicketCategory.facility,
                  onTap: () => setState(() {
                    _categoryFilter =
                        _categoryFilter == TicketCategory.facility
                            ? null
                            : TicketCategory.facility;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.confirmation_number_outlined, size: 18),
              label: Text(
                'Create ticket',
                style: PatternPage.body(size: 13, weight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: PatternPage.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (visible.isEmpty)
            Text(
              _tickets.isEmpty
                  ? (_isAdmin
                        ? 'No tickets yet. Staff can submit IT or facility issues.'
                        : 'You have not submitted any tickets yet.')
                  : 'No tickets match this filter.',
              style: PatternPage.body(size: 13, color: PatternPage.muted),
            )
          else
            for (final ticket in visible) ...[
              _TicketCard(
                ticket: ticket,
                showReporter: _isAdmin,
                onTap: () => _openDetail(ticket),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _CreateTicketPage extends StatefulWidget {
  const _CreateTicketPage();

  @override
  State<_CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<_CreateTicketPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  TicketCategory _category = TicketCategory.it;
  final List<Uint8List> _images = [];
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 3) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _images.add(bytes));
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final description = _description.text.trim();
    final location = _location.text.trim();
    if (title.isEmpty || description.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a title, description, and location / area.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.selectionClick();
    try {
      final ticket = await StaffStore.instance.createTicket(
        category: _category,
        title: title,
        description: description,
        locationLabel: location,
        images: List<Uint8List>.from(_images),
      );
      if (ticket == null) throw Exception('Could not submit ticket.');
      await PushInbox.sync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket submitted. Admins have been notified.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Tickets > New',
      title: 'New ticket',
      subtitle: 'WORK ORDER',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PatternSectionLabel('Category'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final category in TicketCategory.values) ...[
                if (category != TicketCategory.values.first)
                  const SizedBox(width: 8),
                Expanded(
                  child: _CategoryPick(
                    label: category.label,
                    icon: category == TicketCategory.it
                        ? Icons.computer_rounded
                        : Icons.apartment_rounded,
                    selected: _category == category,
                    onTap: () => setState(() => _category = category),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _title,
            style: PatternPage.body(size: 13),
            cursorColor: PatternPage.blue,
            decoration: _field('Issue title'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _location,
            style: PatternPage.body(size: 13),
            cursorColor: PatternPage.blue,
            decoration: _field('Location / area (e.g. LOS HQ OFFICE)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _description,
            maxLines: 5,
            style: PatternPage.body(size: 13),
            cursorColor: PatternPage.blue,
            decoration: _field('Describe the issue…'),
          ),
          const SizedBox(height: 16),
          Text(
            'Photos (optional, up to 3)',
            style: PatternPage.body(size: 12, color: PatternPage.muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _images.length; i++)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _images[i],
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(i)),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_images.length < 3)
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: PatternPage.row,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PatternPage.divider),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: PatternPage.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _saving ? 'Submitting…' : 'Submit ticket',
                style: PatternPage.panchang(size: 12, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _field(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: PatternPage.body(size: 13, color: PatternPage.muted),
      filled: true,
      fillColor: PatternPage.row,
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
}

class _TicketDetailPage extends StatefulWidget {
  const _TicketDetailPage({required this.ticket, required this.isAdmin});

  final SupportTicket ticket;
  final bool isAdmin;

  @override
  State<_TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<_TicketDetailPage> {
  late SupportTicket _ticket;
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _note.text = _ticket.adminNote;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _setStatus(TicketStatus status) async {
    setState(() => _saving = true);
    final updated = await StaffStore.instance.updateTicketStatus(
      id: _ticket.id,
      status: status,
      adminNote: _note.text,
    );
    if (!mounted) return;
    if (updated == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update ticket status.')),
      );
      return;
    }
    setState(() {
      _ticket = updated;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marked as ${status.label.toLowerCase()}.')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Tickets > Detail',
      title: _ticket.title,
      subtitle: '${_ticket.category.label.toUpperCase()}  ·  ${_ticket.status.label.toUpperCase()}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBanner(status: _ticket.status),
          const SizedBox(height: 14),
          _DetailBlock(
            label: 'Reporter',
            value: [
              if (_ticket.reporterName.isNotEmpty) _ticket.reporterName,
              if (_ticket.reporterEmail.isNotEmpty) _ticket.reporterEmail,
            ].join('  ·  '),
          ),
          _DetailBlock(label: 'Location / area', value: _ticket.locationLabel),
          _DetailBlock(label: 'Description', value: _ticket.description),
          _DetailBlock(
            label: 'Submitted',
            value: formatLagosStamp(_ticket.createdAt),
          ),
          if (_ticket.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Photos',
              style: PatternPage.body(size: 12, color: PatternPage.muted),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _ticket.imageUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _ticket.imageUrls[index],
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 110,
                        height: 110,
                        color: PatternPage.row,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: PatternPage.muted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (widget.isAdmin) ...[
            const SizedBox(height: 18),
            Text(
              'Admin note',
              style: PatternPage.body(size: 12, color: PatternPage.muted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 3,
              style: PatternPage.body(size: 13),
              cursorColor: PatternPage.blue,
              decoration: InputDecoration(
                hintText: 'Internal note for this work order…',
                hintStyle: PatternPage.body(size: 13, color: PatternPage.muted),
                filled: true,
                fillColor: PatternPage.row,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: PatternPage.divider),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Update status',
              style: PatternPage.body(size: 13, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatusAction(
                    label: 'Pending',
                    color: const Color(0xFFF97316),
                    selected: _ticket.status == TicketStatus.pending,
                    enabled: !_saving,
                    onTap: () => _setStatus(TicketStatus.pending),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusAction(
                    label: 'In progress',
                    color: const Color(0xFF3B82F6),
                    selected: _ticket.status == TicketStatus.inProgress,
                    enabled: !_saving,
                    onTap: () => _setStatus(TicketStatus.inProgress),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusAction(
                    label: 'Done',
                    color: const Color(0xFF22C55E),
                    selected: _ticket.status == TicketStatus.done,
                    enabled: !_saving,
                    onTap: () => _setStatus(TicketStatus.done),
                  ),
                ),
              ],
            ),
          ] else if (_ticket.adminNote.isNotEmpty) ...[
            const SizedBox(height: 14),
            _DetailBlock(label: 'Admin note', value: _ticket.adminNote),
          ],
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.showReporter,
    required this.onTap,
  });

  final SupportTicket ticket;
  final bool showReporter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (ticket.status) {
      TicketStatus.pending => const Color(0xFFF97316),
      TicketStatus.inProgress => const Color(0xFF3B82F6),
      TicketStatus.done => const Color(0xFF22C55E),
    };
    return Material(
      color: PatternPage.row,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PatternPage.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PatternPage.blue.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket.category.label,
                      style: PatternPage.body(
                        size: 10,
                        weight: FontWeight.w700,
                        color: PatternPage.blue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.status.label,
                      style: PatternPage.body(
                        size: 10,
                        weight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.title,
                style: PatternPage.body(size: 14, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (showReporter && ticket.reporterName.isNotEmpty)
                    ticket.reporterName,
                  if (ticket.locationLabel.isNotEmpty) ticket.locationLabel,
                  formatTimeAgo(ticket.createdAt),
                ].join('  ·  '),
                style: PatternPage.body(size: 11, color: PatternPage.muted),
              ),
              if (ticket.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.photo_outlined,
                      size: 14,
                      color: PatternPage.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ticket.imageUrls.length} photo${ticket.imageUrls.length == 1 ? '' : 's'}',
                      style: PatternPage.body(
                        size: 11,
                        color: PatternPage.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: PatternPage.row,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PatternPage.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: PatternPage.body(
              size: 18,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: PatternPage.body(size: 10, color: PatternPage.muted),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? PatternPage.blue : PatternPage.row,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? PatternPage.blue : PatternPage.divider,
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
    );
  }
}

class _CategoryPick extends StatelessWidget {
  const _CategoryPick({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? PatternPage.blue.withValues(alpha: 0.18)
          : PatternPage.row,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? PatternPage.blue : PatternPage.divider,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? PatternPage.blue : PatternPage.muted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: PatternPage.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : PatternPage.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TicketStatus.pending => const Color(0xFFF97316),
      TicketStatus.inProgress => const Color(0xFF3B82F6),
      TicketStatus.done => const Color(0xFF22C55E),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Status: ${status.label}',
              style: PatternPage.body(
                size: 13,
                weight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: PatternPage.body(size: 11, color: PatternPage.muted),
          ),
          const SizedBox(height: 4),
          Text(value, style: PatternPage.body(size: 13, height: 1.4)),
        ],
      ),
    );
  }
}

class _StatusAction extends StatelessWidget {
  const _StatusAction({
    required this.label,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.22) : PatternPage.row,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : PatternPage.divider,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: PatternPage.body(
              size: 11,
              weight: FontWeight.w700,
              color: selected ? color : PatternPage.muted,
            ),
          ),
        ),
      ),
    );
  }
}
