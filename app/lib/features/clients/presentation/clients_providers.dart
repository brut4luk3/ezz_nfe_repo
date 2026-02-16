import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../data/client_model.dart';
import '../data/clients_repository.dart';

final clientsListProvider = StreamProvider<List<Client>>((ref) {
  final repo = ref.watch(clientsRepositoryProvider);
  if (repo == null) return const Stream<List<Client>>.empty();
  return repo.watchAll();
});

class ClientsActionState {
  final bool isLoading;
  final String? errorMessage;

  const ClientsActionState({this.isLoading = false, this.errorMessage});
}

class ClientsController extends StateNotifier<ClientsActionState> {
  final ClientsRepository? _repo;

  ClientsController(this._repo) : super(const ClientsActionState());

  Future<String?> create(Client client) async {
    if (_repo == null) return null;
    state = const ClientsActionState(isLoading: true);
    try {
      final id = await _repo.create(client);
      state = const ClientsActionState();
      return id;
    } catch (_) {
      state = const ClientsActionState(
        errorMessage: 'Nao foi possivel salvar o cliente.',
      );
      return null;
    }
  }

  Future<void> update(String id, Client client) async {
    if (_repo == null) return;
    state = const ClientsActionState(isLoading: true);
    try {
      await _repo.update(id, client);
      state = const ClientsActionState();
    } catch (_) {
      state = const ClientsActionState(
        errorMessage: 'Nao foi possivel atualizar o cliente.',
      );
    }
  }

  Future<void> delete(String id) async {
    if (_repo == null) return;
    state = const ClientsActionState(isLoading: true);
    try {
      await _repo.delete(id);
      state = const ClientsActionState();
    } catch (_) {
      state = const ClientsActionState(
        errorMessage: 'Nao foi possivel remover o cliente.',
      );
    }
  }
}

final clientsControllerProvider =
    StateNotifierProvider<ClientsController, ClientsActionState>((ref) {
  return ClientsController(ref.watch(clientsRepositoryProvider));
});

final clientByIdProvider = FutureProvider.family<Client?, String>((ref, id) {
  final repo = ref.watch(clientsRepositoryProvider);
  if (repo == null) return Future.value(null);
  return repo.getById(id);
});
