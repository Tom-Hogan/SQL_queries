/* ================================================================================================
Purpose:
    Lists parameters for all projects and packages in the integration services catalog.

History:
    2025-03-04  Tom Hogan           Created.
    2025-04-01  Tom Hogan           Added connection manager logic based on this webpage:
                                    https://richardswinbank.net/ssis/catalog_parameters
================================================================================================ */
USE SSISDB;
SET NOCOUNT ON;


SELECT      par.parameter_id,
            f.name   AS folder_name,
            pro.name AS project_name,
            CASE
                WHEN par.object_type = 20
                    THEN 'Project'
                WHEN par.object_type = 30
                    THEN 'Package'
                WHEN par.object_type = 50
                    THEN 'System'
                ELSE ''
            END      AS parameter_type,
            par.object_name,
            par.parameter_name,
            CASE
                WHEN par.value_type = 'R'
                    THEN 'Referenced'
                WHEN par.value_type = 'V'
                    THEN 'Literal'
                ELSE ''
            END      AS value_type,
            par.required,
            par.sensitive,
            CASE
                WHEN par.parameter_name LIKE 'CM.%'
                    THEN 'Connection Manager'
                ELSE 'Parameter'
            END      AS configuration_page,
            CASE
                WHEN par.parameter_name LIKE 'CM.%'
                    THEN substring(par.parameter_name, 4, charindex('.', par.parameter_name, 4) - 4)
                ELSE par.parameter_name
            END      AS cleaned_name,
            CASE
                WHEN par.parameter_name LIKE 'CM.%'
                    THEN substring(par.parameter_name, charindex('.', par.parameter_name, 4) + 1, len(par.parameter_name))
                ELSE ''
            END      AS property,
            par.default_value,
            par.value_set,  /* 1 = overwritten ar run time */
            par.referenced_variable_name
FROM        catalog.object_parameters   AS par
JOIN        catalog.projects            AS pro  ON  pro.project_id = par.project_id
JOIN        catalog.folders             AS f    ON  f.folder_id = pro.folder_id
ORDER BY    f.name,
            pro.name,
            par.object_name,
            configuration_page DESC,
            par.parameter_name;


/* script parameter value creation statements */
/*
SELECT      'EXEC SSISDB.catalog.set_object_parameter_value' + char(10) + char(13)
            + '    @object_type = ' + convert(varchar(2), par.object_type) + ',' + char(10) + char(13)
            + '    @folder_name = N''' + f.name + ''',' + char(10) + char(13)
            + '    @project_name = N''' + pro.name + ''',' + char(10) + char(13)
            + '    @parameter_name = N''' + par.parameter_name + ''',' + char(10) + char(13)
            + '    @parameter_value = N''' + par.referenced_variable_name + ''',' + char(10) + char(13) 
            + '    @value_type = ' + par.value_type
            +   CASE
                    WHEN par.object_type = 30
                        THEN ',' + char(10) + char(13) + '    @object_name = N''' + par.object_name + ''';'
                    ELSE ';'
                END AS sql_command
FROM        catalog.object_parameters AS par
JOIN        catalog.projects          AS pro ON pro.project_id = par.project_id
JOIN        catalog.folders           AS f ON f.folder_id = pro.folder_id
WHERE       par.value_set = 1
ORDER BY    f.name,
            pro.name,
            par.object_name,
            par.parameter_name;

*/
