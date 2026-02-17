import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
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

  ProductsController(this._repo) : super(const ProductsActionState());

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

  Future<void> delete(String id) async {
    if (_repo == null) return;
    state = const ProductsActionState(isLoading: true);
    try {
      await _repo.delete(id);
      state = const ProductsActionState();
    } catch (_) {
      state = const ProductsActionState(
        errorMessage: 'Não foi possível remover o produto.',
      );
    }
  }
}

final productsControllerProvider =
    StateNotifierProvider<ProductsController, ProductsActionState>((ref) {
      return ProductsController(ref.watch(productsRepositoryProvider));
    });

final productByIdProvider = FutureProvider.family<Product?, String>((ref, id) {
  final repo = ref.watch(productsRepositoryProvider);
  if (repo == null) return Future.value(null);
  return repo.getById(id);
});
