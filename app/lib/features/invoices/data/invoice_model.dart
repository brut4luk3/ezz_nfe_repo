import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus { draft, pendingIntegration, issued, error }

class Invoice {
  final String id;
  final String? appointmentId;
  final InvoiceStatus status;
  final int totalCents;
  final DateTime? issuedAt;
  final String? externalRef;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Invoice({
    required this.id,
    required this.status,
    required this.totalCents,
    this.appointmentId,
    this.issuedAt,
    this.externalRef,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Invoice(
      id: doc.id,
      appointmentId: data['appointmentId'] as String?,
      status: _statusFromString((data['status'] ?? 'draft') as String),
      totalCents: (data['totalCents'] ?? 0) as int,
      issuedAt: (data['issuedAt'] as Timestamp?)?.toDate(),
      externalRef: data['externalRef'] as String?,
      errorMessage: data['errorMessage'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'status': _statusToString(status),
      'totalCents': totalCents,
      'issuedAt': issuedAt == null ? null : Timestamp.fromDate(issuedAt!),
      'externalRef': externalRef,
      'errorMessage': errorMessage,
    };
  }

  static String _statusToString(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return 'draft';
      case InvoiceStatus.pendingIntegration:
        return 'pending_integration';
      case InvoiceStatus.issued:
        return 'issued';
      case InvoiceStatus.error:
        return 'error';
    }
  }

  static InvoiceStatus _statusFromString(String value) {
    switch (value) {
      case 'pending_integration':
        return InvoiceStatus.pendingIntegration;
      case 'issued':
        return InvoiceStatus.issued;
      case 'error':
        return InvoiceStatus.error;
      case 'draft':
      default:
        return InvoiceStatus.draft;
    }
  }
}
