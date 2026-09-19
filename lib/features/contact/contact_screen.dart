import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/app_content.dart';
import '../../core/widgets/pattern_page.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({
    super.key,
    this.initialIntent = 'charter',
  });

  final String initialIntent;

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  String _intent = 'charter';

  @override
  void initState() {
    super.initState();
    _intent = widget.initialIntent;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    final label = switch (_intent) {
      'charter' => 'Charter enquiry received.',
      'consultation' => 'Consultation request received.',
      'assistance' => 'Assistance request received.',
      _ => 'Message received.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label Our team will respond shortly.')),
    );
    _message.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Settings > Contact Support',
      title: 'Contact',
      subtitle: 'GROUND DESK',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PatternSectionLabel('Offices'),
          const SizedBox(height: 8),
          PatternGroup(
            children: [
              PatternListRow(
                title: 'Head Office',
                subtitle: AppContent.headOffice,
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
              PatternListRow(
                title: 'Airport Office',
                subtitle: AppContent.airportOffice,
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
              PatternListRow(
                title: 'UK Office',
                subtitle: AppContent.ukOffice,
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 28),
          const PatternSectionLabel('Reach us'),
          const SizedBox(height: 8),
          PatternGroup(
            children: [
              PatternListRow(
                title: 'Email',
                subtitle: AppContent.contactEmail,
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
              PatternListRow(
                title: 'Phone',
                subtitle: AppContent.contactPhone,
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 28),
          const PatternSectionLabel('Send a message'),
          const SizedBox(height: 14),
          _Field(
            controller: _name,
            label: 'Name',
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final option in [
                ('charter', 'Charter'),
                ('consultation', 'Consultation'),
                ('assistance', 'Assistance'),
                ('other', 'Other'),
              ])
                ChoiceChip(
                  label: Text(option.$2),
                  selected: _intent == option.$1,
                  onSelected: (_) => setState(() => _intent = option.$1),
                  selectedColor: PatternPage.blue,
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  backgroundColor: const Color(0xFF1C1C1E),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _message,
            label: 'Message',
            maxLines: 4,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Send',
                style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: PatternPage.body(size: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: PatternPage.body(size: 13, color: PatternPage.muted),
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
