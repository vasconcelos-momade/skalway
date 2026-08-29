-- AlterTable
ALTER TABLE `purchase_suggestions`
  ADD COLUMN `quantidadeAprovada` DECIMAL(14, 2) NOT NULL DEFAULT 0 AFTER `quantidadeSugerida`;
