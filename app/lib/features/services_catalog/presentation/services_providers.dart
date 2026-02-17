import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/delete_constraint/delete_constraint_result.dart';
import '../../../core/utils/formatters.dart';
import '../../appointments/data/appointments_repository.dart';
import '../data/service_item_model.dart';
import '../data/services_repository.dart';

final servicesListProvider = StreamProvider<List<ServiceItem>>((ref) {
  final repo = ref.watch(servicesRepositoryProvider);
  if (repo == null) return const Stream<List<ServiceItem>>.empty();
  return repo.watchAll();
});

class ServicesActionState {
  final bool isLoading;
  final String? errorMessage;

  const ServicesActionState({this.isLoading = false, this.errorMessage});
}

class ServicesController extends StateNotifier<ServicesActionState> {
  final ServicesRepository? _repo;
  final AppointmentsRepository? _appointmentsRepo;

  ServicesController(this._repo, this._appointmentsRepo)
      : super(const ServicesActionState());

  Future<String?> create(ServiceItem item) async {
    if (_repo == null) return null;
    state = const ServicesActionState(isLoading: true);
    try {
      final id = await _repo.create(item);
      state = const ServicesActionState();
      return id;
    } catch (_) {
      state = const ServicesActionState(
        errorMessage: 'Nao foi possivel salvar o servico.',
      );
      return null;
    }
  }

  Future<void> update(String id, ServiceItem item) async {
    if (_repo == null) return;
    state = const ServicesActionState(isLoading: true);
    try {
      await _repo.update(id, item);
      state = const ServicesActionState();
    } catch (_) {
      state = const ServicesActionState(
        errorMessage: 'Nao foi possivel atualizar o servico.',
      );
    }
  }

  Future<DeleteConstraintResult> delete(ServiceItem service) async {
    if (_repo == null) {
      return const DeleteConstraintSuccess();
    }
    state = const ServicesActionState(isLoading: true);
    try {
      final appointmentsRepo = _appointmentsRepo;
      if (appointmentsRepo != null) {
        final linked = await appointmentsRepo.getAppointmentsByServiceId(service.id);
        if (linked.isNotEmpty) {
          state = const ServicesActionState();
          return DeleteConstraintViolation(
            entityName: service.name,
            linkDescription: 'Este servico esta vinculado aos seguintes atendimentos:',
            linkedItems: linked
                .map((a) => 'Atendimento em ${formatDateTime(a.scheduledAt)}')
                .toList(),
            howToProceed:
                'Para excluir, edite cada atendimento listado e remova este servico. '
                'Depois tente excluir novamente.',
          );
        }
      }
      await _repo.delete(service.id);
      state = const ServicesActionState();
      return const DeleteConstraintSuccess();
    } catch (_) {
      state = const ServicesActionState(
        errorMessage: 'Nao foi possivel remover o servico.',
      );
      return const DeleteConstraintSuccess();
    }
  }
}

final servicesControllerProvider =
    StateNotifierProvider<ServicesController, ServicesActionState>((ref) {
  return ServicesController(
    ref.watch(servicesRepositoryProvider),
    ref.watch(appointmentsRepositoryProvider),
  );
});

final serviceByIdProvider =
    FutureProvider.family<ServiceItem?, String>((ref, id) {
  final repo = ref.watch(servicesRepositoryProvider);
  if (repo == null) return Future.value(null);
  return repo.getById(id);
});
