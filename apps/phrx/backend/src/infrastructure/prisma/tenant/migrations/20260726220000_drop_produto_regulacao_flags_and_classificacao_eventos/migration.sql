-- Drop redundant flags from produto_regulacao (tipoDispensacao is SSOT).
ALTER TABLE `produto_regulacao`
  DROP INDEX `produto_regulacao_requiresPrescription_idx`,
  DROP INDEX `produto_regulacao_requiresPsychotropicBook_idx`;

ALTER TABLE `produto_regulacao`
  DROP COLUMN `requiresPrescription`,
  DROP COLUMN `requiresPsychotropicBook`;

-- Drop classification event audit table (unused append-only history).
DROP TABLE IF EXISTS `produto_classificacao_eventos`;
