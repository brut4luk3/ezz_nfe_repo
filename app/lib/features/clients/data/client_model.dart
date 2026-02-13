import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String name;
  final String? phone;
  final String? cpf;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Client({
    required this.id,
    required this.name,
    this.phone,
    this.cpf,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Client.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Client(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      phone: data['phone'] as String?,
      cpf: data['cpf'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'cpf': cpf,
      'notes': notes,
    };
  }
}
