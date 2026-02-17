import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_brand_model.dart';

class ProductBrandsRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  ProductBrandsRepository({
    required FirebaseFirestore firestore,
    required String uid,
  })  : _firestore = firestore,
        _uid = uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('productBrands');

  Stream<List<ProductBrand>> watchAll() {
    return _col
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(ProductBrand.fromDoc).toList());
  }

  Future<ProductBrand?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ProductBrand.fromDoc(doc);
  }

  Future<String> create(ProductBrand item) async {
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
