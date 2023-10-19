USE master;
GO


/* set file growth settings */
ALTER DATABASE model
    MODIFY FILE
    (
        NAME = 'modeldev',
        FILEGROWTH = 128MB
    );
ALTER DATABASE model
    MODIFY FILE
    (
        NAME = 'modellog',
        FILEGROWTH = 64MB
    );
GO


/* set recovery format to SIMPLE */
ALTER DATABASE model
    SET RECOVERY SIMPLE;
GO
