/* ================================================================================================
Purpose:
    Example script to perform a full backup on the given database with a date only timestamp.  
    Performs a copy only full database backup.

History:
    2005-06-21  Tom Hogan           Created.
================================================================================================ */
DECLARE @full_path     varchar(250),
        @backup_path   varchar(150),
        @database_name nvarchar(128);

SET @backup_path = '\\File_Server\SQL_DB_Backups\DBA_scripts';  /* update with file path where the backup file will be placed */
SET @database_name = N'DBA_scripts';                            /* update with database name to be backed up */


/* build backup path */
IF right(@backup_path, 1) <> '\'
    SET @backup_path = @backup_path + '\';

SET @full_path = @backup_path + @database_name + '_co_' + convert(varchar(10), getdate(), 112) + '.bak';


/* perform full backup */
BEGIN TRY
    BACKUP DATABASE @database_name
        TO  DISK = @full_path
        WITH COMPRESSION,
             COPY_ONLY,
             STATS = 10;

    PRINT 'Database ' + @database_name + ' backed up to: ' + @full_path;
END TRY
BEGIN CATCH
    PRINT 'Backup of database ' + @database_name + ' failed!';
END CATCH;
