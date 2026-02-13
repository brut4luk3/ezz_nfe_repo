import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../data/invoice_model.dart';
import '../data/invoices_repository.dart';

final invoicesListProvider = StreamProvider<List<Invoice>>((ref) {
  final repo = ref.watch(invoicesRepositoryProvider);
  if (repo == null) return const Stream<List<Invoice>>.empty();
  return repo.watchAll();
});

class InvoicesActionState {
  final bool isLoading;
  final String? errorMessage;

  const InvoicesActionState({this.isLoading = false, this.errorMessage});
}

class InvoicesController extends StateNotifier<InvoicesActionState> {
  final InvoicesRepository? _repo;

  InvoicesController(this._repo) : super(const InvoicesActionState());

  Future<void> create(Invoice invoice) async {
    if (_repo == null) return;
    state = const InvoicesActionState(isLoading: true);
    try {
      await _repo.create(invoice);
      state = const InvoicesActionState();
    } catch (_) {
      state = const InvoicesActionState(
        errorMessage: 'Nao foi possivel gerar a nota.',
      );
    }
  }

  Future<void> delete(String id) async {
    if (_repo == null) return;
    state = const InvoicesActionState(isLoading: true);
    try {
      await _repo.delete(id);
      state = const InvoicesActionState();
    } catch (_) {
      state = const InvoicesActionState(
        errorMessage: 'Nao foi possivel remover a nota.',
      );
    }
  }
}

final invoicesControllerProvider =
    StateNotifierProvider<InvoicesController, InvoicesActionState>((ref) {
  return InvoicesController(ref.watch(invoicesRepositoryProvider));
});
