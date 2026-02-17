import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/delete_constraint/delete_constraint_result.dart';
import '../data/product_brand_model.dart';
import '../data/product_brands_repository.dart';
import '../data/products_repository.dart';

final productBrandsListProvider = StreamProvider<List<ProductBrand>>((ref) {
  final repo = ref.watch(productBrandsRepositoryProvider);
  if (repo == null) return const Stream<List<ProductBrand>>.empty();
  return repo.watchAll();
});

class ProductBrandsActionState {
  final bool isLoading;
  final String? errorMessage;

  const ProductBrandsActionState({this.isLoading = false, this.errorMessage});
}

class ProductBrandsController extends StateNotifier<ProductBrandsActionState> {
  final ProductBrandsRepository? _repo;
  final ProductsRepository? _productsRepo;

  ProductBrandsController(this._repo, this._productsRepo)
      : super(const ProductBrandsActionState());

  Future<DeleteConstraintResult> delete(ProductBrand productBrand) async {
    if (_repo == null) return const DeleteConstraintSuccess();
    state = const ProductBrandsActionState(isLoading: true);
    try {
      final productsRepo = _productsRepo;
      if (productsRepo != null) {
        final linked = await productsRepo.getProductsByBrandId(productBrand.id);
        if (linked.isNotEmpty) {
          state = const ProductBrandsActionState();
          return DeleteConstraintViolation(
            entityName: productBrand.name,
            linkDescription:
                'Esta marca esta vinculada aos seguintes produtos:',
            linkedItems: linked.map((p) => p.name).toList(),
            howToProceed:
                'Para excluir, edite cada produto listado e altere ou '
                'remova a marca. Depois tente excluir novamente.',
          );
        }
      }
      await _repo.delete(productBrand.id);
      state = const ProductBrandsActionState();
      return const DeleteConstraintSuccess();
    } catch (_) {
      state = const ProductBrandsActionState(
        errorMessage: 'Nao foi possivel remover a marca.',
      );
      return const DeleteConstraintSuccess();
    }
  }
}

final productBrandsControllerProvider =
    StateNotifierProvider<ProductBrandsController, ProductBrandsActionState>((ref) {
  return ProductBrandsController(
    ref.watch(productBrandsRepositoryProvider),
    ref.watch(productsRepositoryProvider),
  );
});
