-- Unicidade de email apenas entre utilizadores activos (deletedAt IS NULL).
-- Soft-deleted mantêm o email original para auditoria; várias linhas deleted podem
-- partilhar o mesmo email (emailActive = NULL, permitido em UNIQUE MySQL).

DROP INDEX `users_email_key` ON `users`;

ALTER TABLE `users`
  ADD COLUMN `emailActive` VARCHAR(191)
  GENERATED ALWAYS AS (IF(`deletedAt` IS NULL, `email`, NULL)) STORED;

CREATE UNIQUE INDEX `users_email_active_key` ON `users`(`emailActive`);

CREATE INDEX `users_email_idx` ON `users`(`email`);
