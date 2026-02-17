import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/delete_constraint/delete_constraint_dialog.dart';
import '../../../core/delete_constraint/delete_constraint_result.dart';
import '../../../core/ui/components/app_list_tile_with_delete.dart';
import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/confirm_dialog.dart';
import '../../../core/ui/components/simple_add_dialog.dart';
import '../../../core/ui/widgets/error_view.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../data/product_brand_model.dart';
import 'product_brands_providers.dart';

class ProductBrandsScreen extends ConsumerStatefulWidget {
  const ProductBrandsScreen({super.key});

  @override
  ConsumerState<ProductBrandsScreen> createState() => _ProductBrandsScreenState();
}

class _ProductBrandsScreenState extends ConsumerState<ProductBrandsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final brandsAsync = ref.watch(productBrandsListProvider);
    final actionState = ref.watch(productBrandsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcas de produto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(
              label: 'Buscar marca',
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
              child: brandsAsync.when(
                loading: () => const LoadingView(),
                error: (err, _) => ErrorView(message: err.toString()),
                data: (brands) {
                  final filtered = _filterBrands(brands, _query);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma marca encontrada.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final brand = filtered[index];
                      return AppListTileWithDelete(
                        title: brand.name,
                        onDelete: () => _onDelete(context, brand),
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

  List<ProductBrand> _filterBrands(List<ProductBrand> brands, String query) {
    if (query.isEmpty) return brands;
    final q = query.toLowerCase();
    return brands.where((b) => b.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final repo = ref.read(productBrandsRepositoryProvider);
    if (repo == null) return;
    await showSimpleAddDialog<String>(
      context: context,
      title: 'Adicionar marca',
      label: 'Nome',
      onSubmit: (name) async {
        try {
          final item = ProductBrand(id: '', name: name);
          final id = await repo.create(item);
          if (id.isNotEmpty) {
            ref.invalidate(productBrandsListProvider);
            return id;
          }
        } catch (_) {}
        return null;
      },
    );
  }

  Future<void> _onDelete(BuildContext context, ProductBrand brand) async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Remover marca',
      message: 'Tem certeza que deseja remover a marca "${brand.name}"?',
    );
    if (!ok) return;
    final result = await ref
        .read(productBrandsControllerProvider.notifier)
        .delete(brand);
    if (!context.mounted) return;
    switch (result) {
      case DeleteConstraintViolation(
        :final entityName,
        :final linkDescription,
        :final linkedItems,
        :final howToProceed
      ):
        await showDeleteConstraintDialog(
          context: context,
          title: 'Nao foi possivel excluir',
          entityName: entityName,
          linkDescription: linkDescription,
          linkedItems: linkedItems,
          howToProceed: howToProceed,
        );
      case DeleteConstraintSuccess():
        break;
    }
  }
}
