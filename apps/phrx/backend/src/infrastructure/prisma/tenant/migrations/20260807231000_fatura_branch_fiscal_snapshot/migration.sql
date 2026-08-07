-- Snapshot fiscal da filial na fatura (imutável após emissão)
ALTER TABLE `faturas`
  ADD COLUMN `branchId` BIGINT UNSIGNED NULL,
  ADD COLUMN `branchNome` VARCHAR(191) NULL,
  ADD COLUMN `branchNuit` VARCHAR(64) NULL,
  ADD COLUMN `branchEmail` VARCHAR(191) NULL,
  ADD COLUMN `branchTelefone` VARCHAR(64) NULL,
  ADD COLUMN `branchEndereco` TEXT NULL,
  ADD COLUMN `branchLogo` TEXT NULL;

CREATE INDEX `faturas_branchId_idx` ON `faturas`(`branchId`);
