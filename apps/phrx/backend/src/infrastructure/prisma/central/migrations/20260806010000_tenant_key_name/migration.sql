-- Refactor Tenant domain fields:
-- nomeTenant → tenantKey, nomeEmpresa → tenantName, userId → ownerUserId

ALTER TABLE `tenants`
  DROP FOREIGN KEY `tenants_userId_fkey`,
  DROP INDEX `tenants_nomeTenant_key`,
  DROP INDEX `tenants_userId_idx`;

ALTER TABLE `tenants`
  CHANGE COLUMN `nomeTenant` `tenantKey` VARCHAR(191) NOT NULL,
  CHANGE COLUMN `nomeEmpresa` `tenantName` VARCHAR(191) NOT NULL,
  CHANGE COLUMN `userId` `ownerUserId` BIGINT UNSIGNED NOT NULL;

ALTER TABLE `tenants`
  ADD UNIQUE INDEX `tenants_tenantKey_key`(`tenantKey`),
  ADD INDEX `tenants_ownerUserId_idx`(`ownerUserId`);

ALTER TABLE `tenants`
  ADD CONSTRAINT `tenants_ownerUserId_fkey`
    FOREIGN KEY (`ownerUserId`) REFERENCES `users`(`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;
