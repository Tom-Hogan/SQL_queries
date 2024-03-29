/* ================================================================================================
Purpose:
    Creates a dimension table to hold currency data.

History:
    Based on original table in AdventureWorksDW2012
================================================================================================ */
SET NOCOUNT ON;


DROP TABLE IF EXISTS dbo.dim_currency;

CREATE TABLE dbo.dim_currency
(
    currency_id   int          IDENTITY(1, 1) NOT NULL,
    currency_code nchar(3)     NOT NULL,
    currency_name nvarchar(50) NOT NULL,
    CONSTRAINT dim_currency_pk
        PRIMARY KEY CLUSTERED ( currency_id ASC ),
    CONSTRAINT dim_currency_code_uq
        UNIQUE ( currency_code ASC )
);
GO
