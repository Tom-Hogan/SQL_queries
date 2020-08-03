/* ================================================================================================
Purpose:
    Lists SQL Server version, patch level and edition.

History:
    2006-11-15  Tom Hogan           Created.
================================================================================================ */
USE master;


SELECT  serverproperty('MachineName')                               AS computer_name,
        serverproperty('ServerName')                                AS instance_name,
        serverproperty('Edition')                                   AS edition,
        substring(@@version, 11, charindex('(', @@version, 1) - 12) AS verson_name,
        serverproperty('ProductVersion')                            AS product_version,
        serverproperty('ProductLevel')                              AS product_level,
        serverproperty('ProductUpdateLevel')                        AS product_update,
        CASE
            WHEN serverproperty('IsClustered') = 1
                THEN 'Yes'
            ELSE 'No'
        END                                                         AS is_clustered,
        CASE
            WHEN serverproperty('IsHADREnabled') = 1
                THEN 'Y'
            ELSE 'No'
        END                                                         AS is_always_on_enabled
;
