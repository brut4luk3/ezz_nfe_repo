import 'package:cloud_firestore/cloud_firestore.dart';

class ProductType {
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductType({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductType.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProductType(
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
