-- Snapshot cidade/província da filial na fatura (imutável após emissão)
ALTER TABLE `faturas`
  ADD COLUMN `branchCidade` VARCHAR(191) NULL,
  ADD COLUMN `branchProvincia` VARCHAR(191) NULL;
