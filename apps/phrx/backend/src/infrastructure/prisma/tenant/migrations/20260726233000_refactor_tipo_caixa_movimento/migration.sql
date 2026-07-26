-- TipoCaixaMovimento: ENTRADA/SAIDA → VENDA/DESPESA (+ manter SUPRIMENTO/SANGRIA/ESTORNO)
-- Expand enum, backfill, contract.

ALTER TABLE `caixa_movimentos`
  MODIFY COLUMN `tipo` ENUM(
    'ENTRADA',
    'SAIDA',
    'VENDA',
    'SUPRIMENTO',
    'SANGRIA',
    'DESPESA',
    'ESTORNO'
  ) NOT NULL;

-- Vendas / entradas de liquidação → VENDA
UPDATE `caixa_movimentos`
SET `tipo` = 'VENDA'
WHERE `tipo` = 'ENTRADA';

-- Saídas manuais → DESPESA; anulações de fatura (descricao ESTORNO) → ESTORNO
UPDATE `caixa_movimentos`
SET `tipo` = 'ESTORNO'
WHERE `tipo` = 'SAIDA'
  AND (`descricao` LIKE 'ESTORNO%' OR `descricao` LIKE '%Anulação%' OR `descricao` LIKE '%Anulacao%');

UPDATE `caixa_movimentos`
SET `tipo` = 'DESPESA'
WHERE `tipo` = 'SAIDA';

ALTER TABLE `caixa_movimentos`
  MODIFY COLUMN `tipo` ENUM(
    'VENDA',
    'SUPRIMENTO',
    'SANGRIA',
    'DESPESA',
    'ESTORNO'
  ) NOT NULL;

-- Origem: expand + mapear legados para valores canónicos (mantém valores antigos no enum).
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
    'OUTRO'
  ) NULL;

UPDATE `caixa_movimentos` SET `origem` = 'FATURA' WHERE `origem` IN ('PAGAMENTO', 'PEDIDO');
UPDATE `caixa_movimentos` SET `origem` = 'SUPRIMENTO' WHERE `origem` = 'REFORCO';
UPDATE `caixa_movimentos` SET `origem` = 'DESPESA' WHERE `origem` = 'COMPRA';
UPDATE `caixa_movimentos` SET `origem` = 'ESTORNO' WHERE `tipo` = 'ESTORNO' AND (`origem` IS NULL OR `origem` = 'OUTRO');
UPDATE `caixa_movimentos` SET `origem` = 'SANGRIA' WHERE `tipo` = 'SANGRIA' AND (`origem` IS NULL OR `origem` NOT IN ('SANGRIA'));
UPDATE `caixa_movimentos` SET `origem` = 'SUPRIMENTO' WHERE `tipo` = 'SUPRIMENTO' AND (`origem` IS NULL OR `origem` NOT IN ('SUPRIMENTO','REFORCO'));
UPDATE `caixa_movimentos` SET `origem` = 'DESPESA' WHERE `tipo` = 'DESPESA' AND (`origem` IS NULL OR `origem` IN ('OUTRO'));
UPDATE `caixa_movimentos` SET `origem` = 'FATURA' WHERE `tipo` = 'VENDA' AND (`origem` IS NULL OR `origem` IN ('OUTRO','PAGAMENTO','PEDIDO'));
