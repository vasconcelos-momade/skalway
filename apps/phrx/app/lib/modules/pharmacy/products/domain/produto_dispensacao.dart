const List<String> produtoTipoDispensacaoValues = <String>[
  'VENDA_LIVRE',
  'RECEITA_NORMAL',
  'RECEITA_ESPECIAL',
];

String produtoTipoDispensacaoLabel(String tipo) {
  switch (tipo) {
    case 'VENDA_LIVRE':
      return 'Venda livre';
    case 'RECEITA_NORMAL':
      return 'Receita normal';
    case 'RECEITA_ESPECIAL':
      return 'Receita especial';
  }
  switch (tipo) {
    case 'RECEITA_SIMPLES':
    case 'RECEITA_CONTROLADA':
    case 'RECEITA_OBRIGATORIA':
    case 'RECEITA_RETIDA':
      return 'Receita normal';
    case 'PSICOTROPICO':
    case 'NARCOTICO':
      return 'Receita especial';
    default:
      return tipo;
  }
}

/// Resumo das regras derivadas (apenas UI; o backend calcula a política completa).
String produtoDispensacaoDerivedSummary(String tipo) {
  switch (tipo) {
    case 'VENDA_LIVRE':
      return 'Sem receita nem livros regulatórios.';
    case 'RECEITA_NORMAL':
      return 'Receita obrigatória • registo no Livro de Receitas.';
    case 'RECEITA_ESPECIAL':
      return 'Receita obrigatória • dupla validação • Livro de Receitas e Psicotrópicos.';
    case 'RECEITA_SIMPLES':
    case 'RECEITA_CONTROLADA':
    case 'RECEITA_OBRIGATORIA':
    case 'RECEITA_RETIDA':
      return 'Receita obrigatória • registo no Livro de Receitas.';
    case 'PSICOTROPICO':
    case 'NARCOTICO':
      return 'Receita obrigatória • dupla validação • Livro de Receitas e Psicotrópicos.';
    default:
      return '';
  }
}
