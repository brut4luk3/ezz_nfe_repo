import 'package:cloud_firestore/cloud_firestore.dart';

import 'invoice_model.dart';

class InvoicesRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  InvoicesRepository({
    required FirebaseFirestore firestore,
    required String uid,
  })  : _firestore = firestore,
        _uid = uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('invoices');

  Stream<List<Invoice>> watchAll() {
    return _col
        .orderBy('updatedAt', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Invoice.fromDoc).toList());
  }

  Future<void> create(Invoice invoice) async {
    final data = invoice.toMap();
    await _col.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(String id, Invoice invoice) async {
    final data = invoice.toMap();
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
