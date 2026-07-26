-- Grants para o user da app criar/usar bases tenant_* (MULTI-TENANT).
-- MYSQL_USER (admin) só recebe ALL na MYSQL_DATABASE por defeito do image MySQL.
GRANT CREATE ON *.* TO 'admin'@'%';
FLUSH PRIVILEGES;
