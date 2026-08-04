-- Trial days on plan (invoice-at-creation billing model).

ALTER TABLE `plans`
  ADD COLUMN `trialDays` INT NOT NULL DEFAULT 14;
