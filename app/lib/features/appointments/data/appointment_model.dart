import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String clientId;
  final List<String> serviceIds;
  final int totalCents;
  final DateTime scheduledAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Appointment({
    required this.id,
    required this.clientId,
    required this.serviceIds,
    required this.totalCents,
    required this.scheduledAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Appointment(
      id: doc.id,
      clientId: (data['clientId'] ?? '') as String,
      serviceIds: (data['serviceIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      totalCents: (data['totalCents'] ?? 0) as int,
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'serviceIds': serviceIds,
      'totalCents': totalCents,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'notes': notes,
    };
  }
}
