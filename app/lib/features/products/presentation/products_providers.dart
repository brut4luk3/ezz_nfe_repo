import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/delete_constraint/delete_constraint_result.dart';
import '../../services_catalog/data/services_repository.dart';
import '../data/product_model.dart';
import '../data/products_repository.dart';

final productsListProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productsRepositoryProvider);
  if (repo == null) return const Stream<List<Product>>.empty();
  return repo.watchAll();
});

class ProductsActionState {
  final bool isLoading;
  final String? errorMessage;

  const ProductsActionState({this.isLoading = false, this.errorMessage});
}

class ProductsController extends StateNotifier<ProductsActionState> {
  final ProductsRepository? _repo;
  final ServicesRepository? _servicesRepo;

  ProductsController(this._repo, this._servicesRepo)
      : super(const ProductsActionState());

  Future<String?> create(Product product) async {
    if (_repo == null) return null;
    state = const ProductsActionState(isLoading: true);
    try {
      final id = await _repo.create(product);
      state = const ProductsActionState();
      return id;
    } catch (_) {
      state = const ProductsActionState(
        errorMessage: 'Não foi possível salvar o produto.',
      );
      return null;
    }
  }

  Future<void> update(String id, Product product) async {
    if (_repo == null) return;
    state = const ProductsActionState(isLoading: true);
    try {
      await _repo.update(id, product);
      state = const ProductsActionState();
    } catch (_) {
      state = const ProductsActionState(
        errorMessage: 'Não foi possível atualizar o produto.',
      );
    }
  }

  Future<DeleteConstraintResult> delete(Product product) async {
    if (_repo == null) return const DeleteConstraintSuccess();
    state = const ProductsActionState(isLoading: true);
    try {
      final servicesRepo = _servicesRepo;
      if (servicesRepo != null) {
        final linked = await servicesRepo.getServicesUsingProductId(product.id);
        if (linked.isNotEmpty) {
          state = const ProductsActionState();
          return DeleteConstraintViolation(
            entityName: product.name,
            linkDescription:
                'Este produto está vinculado aos seguintes serviços:',
            linkedItems: linked.map((s) => s.name).toList(),
            howToProceed:
                'Para excluir, edite cada serviço listado e remova este '
                'produto dos itens. Depois tente excluir novamente.',
          );
        }
      }
      await _repo.delete(product.id);
      state = const ProductsActionState();
      return const DeleteConstraintSuccess();
    } catch (_) {
      state = const ProductsActionState(
        errorMessage: 'Não foi possível remover o produto.',
      );
      return const DeleteConstraintSuccess();
    }
  }
}

final productsControllerProvider =
    StateNotifierProvider<ProductsController, ProductsActionState>((ref) {
  return ProductsController(
    ref.watch(productsRepositoryProvider),
    ref.watch(servicesRepositoryProvider),
  );
});

final productByIdProvider = FutureProvider.family<Product?, String>((ref, id) {
  final repo = ref.watch(productsRepositoryProvider);
  if (repo == null) return Future.value(null);
  return repo.getById(id);
});
