import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/airport.dart';
import '../../core/data/airport_catalog.dart';
import '../../core/widgets/pattern_page.dart';

Future<Airport?> showAirportPicker({
  required BuildContext context,
  required String title,
  Airport? selected,
  Airport? exclude,
}) {
  return showModalBottomSheet<Airport>(
    context: context,
    backgroundColor: const Color(0xFF121212),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _AirportPickerSheet(
        title: title,
        selected: selected,
        exclude: exclude,
      );
    },
  );
}

class _AirportPickerSheet extends StatefulWidget {
  const _AirportPickerSheet({
    required this.title,
    this.selected,
    this.exclude,
  });

  final String title;
  final Airport? selected;
  final Airport? exclude;

  @override
  State<_AirportPickerSheet> createState() => _AirportPickerSheetState();
}

class _AirportPickerSheetState extends State<_AirportPickerSheet> {
  final _query = TextEditingController();
  List<Airport> _all = const [];
  List<Airport> _results = const [];
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await AirportCatalog.all();
    if (!mounted) return;
    setState(() {
      _all = all;
      _loading = false;
      _results = _filtered('');
    });
  }

  List<Airport> _filtered(String query) {
    final exclude = widget.exclude?.code.toUpperCase();
    return AirportCatalog.search(_all, query)
        .where((a) => a.code.toUpperCase() != exclude)
        .toList();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 90), () {
      if (!mounted) return;
      setState(() => _results = _filtered(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.88;
    final emptyQuery = _query.text.trim().isEmpty;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
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
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'Panchang',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _query,
                autofocus: true,
                onChanged: _onQuery,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                cursorColor: PatternPage.blue,
                decoration: InputDecoration(
                  hintText: 'Search city, airport, or code',
                  hintStyle: GoogleFonts.poppins(
                    color: PatternPage.muted,
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: PatternPage.muted,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (emptyQuery && !_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Suggested  ·  ${_all.length} airports worldwide',
                    style: GoogleFonts.poppins(
                      color: PatternPage.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: PatternPage.blue,
                        strokeWidth: 2,
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            'No airports match that search',
                            style: GoogleFonts.poppins(
                              color: PatternPage.muted,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final airport = _results[index];
                            final selected = widget.selected?.code ==
                                airport.code;
                            return ListTile(
                              dense: true,
                              title: Text(
                                airport.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: selected
                                      ? PatternPage.blue
                                      : Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                '${airport.name}  ·  ${airport.country}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: PatternPage.muted,
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check,
                                      color: PatternPage.blue,
                                      size: 18,
                                    )
                                  : Text(
                                      airport.code,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: PatternPage.blue,
                                      ),
                                    ),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context, airport);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
