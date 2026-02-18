import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_text_field.dart';

class _MenuItem {
  final String route;
  final String label;
  final IconData icon;

  const _MenuItem(this.route, this.label, this.icon);
}

Future<void> showMenuDialog(BuildContext context) async {
  const items = [
    _MenuItem('/home', 'Início', Icons.home),
    _MenuItem('/clients', 'Clientes', Icons.people),
    _MenuItem('/products', 'Produtos', Icons.inventory_2),
    _MenuItem('/services', 'Serviços', Icons.design_services),
    _MenuItem('/appointments', 'Atendimentos', Icons.event),
    _MenuItem('/invoices', 'Notas', Icons.receipt_long),
  ];

  await showDialog<void>(
    context: context,
    builder: (context) => _MenuDialogContent(items: items),
  );
}

class _MenuDialogContent extends StatefulWidget {
  final List<_MenuItem> items;

  const _MenuDialogContent({required this.items});

  @override
  State<_MenuDialogContent> createState() => _MenuDialogContentState();
}

class _MenuDialogContentState extends State<_MenuDialogContent> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_MenuItem> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    return widget.items
        .where((i) => i.label.toLowerCase().contains(_query))
        .toList();
  }

  void _navigateAndClose(_MenuItem item) {
    Navigator.of(context).pop();
    context.go(item.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredItems;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: SizedBox(
        width: 400,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    'Menu',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Buscar',
                      controller: _searchController,
                      prefixIcon: const Icon(Icons.search),
                      textInputAction: TextInputAction.search,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhum item encontrado.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ListTile(
                                  leading: Icon(item.icon),
                                  title: Text(item.label),
                                  onTap: () => _navigateAndClose(item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
