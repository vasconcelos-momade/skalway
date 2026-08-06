-- Desconto comercial nas facturas SaaS da Central.

ALTER TABLE `invoices`
  ADD COLUMN `discount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 AFTER `amount`;
