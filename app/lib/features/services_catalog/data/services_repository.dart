import 'package:cloud_firestore/cloud_firestore.dart';

import 'service_item_model.dart';

class ServicesRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  ServicesRepository({
    required FirebaseFirestore firestore,
    required String uid,
  })  : _firestore = firestore,
        _uid = uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('services');

  Stream<List<ServiceItem>> watchAll() {
    return _col
        .orderBy('updatedAt', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ServiceItem.fromDoc).toList());
  }

  Future<ServiceItem?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ServiceItem.fromDoc(doc);
  }

  Future<String> create(ServiceItem item) async {
    final data = item.toMap();
    final docRef = await _col.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> update(String id, ServiceItem item) async {
    final data = item.toMap();
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Serviços que possuem o produto [productId] em productItems.
  Future<List<ServiceItem>> getServicesUsingProductId(String productId) async {
    final snap = await _col.get();
    return snap.docs
        .map(ServiceItem.fromDoc)
        .where((s) =>
            s.productItems.any((p) => p.productId == productId))
        .toList();
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
