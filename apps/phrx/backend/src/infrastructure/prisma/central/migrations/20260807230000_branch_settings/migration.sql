-- BranchSetting: configurações fiscais/comerciais por filial (Central)
CREATE TABLE `branch_settings` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tenantId` BIGINT UNSIGNED NOT NULL,
    `branchId` BIGINT UNSIGNED NOT NULL,
    `key` VARCHAR(191) NOT NULL,
    `value` JSON NOT NULL,
    `category` ENUM('IDENTIDADE', 'CONTACTO', 'FISCAL', 'DOCUMENTO', 'IMPRESSAO') NOT NULL,
    `description` TEXT NULL,
    `schemaVersion` INTEGER NOT NULL DEFAULT 1,
    `version` INTEGER NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `deletedAt` DATETIME(3) NULL,

    UNIQUE INDEX `branch_settings_branchId_key_key`(`branchId`, `key`),
    INDEX `branch_settings_tenantId_idx`(`tenantId`),
    INDEX `branch_settings_branchId_idx`(`branchId`),
    INDEX `branch_settings_tenantId_branchId_idx`(`tenantId`, `branchId`),
    INDEX `branch_settings_category_idx`(`category`),
    INDEX `branch_settings_deletedAt_idx`(`deletedAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `branch_settings`
  ADD CONSTRAINT `branch_settings_tenantId_fkey`
  FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`)
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `branch_settings`
  ADD CONSTRAINT `branch_settings_branchId_fkey`
  FOREIGN KEY (`branchId`) REFERENCES `branches`(`id`)
  ON DELETE CASCADE ON UPDATE CASCADE;
