-- Alinha a FK da tabela renomeada com o schema Prisma (proformaInvoiceId).
-- A migração 20260708122000 só renomeou as tabelas e manteve a coluna `cotacaoId`.

ALTER TABLE `proforma_invoice_items`
  DROP FOREIGN KEY `cotacao_itens_cotacaoId_fkey`;

ALTER TABLE `proforma_invoice_items`
  DROP INDEX `cotacao_itens_cotacaoId_idx`;

ALTER TABLE `proforma_invoice_items`
  CHANGE COLUMN `cotacaoId` `proformaInvoiceId` BIGINT UNSIGNED NOT NULL;

CREATE INDEX `proforma_invoice_items_proformaInvoiceId_idx`
  ON `proforma_invoice_items`(`proformaInvoiceId`);

ALTER TABLE `proforma_invoice_items`
  ADD CONSTRAINT `proforma_invoice_items_proformaInvoiceId_fkey`
  FOREIGN KEY (`proformaInvoiceId`) REFERENCES `proforma_invoices`(`id`)
  ON DELETE CASCADE ON UPDATE CASCADE;
