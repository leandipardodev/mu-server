-- ============================================================
--  Crear login dedicado para el MuServer (MuEmu)
--  Ejecutar en SSMS o con sqlcmd. Es IDEMPOTENTE (se puede correr varias veces).
--
--  - Crea el login 'muuser'.
--  - Le da permisos de lectura/escritura y ejecucion en las bases existentes.
--
--  >>> Volvé a ejecutarlo DESPUÉS de crear las bases, para mapear el usuario. <<<
--  Antes de ejecutarlo, reemplazá el marcador por una clave única de al menos
--  16 caracteres. No guardes esa clave en el repositorio.
-- ============================================================

USE master;
GO

DECLARE @Login    sysname = N'muuser';
DECLARE @Password sysname = N'<SET_A_UNIQUE_PASSWORD>';
DECLARE @Sql      nvarchar(max);

IF @Password = N'<SET_A_UNIQUE_PASSWORD>' OR LEN(@Password) < 16
    THROW 50000, 'Seteá una clave única de al menos 16 caracteres antes de ejecutar este script.', 1;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @Login)
BEGIN
    SET @Sql = N'ALTER LOGIN ' + QUOTENAME(@Login) + N' WITH PASSWORD = ' +
               QUOTENAME(@Password, '''') + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
END
ELSE
BEGIN
    SET @Sql = N'CREATE LOGIN ' + QUOTENAME(@Login) + N' WITH PASSWORD = ' +
               QUOTENAME(@Password, '''') +
               N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF, DEFAULT_DATABASE = [master];';
END
EXEC sp_executesql @Sql;
GO

-- Dar acceso de runtime sin db_owner a cada base que exista
DECLARE @Login sysname = N'muuser';
DECLARE @db    sysname;
DECLARE @sql   nvarchar(max);
DECLARE cur CURSOR FOR
    SELECT name FROM sys.databases
    WHERE name IN (N'MuOnline', N'Me_MuOnline', N'Ranking', N'Events');

OPEN cur;
FETCH NEXT FROM cur INTO @db;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'USE [' + @db + N'];
        IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''' + @Login + N''')
            CREATE USER [' + @Login + N'] FOR LOGIN [' + @Login + N'];
        IF IS_ROLEMEMBER(N''db_owner'', N''' + @Login + N''') = 1
            ALTER ROLE db_owner DROP MEMBER [' + @Login + N'];
        IF IS_ROLEMEMBER(N''db_datareader'', N''' + @Login + N''') <> 1
            ALTER ROLE db_datareader ADD MEMBER [' + @Login + N'];
        IF IS_ROLEMEMBER(N''db_datawriter'', N''' + @Login + N''') <> 1
            ALTER ROLE db_datawriter ADD MEMBER [' + @Login + N'];
        GRANT EXECUTE ON SCHEMA::dbo TO [' + @Login + N'];';
    EXEC sp_executesql @sql;
    PRINT 'Acceso otorgado en: ' + @db;
    FETCH NEXT FROM cur INTO @db;
END
CLOSE cur;
DEALLOCATE cur;
GO

-- Verificación
SELECT name, type_desc, is_disabled
FROM sys.server_principals
WHERE name = N'muuser';
GO
