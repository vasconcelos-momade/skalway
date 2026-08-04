-- Prep for prepaid multi-month billing (plans annual/monthly, coverage horizon).

ALTER TABLE `plans`
  ADD COLUMN `billingIntervalMonths` INT NOT NULL DEFAULT 1;

ALTER TABLE `subscriptions`
  ADD COLUMN `currentPeriodEnd` DATETIME(3) NULL,
  ADD COLUMN `autoRenew` BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE `payments`
  ADD COLUMN `monthsCovered` INT NULL;
