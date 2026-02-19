import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço vinculado a um atendimento.
/// [serviceName] é persistido para exibição e título em eventos de agenda.
class AppointmentServiceItem {
  final String serviceId;
  final String serviceName;

  const AppointmentServiceItem({
    required this.serviceId,
    this.serviceName = '',
  });

  Map<String, dynamic> toMap() => {
    'serviceId': serviceId,
    'serviceName': serviceName,
  };

  static AppointmentServiceItem fromMap(Map<String, dynamic> m) =>
      AppointmentServiceItem(
        serviceId: (m['serviceId'] ?? '') as String,
        serviceName: (m['serviceName'] ?? '') as String,
      );
}

/// Produto vinculado a um atendimento, com quantidade.
/// [productName] é persistido para exibição e título em eventos de agenda.
class AppointmentProductItem {
  final String productId;

  /// Nome do produto para exibição e integração com Google Agenda.
  final String productName;
  final double quantity;

  const AppointmentProductItem({
    required this.productId,
    this.productName = '',
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
  };

  static AppointmentProductItem fromMap(Map<String, dynamic> m) =>
      AppointmentProductItem(
        productId: (m['productId'] ?? '') as String,
        productName: (m['productName'] ?? '') as String,
        quantity: (m['quantity'] ?? 1.0) is int
            ? (m['quantity'] as int).toDouble()
            : (m['quantity'] ?? 1.0) as double,
      );
}

class Appointment {
  final String id;
  final String clientId;
  final bool isOnlySale;
  final List<AppointmentServiceItem> serviceItems;
  final List<AppointmentProductItem> productItems;

  /// Valor total em reais (ex: 150.50).
  final double total;
  final DateTime scheduledAt;
  final bool chargeDeposit;

  /// Valor do sinal em reais quando [chargeDeposit] é true.
  final double? deposit;
  final String? notes;

  /// Marcar na Google Agenda. Relevante apenas quando [isOnlySale] == false.
  /// Para vendas (isOnlySale == true) a integração com agenda não se aplica.
  final bool addToCalendar;

  /// ID do evento na Google Agenda, quando criado com sucesso.
  final String? calendarEventId;

  /// Indica se o agendamento deve ser criado na Google Agenda.
  /// Apenas para agendamentos de serviços (não vendas).
  bool get canAddToCalendar => !isOnlySale && addToCalendar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Appointment copyWith({
    String? id,
    String? clientId,
    bool? isOnlySale,
    List<AppointmentServiceItem>? serviceItems,
    List<AppointmentProductItem>? productItems,
    double? total,
    DateTime? scheduledAt,
    bool? chargeDeposit,
    double? deposit,
    String? notes,
    bool? addToCalendar,
    String? calendarEventId,
  }) =>
      Appointment(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        isOnlySale: isOnlySale ?? this.isOnlySale,
        serviceItems: serviceItems ?? this.serviceItems,
        productItems: productItems ?? this.productItems,
        total: total ?? this.total,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        chargeDeposit: chargeDeposit ?? this.chargeDeposit,
        deposit: deposit ?? this.deposit,
        notes: notes ?? this.notes,
        addToCalendar: addToCalendar ?? this.addToCalendar,
        calendarEventId: calendarEventId ?? this.calendarEventId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  const Appointment({
    required this.id,
    required this.clientId,
    this.isOnlySale = false,
    this.serviceItems = const [],
    this.productItems = const [],
    required this.total,
    required this.scheduledAt,
    this.chargeDeposit = false,
    this.deposit,
    this.notes,
    this.addToCalendar = true,
    this.calendarEventId,
    this.createdAt,
    this.updatedAt,
  });

  static double _parseTotal(Map<String, dynamic> data) {
    final totalVal = data['total'];
    final totalCents = data['totalCents'];
    if (totalVal != null && totalVal is num) return totalVal.toDouble();
    if (totalCents != null && totalCents is num) {
      return totalCents.toDouble() / 100.0;
    }
    return 0.0;
  }

  static double? _parseDeposit(Map<String, dynamic> data) {
    final depositVal = data['deposit'];
    final depositCents = data['depositCents'];
    if (depositVal != null && depositVal is num) return depositVal.toDouble();
    if (depositCents != null && depositCents is num) {
      return depositCents.toDouble() / 100.0;
    }
    return null;
  }

  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final serviceItemsRaw = data['serviceItems'] as List<dynamic>?;
    List<AppointmentServiceItem> serviceItems;
    if (serviceItemsRaw != null && serviceItemsRaw.isNotEmpty) {
      serviceItems = serviceItemsRaw
          .map(
            (e) => AppointmentServiceItem.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } else {
      final serviceIdsRaw = data['serviceIds'] as List<dynamic>? ?? [];
      final serviceNamesRaw = data['serviceNames'] as List<dynamic>? ?? [];
      serviceItems = List.generate(
        serviceIdsRaw.length,
        (i) => AppointmentServiceItem(
          serviceId: serviceIdsRaw[i].toString(),
          serviceName: i < serviceNamesRaw.length
              ? serviceNamesRaw[i].toString()
              : '',
        ),
      );
    }
    return Appointment(
      id: doc.id,
      clientId: (data['clientId'] ?? '') as String,
      isOnlySale: data['isOnlySale'] == true,
      serviceItems: serviceItems,
      total: _parseTotal(data),
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      chargeDeposit: data['chargeDeposit'] == true,
      deposit: _parseDeposit(data),
      notes: data['notes'] as String?,
      addToCalendar: data['addToCalendar'] != false,
      calendarEventId: data['calendarEventId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'isOnlySale': isOnlySale,
      'serviceItems': serviceItems.map((e) => e.toMap()).toList(),
      'productItems': productItems.map((e) => e.toMap()).toList(),
      'total': total,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'chargeDeposit': chargeDeposit,
      'deposit': deposit,
      'notes': notes,
      'addToCalendar': addToCalendar,
      'calendarEventId': calendarEventId,
    };
  }
}
