-- Regras regulatórias persistem em produto_regulacao (não em produtos).
ALTER TABLE `produto_regulacao`
  ADD COLUMN `requiresPrescription` BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN `requiresDoubleCheck` BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN `requiresPsychotropicBook` BOOLEAN NOT NULL DEFAULT false;

-- Backfill a partir de tipoDispensacao (fonte de derivação).
UPDATE `produto_regulacao`
SET
  `requiresPrescription` = CASE
    WHEN `tipoDispensacao` IN ('RECEITA_NORMAL', 'RECEITA_ESPECIAL') THEN true
    ELSE false
  END,
  `requiresDoubleCheck` = CASE
    WHEN `tipoDispensacao` = 'RECEITA_ESPECIAL' THEN true
    ELSE false
  END,
  `requiresPsychotropicBook` = CASE
    WHEN `tipoDispensacao` = 'RECEITA_ESPECIAL' THEN true
    ELSE false
  END;

CREATE INDEX `produto_regulacao_requiresPrescription_idx` ON `produto_regulacao`(`requiresPrescription`);
CREATE INDEX `produto_regulacao_requiresDoubleCheck_idx` ON `produto_regulacao`(`requiresDoubleCheck`);
CREATE INDEX `produto_regulacao_requiresPsychotropicBook_idx` ON `produto_regulacao`(`requiresPsychotropicBook`);
