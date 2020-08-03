/* ================================================================================================
Purpose:
    Lists all packages deployed to the integration services catalog and their version numbers.

    *** Uncomment and update WHERE clause to filter results by catalog folder.

History:
    2018-12-18  Tom Hogan           Created.
================================================================================================ */
USE SSISDB;
SET NOCOUNT ON;


SELECT      f.name  AS folder_name,
            pr.name AS project_name,
            pa.name AS package_name,
            pa.version_major,
            pa.version_minor,
            pa.version_build,
            pr.object_version_lsn,
            pr.last_deployed_time,
            pr.deployed_by_name
FROM        catalog.folders     AS f
JOIN        catalog.projects    AS pr   ON  pr.folder_id = f.folder_id
JOIN        catalog.packages    AS pa   ON  pa.project_id = pr.project_id
            -- ------------------------------------------------------------------------------------------------
            -- to get contents of specifc catalog folder
            -- ------------------------------------------------------------------------------------------------
--WHERE       f.name = 'folder_name'
ORDER BY    f.name,
            pr.name,
            pa.name;
