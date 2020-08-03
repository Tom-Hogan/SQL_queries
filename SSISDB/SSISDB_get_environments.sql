/* ================================================================================================
Purpose:
    Lists all integration services catalog environments and their associated variables by folder.

History:
    2018-12-18  Tom Hogan           Created.
================================================================================================ */
USE SSISDB;
SET NOCOUNT ON;


SELECT      f.name          AS folder_name,
            e.name          AS environment_name,
            e.description   AS environment_description,
            v.name,
            v.description,
            v.type,
            v.sensitive,
            v.value
FROM        catalog.folders                 AS f
LEFT JOIN   catalog.environments            AS e    ON  e.folder_id = f.folder_id
LEFT JOIN   catalog.environment_variables   AS v    ON  v.environment_id = e.environment_id
ORDER BY    f.name,
            e.name,
            v.name;


-- environment references
 /*
SELECT      f.name  AS folder_name,
            pr.name AS project_name,
            er.environment_name,
            CASE
                WHEN er.reference_type = 'A'
                    THEN 'Absolute'
                ELSE 'Relative'
            END     AS reference_type,
            er.environment_folder_name
FROM        catalog.folders                 AS f
JOIN        catalog.projects                AS pr   ON  pr.folder_id = f.folder_id
JOIN        catalog.environment_references  AS er   ON  er.project_id = pr.project_id
ORDER BY    f.name,
            pr.name,
            er.environment_name;
-- */
