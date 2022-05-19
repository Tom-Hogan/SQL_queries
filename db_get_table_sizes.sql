/* ================================================================================================
Purpose:
    Returns table sizes.
 
History:
    2008-06-06  Tom Hogan           Created.
================================================================================================ */
DECLARE @space_used table
(
    table_name     varchar(100)  NOT NULL,
    row_count      bigint        NULL,
    reserved_space varchar(1000) NULL,
    data_space     varchar(1000) NULL,
    index_size     varchar(1000) NULL,
    unused_space   varchar(1000) NULL
);


INSERT INTO @space_used
(
    table_name,
    row_count,
    reserved_space,
    data_space,
    index_size,
    unused_space
)
EXEC sys.sp_MSforeachtable 
    @command1 = 'sp_SpaceUsed ''?''';


SELECT      table_name,
            row_count,
            convert(decimal(15, 4), convert(decimal(15, 4), replace(reserved_space, ' KB', '')) / 1024) AS reserved_space_in_MB,
            convert(decimal(15, 4), convert(decimal(15, 4), replace(data_space, ' KB', '')) / 1024)     AS data_space_in_MB,
            convert(decimal(15, 4), convert(decimal(15, 4), replace(index_size, ' KB', '')) / 1024)     AS index_size_in_MB,
            convert(decimal(15, 4), convert(decimal(15, 4), replace(unused_space, ' KB', '')) / 1024)   AS unused_space_in_MB
FROM        @space_used
ORDER BY    reserved_space_in_MB DESC;
