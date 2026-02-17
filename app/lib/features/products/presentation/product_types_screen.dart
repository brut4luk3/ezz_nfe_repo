import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/delete_constraint/delete_constraint_dialog.dart';
import '../../../core/delete_constraint/delete_constraint_result.dart';
import '../../../core/ui/components/app_card.dart';
import '../../../core/ui/components/app_text_field.dart';
import '../../../core/ui/components/confirm_dialog.dart';
import '../../../core/ui/components/simple_add_dialog.dart';
import '../../../core/ui/widgets/error_view.dart';
import '../../../core/ui/widgets/loading_view.dart';
import '../data/product_type_model.dart';
import 'product_types_providers.dart';

class ProductTypesScreen extends ConsumerStatefulWidget {
  const ProductTypesScreen({super.key});

  @override
  ConsumerState<ProductTypesScreen> createState() => _ProductTypesScreenState();
}

class _ProductTypesScreenState extends ConsumerState<ProductTypesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(productTypesListProvider);
    final actionState = ref.watch(productTypesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipos de produto'),
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
              label: 'Buscar tipo',
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
              child: typesAsync.when(
                loading: () => const LoadingView(),
                error: (err, _) => ErrorView(message: err.toString()),
                data: (types) {
                  final filtered = _filterTypes(types, _query);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Nenhum tipo encontrado.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final type = filtered[index];
                      return AppCard(
                        child: ListTile(
                          title: Text(type.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _onDelete(context, type),
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

  List<ProductType> _filterTypes(List<ProductType> types, String query) {
    if (query.isEmpty) return types;
    final q = query.toLowerCase();
    return types.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final repo = ref.read(productTypesRepositoryProvider);
    if (repo == null) return;
    await showSimpleAddDialog<String>(
      context: context,
      title: 'Adicionar tipo',
      label: 'Nome',
      onSubmit: (name) async {
        try {
          final item = ProductType(id: '', name: name);
          final id = await repo.create(item);
          if (id.isNotEmpty) {
            ref.invalidate(productTypesListProvider);
            return id;
          }
        } catch (_) {}
        return null;
      },
    );
  }

  Future<void> _onDelete(BuildContext context, ProductType type) async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Remover tipo',
      message: 'Tem certeza que deseja remover o tipo "${type.name}"?',
    );
    if (!ok) return;
    final result = await ref
        .read(productTypesControllerProvider.notifier)
        .delete(type);
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
