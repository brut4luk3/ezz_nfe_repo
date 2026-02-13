import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceItem {
  final String id;
  final String name;
  final int priceCents;
  final int? durationMinutes;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.priceCents,
    this.durationMinutes,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ServiceItem(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      priceCents: (data['priceCents'] ?? 0) as int,
      durationMinutes: data['durationMinutes'] as int?,
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'priceCents': priceCents,
      'durationMinutes': durationMinutes,
      'description': description,
    };
  }
}
