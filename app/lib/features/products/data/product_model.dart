import 'package:cloud_firestore/cloud_firestore.dart';

/// Unidades de medida para produtos.
enum ProductUnit {
  kg('kg', 'Quilo'),
  g('g', 'Grama'),
  mg('mg', 'Miligrama'),
  L('L', 'Litros'),
  ml('ml', 'Mililitro');

  final String code;
  final String label;

  const ProductUnit(this.code, this.label);

  static ProductUnit? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final u in ProductUnit.values) {
      if (u.code == code) return u;
    }
    return null;
  }
}

class Product {
  final String id;
  final String name;
  /// ID da marca em productBrands. Quando null, usa [brandLegacy] (produtos antigos).
  final String? brandId;
  /// Marca legada (string direta) para produtos criados antes da entidade ProductBrand.
  final String? brandLegacy;
  /// Valor em reais (ex: 59.90).
  final double value;
  final String? typeId;
  final double? quantity;
  final ProductUnit? unit;
  final DateTime? expiryDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.brandId,
    this.brandLegacy,
    required this.value,
    this.typeId,
    this.quantity,
    this.unit,
    this.expiryDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Nome da marca para exibição. Passar [brandName] quando [brandId] está preenchido.
  String brandDisplay(String? brandName) =>
      brandId != null && brandName != null ? brandName : (brandLegacy ?? '');

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final quantityVal = data['quantity'];
    double? quantity;
    if (quantityVal != null) {
      if (quantityVal is int) {
        quantity = quantityVal.toDouble();
      } else if (quantityVal is double) {
        quantity = quantityVal;
      } else if (quantityVal is num) {
        quantity = quantityVal.toDouble();
      }
    }
    final brandId = data['brandId'] as String?;
    final brandLegacy = data['brand'] as String?;
    return Product(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      brandId: brandId,
      brandLegacy: brandId == null ? brandLegacy : null,
      value: _parseValue(data),
      typeId: data['typeId'] as String?,
      quantity: quantity,
      unit: ProductUnit.fromCode(data['unit'] as String?),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static double _parseValue(Map<String, dynamic> data) {
    final v = data['value'];
    if (v != null && v is num) return v.toDouble();
    final cents = data['valueCents'];
    if (cents != null && cents is num) return cents.toDouble() / 100.0;
    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brandId': brandId,
      'value': value,
      'typeId': typeId,
      'quantity': quantity,
      'unit': unit?.code,
      'expiryDate': expiryDate != null
          ? Timestamp.fromDate(expiryDate!)
          : null,
    };
  }
}
