import 'package:cloud_firestore/cloud_firestore.dart';

import 'appointment_model.dart';

class AppointmentsRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  AppointmentsRepository({
    required FirebaseFirestore firestore,
    required String uid,
  })  : _firestore = firestore,
        _uid = uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('appointments');

  Stream<List<Appointment>> watchAll() {
    return _col
        .orderBy('updatedAt', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Appointment.fromDoc).toList());
  }

  Future<Appointment?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Appointment.fromDoc(doc);
  }

  Future<String> create(Appointment appointment) async {
    final data = appointment.toMap();
    final doc = await _col.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> update(String id, Appointment appointment) async {
    final data = appointment.toMap();
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
