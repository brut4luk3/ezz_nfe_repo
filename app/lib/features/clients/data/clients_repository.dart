import 'package:cloud_firestore/cloud_firestore.dart';

import 'client_model.dart';

class ClientsRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  ClientsRepository({
    required FirebaseFirestore firestore,
    required String uid,
  })  : _firestore = firestore,
        _uid = uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('clients');

  Stream<List<Client>> watchAll() {
    return _col
        .orderBy('updatedAt', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Client.fromDoc).toList());
  }

  Future<Client?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Client.fromDoc(doc);
  }

  Future<String> create(Client client) async {
    final data = client.toMap();
    final docRef = await _col.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> update(String id, Client client) async {
    final data = client.toMap();
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Clientes que têm [indicadorClientId] como indicador.
  Future<List<Client>> getClientsWithIndicatorId(String indicadorClientId) async {
    final snap = await _col
        .where('indicadorClientId', isEqualTo: indicadorClientId)
        .get();
    return snap.docs.map(Client.fromDoc).toList();
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
