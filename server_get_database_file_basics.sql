/* ================================================================================================
Purpose:
    Lists current file sizes for all databases.
 
History:
    2005-09-21  Tom Hogan           Created.
    2007-07-05  Tom Hogan           Updated for use with 2005 sys views.
    2017-02-17  Tom Hogan           Updated to use new sys views.
================================================================================================ */
USE master;


SELECT      d.name                                  AS database_name,
            mf.name                                 AS logical_name,
            mf.physical_name,
            mf.type_desc                            AS file_type,
            cast(( sum(mf.size) OVER ( PARTITION BY d.name
                                       ORDER BY d.name
                                     )
                 ) / 128.0 AS decimal(15, 2))       AS database_size_in_MB,
            cast(mf.size / 128.0 AS decimal(15, 2)) AS size_in_MB,
            CASE
                WHEN mf.max_size = -1
                    THEN 'Unlimited'
                ELSE cast(( mf.max_size / 128 ) AS varchar(20)) + ' MB'
            END                                     AS max_size,
            CASE
                WHEN mf.is_percent_growth = 1
                    THEN cast(( mf.growth ) AS varchar(20)) + '%'
                ELSE cast(( mf.growth / 128 ) AS varchar(20)) + ' MB'
            END                                     AS current_growth,
            mf.is_read_only,
            mf.is_sparse,
            mf.is_percent_growth
FROM        sys.master_files    AS mf
JOIN        sys.databases       AS d    ON  d.database_id = mf.database_id
--WHERE       mf.is_percent_growth = 1
ORDER BY    d.name,
            mf.type_desc DESC;
