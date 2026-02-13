import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
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

  ServicesController(this._repo) : super(const ServicesActionState());

  Future<void> create(ServiceItem item) async {
    if (_repo == null) return;
    state = const ServicesActionState(isLoading: true);
    try {
      await _repo.create(item);
      state = const ServicesActionState();
    } catch (_) {
      state = const ServicesActionState(
        errorMessage: 'Nao foi possivel salvar o servico.',
      );
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

  Future<void> delete(String id) async {
    if (_repo == null) return;
    state = const ServicesActionState(isLoading: true);
    try {
      await _repo.delete(id);
      state = const ServicesActionState();
    } catch (_) {
      state = const ServicesActionState(
        errorMessage: 'Nao foi possivel remover o servico.',
      );
    }
  }
}

final servicesControllerProvider =
    StateNotifierProvider<ServicesController, ServicesActionState>((ref) {
  return ServicesController(ref.watch(servicesRepositoryProvider));
});

final serviceByIdProvider =
    FutureProvider.family<ServiceItem?, String>((ref, id) {
  final repo = ref.watch(servicesRepositoryProvider);
  if (repo == null) return Future.value(null);
  return repo.getById(id);
});
