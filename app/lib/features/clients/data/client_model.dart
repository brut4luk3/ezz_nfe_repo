import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? cpf;
  final String? notes;
  final String? origem;
  final bool indicacao;
  final String? indicadorClientId;
  final bool inadimplente;
  final bool addedViaSelectDialog;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Client({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.cpf,
    this.notes,
    this.origem,
    this.indicacao = false,
    this.indicadorClientId,
    this.inadimplente = false,
    this.addedViaSelectDialog = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Nome completo (firstName + lastName) para exibicao e compatibilidade.
  String get name => '$firstName $lastName'.trim();

  factory Client.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final firstName = data['firstName'] as String?;
    final lastName = data['lastName'] as String?;
    final legacyName = data['name'] as String? ?? '';
    return Client(
      id: doc.id,
      firstName: firstName ?? legacyName,
      lastName: lastName ?? '',
      phone: (data['phone'] ?? '') as String,
      cpf: data['cpf'] as String?,
      notes: data['notes'] as String?,
      origem: data['origem'] as String?,
      indicacao: data['indicacao'] == true,
      indicadorClientId: data['indicadorClientId'] as String?,
      inadimplente: data['inadimplente'] == true,
      addedViaSelectDialog: data['addedViaSelectDialog'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'cpf': cpf,
      'notes': notes,
      'origem': origem,
      'indicacao': indicacao,
      'indicadorClientId': indicadorClientId,
      'inadimplente': inadimplente,
      'addedViaSelectDialog': addedViaSelectDialog,
    };
  }
}
