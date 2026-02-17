import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_model.dart';

class ProductsRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  ProductsRepository({
    required FirebaseFirestore firestore,
    required String uid,
  })  : _firestore = firestore,
        _uid = uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('products');

  Stream<List<Product>> watchAll() {
    return _col
        .orderBy('updatedAt', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromDoc).toList());
  }

  Future<Product?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromDoc(doc);
  }

  Future<String> create(Product product) async {
    final data = product.toMap();
    final docRef = await _col.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> update(String id, Product product) async {
    final data = product.toMap();
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Produtos que usam o tipo [typeId].
  Future<List<Product>> getProductsByTypeId(String typeId) async {
    final snap = await _col.where('typeId', isEqualTo: typeId).get();
    return snap.docs.map(Product.fromDoc).toList();
  }

  /// Produtos que usam a marca [brandId].
  Future<List<Product>> getProductsByBrandId(String brandId) async {
    final snap = await _col.where('brandId', isEqualTo: brandId).get();
    return snap.docs.map(Product.fromDoc).toList();
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
