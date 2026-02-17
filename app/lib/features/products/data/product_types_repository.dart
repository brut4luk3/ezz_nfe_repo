import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_type_model.dart';

class ProductTypesRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  ProductTypesRepository({
    required FirebaseFirestore firestore,
    required String uid,
  })  : _firestore = firestore,
        _uid = uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('productTypes');

  Stream<List<ProductType>> watchAll() {
    return _col
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(ProductType.fromDoc).toList());
  }

  Future<ProductType?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ProductType.fromDoc(doc);
  }

  Future<String> create(ProductType item) async {
    final data = item.toMap();
    final docRef = await _col.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
