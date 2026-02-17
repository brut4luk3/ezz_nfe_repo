import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../data/product_brand_model.dart';

final productBrandsListProvider = StreamProvider<List<ProductBrand>>((ref) {
  final repo = ref.watch(productBrandsRepositoryProvider);
  if (repo == null) return const Stream<List<ProductBrand>>.empty();
  return repo.watchAll();
});
