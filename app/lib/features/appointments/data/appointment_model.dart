import 'package:cloud_firestore/cloud_firestore.dart';

/// Produto vinculado a um atendimento, com quantidade.
class AppointmentProductItem {
  final String productId;
  final double quantity;

  const AppointmentProductItem({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() =>
      {'productId': productId, 'quantity': quantity};

  static AppointmentProductItem fromMap(Map<String, dynamic> m) =>
      AppointmentProductItem(
        productId: (m['productId'] ?? '') as String,
        quantity: (m['quantity'] ?? 1.0) is int
            ? (m['quantity'] as int).toDouble()
            : (m['quantity'] ?? 1.0) as double,
      );
}

class Appointment {
  final String id;
  final String clientId;
  final bool isOnlySale;
  final List<String> serviceIds;
  final List<AppointmentProductItem> productItems;
  /// Valor total em reais (ex: 150.50).
  final double total;
  final DateTime scheduledAt;
  final bool chargeDeposit;
  /// Valor do sinal em reais quando [chargeDeposit] é true.
  final double? deposit;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Appointment({
    required this.id,
    required this.clientId,
    this.isOnlySale = false,
    this.serviceIds = const [],
    this.productItems = const [],
    required this.total,
    required this.scheduledAt,
    this.chargeDeposit = false,
    this.deposit,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  static double _parseTotal(Map<String, dynamic> data) {
    final totalVal = data['total'];
    final totalCents = data['totalCents'];
    if (totalVal != null && totalVal is num) return totalVal.toDouble();
    if (totalCents != null && totalCents is num) {
      return totalCents.toDouble() / 100.0;
    }
    return 0.0;
  }

  static double? _parseDeposit(Map<String, dynamic> data) {
    final depositVal = data['deposit'];
    final depositCents = data['depositCents'];
    if (depositVal != null && depositVal is num) return depositVal.toDouble();
    if (depositCents != null && depositCents is num) {
      return depositCents.toDouble() / 100.0;
    }
    return null;
  }

  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final productItemsRaw = data['productItems'] as List<dynamic>?;
    final productItems = productItemsRaw != null
        ? productItemsRaw
            .map((e) => AppointmentProductItem.fromMap(
                Map<String, dynamic>.from(e as Map)))
            .toList()
        : <AppointmentProductItem>[];
    return Appointment(
      id: doc.id,
      clientId: (data['clientId'] ?? '') as String,
      isOnlySale: data['isOnlySale'] == true,
      serviceIds: (data['serviceIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      productItems: productItems,
      total: _parseTotal(data),
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      chargeDeposit: data['chargeDeposit'] == true,
      deposit: _parseDeposit(data),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'isOnlySale': isOnlySale,
      'serviceIds': serviceIds,
      'productItems': productItems.map((e) => e.toMap()).toList(),
      'total': total,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'chargeDeposit': chargeDeposit,
      'deposit': deposit,
      'notes': notes,
    };
  }
}
