/* ================================================================================================
Purpose:
    Steps to whitelist a CRL assembly.

History:
    2021-04-12  Tom Hogan       Taken from:
                                https://nielsberglund.com/2017/07/23/sql-server-2017-sqlclr---whitelisting-assemblies/
================================================================================================ */
USE master;
GO
RAISERROR(N'You want to run these sections one at a time.', 20, 1) WITH LOG;
GO

/*
    check configuration
*/
/*  turn on advanced options, if needed */
EXEC sys.sp_configure
    'show advanced options',
    1;
RECONFIGURE;
GO

/*  you want to see CLR enabled set to 1 */
EXEC sys.sp_configure;
GO

/*
-- command to  enable CLR, if not set
EXEC sys.sp_configure
    'clr_enabled',
    1;
RECONFIGURE;
GO
*/


/*
    right-click on assembly in SSMS and script as create
    take the assembly name and the varbinary of the hash from the output and paste into the variables below
*/


/*
    add assembly as trustworthy
*/
DECLARE @clr_name nvarchar(4000) = N'CLRSQL';
DECLARE @hash_binary varbinary(MAX) = 0x00;
DECLARE @hash varbinary(64);

SELECT  @hash = hashbytes('SHA2_512', @hash_binary);

EXEC sys.sp_add_trusted_assembly
    @hash = @hash,
    @description = @clr_name;


/*
    list trusted asemblies
*/
SELECT  *
FROM    sys.trusted_assemblies;
