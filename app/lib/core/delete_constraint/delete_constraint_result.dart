/// Resultado de uma tentativa de exclusão.
///
/// Quando há vínculos que impedem a exclusão, use [DeleteConstraintViolation]
/// para informar o usuário exatamente o que está vinculado e como proceder.
///
/// Padrão: sempre verificar vínculos antes de deletar entidades referenciadas.
sealed class DeleteConstraintResult {
  const DeleteConstraintResult();
}

/// Exclusão realizada com sucesso.
class DeleteConstraintSuccess extends DeleteConstraintResult {
  const DeleteConstraintSuccess();
}

/// Exclusão bloqueada por vínculos existentes.
class DeleteConstraintViolation extends DeleteConstraintResult {
  /// Nome da entidade que está sendo excluída (ex: "Cliente João Silva").
  final String entityName;

  /// Tipo de vínculo em linguagem clara (ex: "clientes que têm este indicador").
  final String linkDescription;

  /// Lista de itens vinculados para exibir ao usuário
  /// (ex: ["Cliente Maria", "Cliente Pedro"]).
  final List<String> linkedItems;

  /// Orientação de como proceder para conseguir excluir
  /// (ex: "Remova ou altere a indicação nos clientes listados.").
  final String howToProceed;

  const DeleteConstraintViolation({
    required this.entityName,
    required this.linkDescription,
    required this.linkedItems,
    required this.howToProceed,
  });
}
