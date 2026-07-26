-- Remover colunas regulatórias legadas de `produtos`.
-- Fonte de verdade: `produto_regulacao`.

ALTER TABLE `produtos`
  DROP COLUMN `classificacaoAnarme`,
  DROP COLUMN `tipoDispensacao`,
  DROP COLUMN `requiresPrescription`,
  DROP COLUMN `requiresDoubleCheck`,
  DROP COLUMN `requiresPsychotropicBook`;
