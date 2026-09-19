import 'package:flutter/foundation.dart';

import '../data/app_content.dart';

class CateringLine {
  CateringLine({required this.item, this.qty = 1});
  final CateringMenuItem item;
  int qty;
}

/// In-flight catering cart — multi-select, then order for crew/admin.
class CateringCart extends ChangeNotifier {
  final Map<String, CateringLine> _lines = {};
  final List<CateringOrder> _orders = [];

  List<CateringLine> get lines => _lines.values.toList(growable: false);
  int get itemCount => _lines.values.fold(0, (s, l) => s + l.qty);
  bool get isEmpty => _lines.isEmpty;
  List<CateringOrder> get orders => List.unmodifiable(_orders);

  void add(CateringMenuItem item) {
    final existing = _lines[item.id];
    if (existing != null) {
      existing.qty++;
    } else {
      _lines[item.id] = CateringLine(item: item);
    }
    notifyListeners();
  }

  void removeOne(String id) {
    final existing = _lines[id];
    if (existing == null) return;
    if (existing.qty > 1) {
      existing.qty--;
    } else {
      _lines.remove(id);
    }
    notifyListeners();
  }

  void removeAll(String id) {
    _lines.remove(id);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  int qtyOf(String id) => _lines[id]?.qty ?? 0;

  /// Submits order locally for crew/admin review (offline-first).
  CateringOrder placeOrder({String seatNote = '', String passengerName = ''}) {
    final snapshot = lines
        .map((l) => CateringOrderLine(name: l.item.name, category: l.item.category, qty: l.qty))
        .toList();
    final order = CateringOrder(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      lines: snapshot,
      seatNote: seatNote,
      passengerName: passengerName,
      status: 'Sent to crew',
    );
    _orders.insert(0, order);
    _lines.clear();
    notifyListeners();
    return order;
  }
}

class CateringOrderLine {
  const CateringOrderLine({
    required this.name,
    required this.category,
    required this.qty,
  });
  final String name;
  final String category;
  final int qty;
}

class CateringOrder {
  const CateringOrder({
    required this.id,
    required this.createdAt,
    required this.lines,
    required this.status,
    this.seatNote = '',
    this.passengerName = '',
  });

  final String id;
  final DateTime createdAt;
  final List<CateringOrderLine> lines;
  final String status;
  final String seatNote;
  final String passengerName;
}
