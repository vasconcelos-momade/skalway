-- Histórico de filiais na subscrição (auditoria / preparação para pró-rata).

CREATE TABLE `subscription_branch_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `subscriptionId` BIGINT UNSIGNED NOT NULL,
  `branchId` BIGINT UNSIGNED NOT NULL,
  `action` ENUM('ADD', 'REMOVE') NOT NULL,
  `effectiveDate` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `reason` TEXT NULL,
  `createdBy` BIGINT UNSIGNED NULL,
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  INDEX `subscription_branch_history_subscriptionId_effectiveDate_idx` (`subscriptionId`, `effectiveDate`),
  INDEX `subscription_branch_history_branchId_effectiveDate_idx` (`branchId`, `effectiveDate`),
  CONSTRAINT `subscription_branch_history_subscriptionId_fkey`
    FOREIGN KEY (`subscriptionId`) REFERENCES `subscriptions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `subscription_branch_history_branchId_fkey`
    FOREIGN KEY (`branchId`) REFERENCES `branches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `subscription_branch_history_createdBy_fkey`
    FOREIGN KEY (`createdBy`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
