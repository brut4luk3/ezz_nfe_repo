import 'package:cloud_firestore/cloud_firestore.dart';

class ProductBrand {
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductBrand({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductBrand.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProductBrand(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name};
  }
}
