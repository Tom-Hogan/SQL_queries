/* ================================================================================================
Purpose:
    Lists all the properties for the Integration Services Catalog.

History:
    2015-02-27  Tom Hogan           Created.
================================================================================================ */
USE SSISDB;
SET NOCOUNT ON;


/* check SSIS catalog properties */
SELECT  property_name,
        property_value
FROM    catalog.catalog_properties;


/*
/* command to change catalog properties */
EXEC catalog.configure_catalog 
    @property_name = N'RETENTION_WINDOW',
    @property_value = N'90';
-- */
