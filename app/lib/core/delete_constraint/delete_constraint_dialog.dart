import 'package:flutter/material.dart';

import '../ui/components/delete_constraint_dialog_content.dart';

/// Exibe um diálogo informativo quando a exclusão é bloqueada por vínculos.
///
/// Mostra exatamente quais itens estão vinculados e orienta o usuário
/// sobre como proceder para conseguir excluir.
Future<void> showDeleteConstraintDialog({
  required BuildContext context,
  required String title,
  required String entityName,
  required String linkDescription,
  required List<String> linkedItems,
  required String howToProceed,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: DeleteConstraintDialogContent(
        entityName: entityName,
        linkDescription: linkDescription,
        linkedItems: linkedItems,
        howToProceed: howToProceed,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}
