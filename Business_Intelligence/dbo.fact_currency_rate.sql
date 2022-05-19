/* ================================================================================================
Purpose:
    Creates a fact table to hold currency rates by date.

History:
    Based on original table in AdventureWorksDW2012
================================================================================================ */
SET NOCOUNT ON;


DROP TABLE IF EXISTS dbo.fact_currency_rate;

CREATE TABLE dbo.fact_currency_rate
(
    currency_id     int            NOT NULL,
    date_id         int            NOT NULL,
    average_rate    decimal(19, 4) NOT NULL,
    end_of_day_rate decimal(19, 4) NOT NULL,
    etl_audit_id    int            NULL,
    CONSTRAINT fact_currency_rate_pk
        PRIMARY KEY CLUSTERED ( currency_id ASC, date_id ASC )
);
GO
