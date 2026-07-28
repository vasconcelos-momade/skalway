-- Separar DESPESA genérica em DESPESA_OPERACIONAL e COMPRA_ESTOQUE.
-- Expand enums → backfill → contract (sem perda de dados).

-- 1) Expand TipoCaixaMovimento
ALTER TABLE `caixa_movimentos`
  MODIFY COLUMN `tipo` ENUM(
    'VENDA',
    'SUPRIMENTO',
    'SANGRIA',
    'DESPESA',
    'ESTORNO',
    'DESPESA_OPERACIONAL',
    'COMPRA_ESTOQUE'
  ) NOT NULL;

-- 2a) Compra de estoque (origem COMPRA ou categoria COMPRA_STOCK)
UPDATE `caixa_movimentos`
SET `tipo` = 'COMPRA_ESTOQUE'
WHERE `tipo` = 'DESPESA'
  AND (`origem` = 'COMPRA' OR `categoria` = 'COMPRA_STOCK');

-- 2b) Restantes DESPESA → DESPESA_OPERACIONAL
UPDATE `caixa_movimentos`
SET `tipo` = 'DESPESA_OPERACIONAL'
WHERE `tipo` = 'DESPESA';

-- 3) Expand OrigemCaixaMovimentacao
ALTER TABLE `caixa_movimentos`
  MODIFY COLUMN `origem` ENUM(
    'FATURA',
    'SUPRIMENTO',
    'SANGRIA',
    'DESPESA',
    'ESTORNO',
    'AJUSTE',
    'PEDIDO',
    'COMPRA',
    'PAGAMENTO',
    'REFORCO',
    'OUTRO',
    'DESPESA_OPERACIONAL',
    'COMPRA_ESTOQUE'
  ) NULL;

UPDATE `caixa_movimentos`
SET `origem` = 'COMPRA_ESTOQUE'
WHERE `origem` = 'COMPRA';

UPDATE `caixa_movimentos`
SET `origem` = 'DESPESA_OPERACIONAL'
WHERE `origem` = 'DESPESA';

-- Alinhar origem ao tipo quando ainda legado/nulo
UPDATE `caixa_movimentos`
SET `origem` = 'COMPRA_ESTOQUE'
WHERE `tipo` = 'COMPRA_ESTOQUE'
  AND (`origem` IS NULL OR `origem` IN ('OUTRO', 'AJUSTE'));

UPDATE `caixa_movimentos`
SET `origem` = 'DESPESA_OPERACIONAL'
WHERE `tipo` = 'DESPESA_OPERACIONAL'
  AND (`origem` IS NULL OR `origem` IN ('OUTRO', 'AJUSTE'));

-- 4) Contract enums (remover DESPESA e COMPRA)
ALTER TABLE `caixa_movimentos`
  MODIFY COLUMN `tipo` ENUM(
    'VENDA',
    'SUPRIMENTO',
    'SANGRIA',
    'DESPESA_OPERACIONAL',
    'COMPRA_ESTOQUE',
    'ESTORNO'
  ) NOT NULL;

ALTER TABLE `caixa_movimentos`
  MODIFY COLUMN `origem` ENUM(
    'FATURA',
    'SUPRIMENTO',
    'SANGRIA',
    'DESPESA_OPERACIONAL',
    'COMPRA_ESTOQUE',
    'ESTORNO',
    'AJUSTE',
    'PEDIDO',
    'PAGAMENTO',
    'REFORCO',
    'OUTRO'
  ) NULL;
