import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/app_card.dart';
import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/confirm_dialog.dart';
import '../../../core/ui/widgets/error_view.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../../../core/utils/formatters.dart';
import '../data/product_brand_model.dart';
import '../data/product_model.dart';
import 'product_brands_providers.dart';
import 'products_providers.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final actionState = ref.watch(productsControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/products/new'),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(
              label: 'Buscar produto',
              prefixIcon: const Icon(Icons.search),
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            if (actionState.errorMessage != null)
              Text(
                actionState.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: productsAsync.when(
                loading: () => const LoadingView(),
                error: (err, _) => ErrorView(message: err.toString()),
                data: (items) {
                  final brands =
                      ref.watch(productBrandsListProvider).valueOrNull ?? [];
                  final filtered =
                      _filterProducts(items, _query, brands);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Nenhum produto encontrado.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return AppCard(
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            _subtitle(product, brands),
                          ),
                          onTap: () => context.go('/products/${product.id}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showConfirmDialog(
                                context: context,
                                title: 'Remover produto',
                                message:
                                    'Tem certeza que deseja remover este produto?',
                              );
                              if (!ok) return;
                              await ref
                                  .read(productsControllerProvider.notifier)
                                  .delete(product.id);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Product> _filterProducts(
    List<Product> items,
    String query,
    List<ProductBrand> brands,
  ) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items.where((p) {
      final name = p.name.toLowerCase();
      final brandName = _brandNameFor(p, brands);
      return name.contains(q) || brandName.toLowerCase().contains(q);
    }).toList();
  }

  String _brandNameFor(Product product, List<ProductBrand> brands) {
    if (product.brandId == null) {
      return product.brandDisplay(null);
    }
    try {
      final b = brands.firstWhere((b) => b.id == product.brandId);
      return product.brandDisplay(b.name);
    } catch (_) {
      return product.brandDisplay(null);
    }
  }

  String _subtitle(Product product, List<ProductBrand> brands) {
    final parts = <String>[
      _brandNameFor(product, brands),
      formatCurrencyValue(product.value),
    ];
    if (product.quantity != null && product.unit != null) {
      parts.add('${product.quantity} ${product.unit!.code}');
    }
    if (product.expiryDate != null) {
      parts.add('Val: ${product.expiryDate!.day.toString().padLeft(2, '0')}/${product.expiryDate!.month.toString().padLeft(2, '0')}/${product.expiryDate!.year}');
    }
    return parts.join(' • ');
  }
}
