import 'package:flutter/material.dart';

/// Opção exibida no diálogo de ações.
class AppListTileOption {
  final String value;
  final String label;
  final IconData? icon;

  const AppListTileOption({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Lista item com conteúdo tappável, separador vertical e botão de opções à direita.
/// Mantém a mesma estética de [AppListTileWithDelete], mas abre um diálogo com
/// as opções disponíveis em vez de um ícone de exclusão direto.
class AppListTileWithOptions extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final List<AppListTileOption> options;
  final Future<void> Function(String value)? onOptionSelected;

  const AppListTileWithOptions({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
    required this.options,
    this.onOptionSelected,
  });

  Future<void> _showOptionsDialog(BuildContext context) async {
    if (options.isEmpty) return;
    final value = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Opções'),
        children: options
            .map(
              (opt) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(opt.value),
                child: Row(
                  children: [
                    if (opt.icon != null) ...[
                      Icon(opt.icon),
                      const SizedBox(width: 16),
                    ],
                    Text(opt.label),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (value != null && context.mounted && onOptionSelected != null) {
      await onOptionSelected!(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: IntrinsicHeight(
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: 12),
          color: Theme.of(context).dividerColor,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: options.isEmpty ? null : () => _showOptionsDialog(context),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.only(left: 12, right: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
