import 'package:cloud_firestore/cloud_firestore.dart';

/// Produto vinculado a um serviço, com quantidade.
class ServiceProductItem {
  final String productId;
  final double quantity;

  const ServiceProductItem({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {'productId': productId, 'quantity': quantity};

  static ServiceProductItem fromMap(Map<String, dynamic> m) =>
      ServiceProductItem(
        productId: (m['productId'] ?? '') as String,
        quantity: (m['quantity'] ?? 1.0) is int
            ? (m['quantity'] as int).toDouble()
            : (m['quantity'] ?? 1.0) as double,
      );
}

class ServiceItem {
  final String id;
  final String name;
  /// Valor em reais (ex: 59.90).
  final double price;
  final int? durationMinutes;
  final String? description;
  final bool addedViaSelectDialog;
  final List<ServiceProductItem> productItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.price,
    this.durationMinutes,
    this.description,
    this.addedViaSelectDialog = false,
    this.productItems = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final priceVal = data['price'];
    final priceCents = data['priceCents'];
    double price;
    if (priceVal != null && priceVal is num) {
      price = priceVal.toDouble();
    } else if (priceCents != null && priceCents is num) {
      price = priceCents.toDouble() / 100.0;
    } else {
      price = 0.0;
    }
    final productItemsRaw = data['productItems'] as List<dynamic>?;
    final productItems = productItemsRaw != null
        ? productItemsRaw
            .map((e) => ServiceProductItem.fromMap(
                Map<String, dynamic>.from(e as Map)))
            .toList()
        : <ServiceProductItem>[];
    return ServiceItem(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      price: price,
      durationMinutes: data['durationMinutes'] as int?,
      description: data['description'] as String?,
      addedViaSelectDialog: data['addedViaSelectDialog'] == true,
      productItems: productItems,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationMinutes': durationMinutes,
      'description': description,
      'addedViaSelectDialog': addedViaSelectDialog,
      'productItems': productItems.map((e) => e.toMap()).toList(),
    };
  }
}
