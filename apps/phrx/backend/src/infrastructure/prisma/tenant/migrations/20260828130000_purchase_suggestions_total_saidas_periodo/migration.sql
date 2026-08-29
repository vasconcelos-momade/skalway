ALTER TABLE `purchase_suggestions`
  ADD COLUMN `totalSaidasPeriodo` DECIMAL(14, 2) NOT NULL DEFAULT 0;

UPDATE `purchase_suggestions`
SET `totalSaidasPeriodo` = ROUND(`consumoMedioDiario` * 30);
