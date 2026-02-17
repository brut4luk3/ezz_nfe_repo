import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../data/product_type_model.dart';

final productTypesListProvider = StreamProvider<List<ProductType>>((ref) {
  final repo = ref.watch(productTypesRepositoryProvider);
  if (repo == null) return const Stream<List<ProductType>>.empty();
  return repo.watchAll();
});
