import 'package:flutter/material.dart';

/// Ícone de lixeira vermelho, independente do tema.
const Color kDeleteIconColor = Colors.red;

/// Lista item com conteúdo tappável, separador vertical e botão de exclusão à direita.
/// O ícone de delete fica próximo da borda direita do card.
class AppListTileWithDelete extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const AppListTileWithDelete({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
    required this.onDelete,
  });

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
                      maxLines: 1,
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
          icon: const Icon(Icons.delete, color: kDeleteIconColor),
          onPressed: onDelete,
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
