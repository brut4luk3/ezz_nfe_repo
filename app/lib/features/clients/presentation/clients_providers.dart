import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/delete_constraint/delete_constraint_result.dart';
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

  Future<DeleteConstraintResult> delete(Client client) async {
    if (_repo == null) {
      return const DeleteConstraintSuccess();
    }
    state = const ClientsActionState(isLoading: true);
    try {
      final linked = await _repo.getClientsWithIndicatorId(client.id);
      if (linked.isNotEmpty) {
        state = const ClientsActionState();
        return DeleteConstraintViolation(
          entityName: client.name,
          linkDescription: 'Este cliente é indicador dos seguintes clientes:',
          linkedItems: linked.map((c) => c.name).toList(),
          howToProceed:
              'Para excluir, acesse cada cliente listado, remova ou altere '
              'o indicador, e então tente excluir novamente.',
        );
      }
      await _repo.delete(client.id);
      state = const ClientsActionState();
      return const DeleteConstraintSuccess();
    } catch (_) {
      state = const ClientsActionState(
        errorMessage: 'Nao foi possivel remover o cliente.',
      );
      return const DeleteConstraintSuccess();
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
