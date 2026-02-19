import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;

import '../../clients/data/client_model.dart';
import 'appointment_model.dart';

/// Resultado da tentativa de criar evento na Google Agenda.
sealed class GoogleCalendarResult {
  const GoogleCalendarResult();
}

/// Evento criado com sucesso.
class GoogleCalendarSuccess extends GoogleCalendarResult {
  final String eventId;
  const GoogleCalendarSuccess(this.eventId);
}

/// Usuário cancelou o fluxo de autorização.
class GoogleCalendarUserCancelled extends GoogleCalendarResult {
  const GoogleCalendarUserCancelled();
}

/// Erro na criação (credenciais inválidas, rede, etc).
class GoogleCalendarError extends GoogleCalendarResult {
  final String message;
  const GoogleCalendarError(this.message);
}

/// Serviço de integração com Google Calendar.
///
/// Usa escopo mínimo [CalendarApi.calendarEventsScope] e solicita
/// autorização somente quando o usuário marca "Marcar na agenda".
/// Veja GOOGLE_CALENDAR_INTEGRATION.md para diretrizes de segurança.
class GoogleCalendarService {
  final String _webClientId;

  GoogleSignIn? _googleSignIn;
  GoogleSignIn get _signIn {
    _googleSignIn ??= GoogleSignIn(
      serverClientId: _webClientId.isEmpty ? null : _webClientId,
      scopes: [CalendarApi.calendarEventsScope],
    );
    return _googleSignIn!;
  }

  GoogleCalendarService({required String webClientId})
      : _webClientId = webClientId;

  /// Tenta obter cliente autenticado para a API do Calendar.
  /// Usa signInSilently primeiro (para quem já autorizou).
  /// Se falhar, usa signIn() para solicitar consentimento.
  Future<AuthClient?> _getAuthenticatedClient() async {
    var account = await _signIn.signInSilently();
    account ??= await _signIn.signIn();
    if (account == null) return null;
    return _signIn.authenticatedClient();
  }

  /// Cria um evento na Google Agenda do usuário.
  ///
  /// Título: "{firstName} {lastName} - {serviços separados por vírgula}"
  /// Data/hora: [appointment.scheduledAt]
  ///
  /// Retorna [GoogleCalendarSuccess] em caso de sucesso, ou um dos tipos
  /// de erro correspondentes.
  Future<GoogleCalendarResult> createEvent({
    required Appointment appointment,
    required Client client,
  }) async {
    if (!appointment.canAddToCalendar) {
      return const GoogleCalendarError(
        'Agendamento não é elegível para a agenda.',
      );
    }

    final clientAuth = await _getAuthenticatedClient();
    if (clientAuth == null) {
      return const GoogleCalendarUserCancelled();
    }

    try {
      final calendarApi = CalendarApi(clientAuth);

      final title = _buildEventTitle(client, appointment);
      final start = _toEventDateTime(appointment.scheduledAt);
      final end = _toEventDateTime(
        appointment.scheduledAt.add(const Duration(hours: 1)),
      );

      final event = Event(
        summary: title,
        start: EventDateTime(dateTime: start),
        end: EventDateTime(dateTime: end),
      );

      final created = await calendarApi.events.insert(event, 'primary');
      return GoogleCalendarSuccess(created.id ?? '');
    } catch (e) {
      final msg = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : e.toString();
      return GoogleCalendarError(
        msg.isEmpty ? 'Erro ao acessar a agenda' : msg,
      );
    } finally {
      clientAuth.close();
    }
  }

  String _buildEventTitle(Client client, Appointment appointment) {
    final clientName = '${client.firstName} ${client.lastName}'.trim();
    if (clientName.isEmpty) return 'Cliente';
    final services = appointment.serviceItems
        .map((s) => s.serviceName)
        .where((n) => n.isNotEmpty)
        .join(', ');
    if (services.isEmpty) return clientName;
    return '$clientName - $services';
  }

  /// Converte [DateTime] local para UTC (formato esperado pela API).
  DateTime _toEventDateTime(DateTime dt) {
    return dt.isUtc ? dt : dt.toUtc();
  }

  /// Remove um evento da Google Agenda.
  /// Ignora erros (ex.: evento já removido ou sem permissão).
  Future<void> deleteEvent(String eventId) async {
    if (eventId.isEmpty) return;
    final clientAuth = await _getAuthenticatedClient();
    if (clientAuth == null) return;
    try {
      final calendarApi = CalendarApi(clientAuth);
      await calendarApi.events.delete('primary', eventId);
    } catch (_) {
      // Ignora: evento pode já ter sido removido ou usuário revogou acesso
    } finally {
      clientAuth.close();
    }
  }

  /// Revoga o acesso à agenda (útil para logout ou configurações).
  Future<void> revokeAccess() async {
    await _signIn.signOut();
  }
}
