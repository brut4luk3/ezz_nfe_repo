import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../data/appointment_model.dart';
import '../data/appointments_repository.dart';
import '../data/google_calendar_service.dart';

final appointmentsListProvider = StreamProvider<List<Appointment>>((ref) {
  final repo = ref.watch(appointmentsRepositoryProvider);
  if (repo == null) return const Stream<List<Appointment>>.empty();
  return repo.watchAll();
});

class AppointmentsActionState {
  final bool isLoading;
  final String? errorMessage;

  const AppointmentsActionState({this.isLoading = false, this.errorMessage});
}

class AppointmentsController extends StateNotifier<AppointmentsActionState> {
  final AppointmentsRepository? _repo;
  final GoogleCalendarService _calendarService;

  AppointmentsController(this._repo, this._calendarService)
      : super(const AppointmentsActionState());

  Future<String?> create(Appointment appointment) async {
    if (_repo == null) return null;
    state = const AppointmentsActionState(isLoading: true);
    try {
      final id = await _repo.create(appointment);
      state = const AppointmentsActionState();
      return id;
    } catch (_) {
      state = const AppointmentsActionState(
        errorMessage: 'Nao foi possivel salvar o atendimento.',
      );
      return null;
    }
  }

  Future<void> update(String id, Appointment appointment) async {
    if (_repo == null) return;
    state = const AppointmentsActionState(isLoading: true);
    try {
      await _repo.update(id, appointment);
      state = const AppointmentsActionState();
    } catch (_) {
      state = const AppointmentsActionState(
        errorMessage: 'Nao foi possivel atualizar o atendimento.',
      );
    }
  }

  Future<void> delete(String id) async {
    if (_repo == null) return;
    state = const AppointmentsActionState(isLoading: true);
    try {
      final appt = await _repo.getById(id);
      final eventId = appt?.calendarEventId;
      if (eventId != null && eventId.isNotEmpty) {
        await _calendarService.deleteEvent(eventId);
      }
      await _repo.delete(id);
      state = const AppointmentsActionState();
    } catch (_) {
      state = const AppointmentsActionState(
        errorMessage: 'Nao foi possivel remover o atendimento.',
      );
    }
  }
}

final appointmentsControllerProvider =
    StateNotifierProvider<AppointmentsController, AppointmentsActionState>(
        (ref) {
  return AppointmentsController(
    ref.watch(appointmentsRepositoryProvider),
    ref.watch(googleCalendarServiceProvider),
  );
});

final appointmentByIdProvider =
    FutureProvider.family<Appointment?, String>((ref, id) {
  final repo = ref.watch(appointmentsRepositoryProvider);
  if (repo == null) return Future.value(null);
  return repo.getById(id);
});
