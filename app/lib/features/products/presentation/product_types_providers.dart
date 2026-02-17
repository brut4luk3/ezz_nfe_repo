import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/delete_constraint/delete_constraint_result.dart';
import '../data/product_type_model.dart';
import '../data/product_types_repository.dart';
import '../data/products_repository.dart';

final productTypesListProvider = StreamProvider<List<ProductType>>((ref) {
  final repo = ref.watch(productTypesRepositoryProvider);
  if (repo == null) return const Stream<List<ProductType>>.empty();
  return repo.watchAll();
});

class ProductTypesActionState {
  final bool isLoading;
  final String? errorMessage;

  const ProductTypesActionState({this.isLoading = false, this.errorMessage});
}

class ProductTypesController extends StateNotifier<ProductTypesActionState> {
  final ProductTypesRepository? _repo;
  final ProductsRepository? _productsRepo;

  ProductTypesController(this._repo, this._productsRepo)
      : super(const ProductTypesActionState());

  Future<DeleteConstraintResult> delete(ProductType productType) async {
    if (_repo == null) return const DeleteConstraintSuccess();
    state = const ProductTypesActionState(isLoading: true);
    try {
      final productsRepo = _productsRepo;
      if (productsRepo != null) {
        final linked = await productsRepo.getProductsByTypeId(productType.id);
        if (linked.isNotEmpty) {
          state = const ProductTypesActionState();
          return DeleteConstraintViolation(
            entityName: productType.name,
            linkDescription:
                'Este tipo esta vinculado aos seguintes produtos:',
            linkedItems: linked.map((p) => p.name).toList(),
            howToProceed:
                'Para excluir, edite cada produto listado e altere ou '
                'remova o tipo. Depois tente excluir novamente.',
          );
        }
      }
      await _repo.delete(productType.id);
      state = const ProductTypesActionState();
      return const DeleteConstraintSuccess();
    } catch (_) {
      state = const ProductTypesActionState(
        errorMessage: 'Nao foi possivel remover o tipo de produto.',
      );
      return const DeleteConstraintSuccess();
    }
  }
}

final productTypesControllerProvider =
    StateNotifierProvider<ProductTypesController, ProductTypesActionState>((ref) {
  return ProductTypesController(
    ref.watch(productTypesRepositoryProvider),
    ref.watch(productsRepositoryProvider),
  );
});
