import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/cart/catering_cart.dart';
import '../../core/data/app_content.dart';
import '../../core/data/catering_menu.dart';
import '../../core/widgets/app_asset_image.dart';
import '../../core/widgets/pattern_page.dart';

class CateringScreen extends StatefulWidget {
  const CateringScreen({super.key});

  @override
  State<CateringScreen> createState() => _CateringScreenState();
}

class _CateringScreenState extends State<CateringScreen> {
  String _filter = 'All';

  List<String> get _filters => ['All', ...CateringMenu.categories];

  void _openCart() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CartSheet(),
    );
  }

  void _openCrewOrders() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CrewOrdersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CateringCart>();
    final items = CateringMenu.byCategory(_filter);

    return PatternPage(
      breadcrumb: 'Home > Catering',
      title: 'Catering',
      titleSize: 18,
      subtitle: 'IN-FLIGHT MENU',
      actions: [
        IconButton(
          tooltip: 'Crew orders',
          onPressed: _openCrewOrders,
          icon: Badge(
            isLabelVisible: cart.orders.isNotEmpty,
            label: Text('${cart.orders.length}'),
            child: const Icon(
              Icons.airline_seat_recline_extra_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Your order',
          onPressed: _openCart,
          icon: Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text('${cart.itemCount}'),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white70,
              size: 22,
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: f,
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (cart.itemCount > 0) ...[
            Material(
              color: PatternPage.blue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _openCart,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: PatternPage.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Order · ${cart.itemCount} item'
                          '${cart.itemCount == 1 ? '' : 's'}',
                          style: PatternPage.body(
                            size: 12.5,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'Review',
                        style: PatternPage.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: PatternPage.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) => _MealCard(item: items[index]),
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
    return Material(
      color: selected
          ? PatternPage.blue.withValues(alpha: 0.35)
          : const Color(0xFF121212),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
              size: 11.5,
              weight: FontWeight.w500,
              color: selected ? Colors.white : PatternPage.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.item});

  final CateringMenuItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CateringCart>();
    final qty = cart.qtyOf(item.id);

    return Material(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: item.imageAsset == null
                  ? const ColoredBox(
                      color: Color(0xFF1A1A1A),
                      child: Icon(
                        Icons.restaurant_outlined,
                        color: PatternPage.muted,
                        size: 28,
                      ),
                    )
                  : AppAssetImage(
                      item.imageAsset!,
                      fit: BoxFit.cover,
                      maxCacheWidth: 600,
                      errorBuilder: (_, error, stackTrace) => const ColoredBox(
                        color: Color(0xFF1A1A1A),
                        child: Icon(
                          Icons.restaurant_outlined,
                          color: PatternPage.muted,
                          size: 28,
                        ),
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PatternPage.body(
                      size: 9,
                      weight: FontWeight.w500,
                      color: PatternPage.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PatternPage.panchang(
                        size: 11,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (qty == 0)
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: FilledButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          cart.add(item);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: PatternPage.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Add',
                          style: PatternPage.panchang(size: 9),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        _QtyBtn(
                          icon: Icons.remove_rounded,
                          onTap: () => cart.removeOne(item.id),
                        ),
                        Expanded(
                          child: Text(
                            '$qty',
                            textAlign: TextAlign.center,
                            style: PatternPage.panchang(
                              size: 12,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _QtyBtn(
                          icon: Icons.add_rounded,
                          onTap: () => cart.add(item),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PatternPage.blue.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 15, color: Colors.white),
        ),
      ),
    );
  }
}

class _CartSheet extends StatefulWidget {
  const _CartSheet();

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  final _name = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _place(CateringCart cart) {
    if (cart.isEmpty) return;
    final order = cart.placeOrder(
      passengerName: _name.text.trim(),
      seatNote: _note.text.trim(),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${order.id} sent to crew — ${order.lines.length} item type(s).',
          style: PatternPage.body(size: 13),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF222222),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CateringCart>();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 16, 22, 20 + bottom + safe),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your order',
            style: PatternPage.panchang(size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Crew will receive this when you tap Order.',
            style: PatternPage.body(size: 12.5, color: PatternPage.muted),
          ),
          const SizedBox(height: 16),
          if (cart.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No meals selected yet.',
                style: PatternPage.body(size: 13, color: PatternPage.muted),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.32,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cart.lines.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final line = cart.lines[i];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.item.name,
                              style: PatternPage.body(
                                size: 13,
                                weight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              line.item.category,
                              style: PatternPage.body(
                                size: 11,
                                color: PatternPage.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _QtyBtn(
                        icon: Icons.remove_rounded,
                        onTap: () => cart.removeOne(line.item.id),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${line.qty}',
                          style: PatternPage.panchang(size: 12),
                        ),
                      ),
                      _QtyBtn(
                        icon: Icons.add_rounded,
                        onTap: () => cart.add(line.item),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            style: PatternPage.body(size: 13),
            decoration: _fieldDecoration('Passenger name (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            style: PatternPage.body(size: 13),
            decoration: _fieldDecoration('Seat / cabin note (optional)'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: cart.isEmpty ? null : () => _place(cart),
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                disabledBackgroundColor: PatternPage.divider,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                cart.isEmpty ? 'Add meals first' : 'Order — send to crew',
                style: PatternPage.panchang(size: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: PatternPage.body(size: 12, color: PatternPage.muted),
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

class _CrewOrdersSheet extends StatelessWidget {
  const _CrewOrdersSheet();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CateringCart>();
    final safe = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 16, 22, 28 + safe),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Crew desk',
            style: PatternPage.panchang(size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Orders received from the cabin (offline staging).',
            style: PatternPage.body(size: 12.5, color: PatternPage.muted),
          ),
          const SizedBox(height: 16),
          if (cart.orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No catering orders yet.',
                style: PatternPage.body(size: 13, color: PatternPage.muted),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cart.orders.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final o = cart.orders[i];
                  final time =
                      '${o.createdAt.hour.toString().padLeft(2, '0')}:'
                      '${o.createdAt.minute.toString().padLeft(2, '0')}';
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: PatternPage.divider),
                      color: PatternPage.blue.withValues(alpha: 0.12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                o.id,
                                style: PatternPage.body(
                                  size: 13,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              o.status,
                              style: PatternPage.body(
                                size: 11,
                                color: PatternPage.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time +
                              (o.passengerName.isEmpty
                                  ? ''
                                  : ' · ${o.passengerName}'),
                          style: PatternPage.body(
                            size: 11.5,
                            color: PatternPage.muted,
                          ),
                        ),
                        if (o.seatNote.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            o.seatNote,
                            style: PatternPage.body(
                              size: 12,
                              color: PatternPage.muted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ...o.lines.map(
                          (l) => Text(
                            '· ${l.qty}× ${l.name}',
                            style: PatternPage.body(size: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
