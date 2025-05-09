/* ================================================================================================
Purpose:
    Creates a dimension table to hold date data.  Uses variables to define the start and end values
    for the date range to be held in the table.

Notes:
    1. Need to update start date, end date, and first fiscal month variables for initial data.
    2. Tally CTE based on work done by Dwain Camps

History:
    2012-02-07  Tom Hogan           Created.
================================================================================================ */
SET NOCOUNT ON;


/*
    create table
    number columns are generally used for sorting
*/
DROP TABLE IF EXISTS dbo.dim_date;

CREATE TABLE dbo.dim_date
(
    date_id               int           NOT NULL,
    calendar_date         date          NOT NULL,
    day_of_week_number    int           NOT NULL,   /* 1 = first day of week */
    day_of_week_name      char(3)       NOT NULL,   /* Tue */
    week_number           int           NOT NULL,   /* 1, 2, 3, etc. */
    week_name             char(5)       NOT NULL,   /* Wk 01 */
    week_year             char(10)      NOT NULL,   /* Wk 01 2020 */
    month_number          int           NOT NULL,   /* 1, 2, 3, etc. */
    month_name            char(3)       NOT NULL,   /* Jan */
    month_year            char(8)       NOT NULL,   /* Jan 2020 */
    month_start_date      date          NOT NULL,
    month_end_date        date          NOT NULL,
    quarter_number        int           NOT NULL,   /* 1, 2, etc. */
    quarter_name          char(3)       NOT NULL,   /* Q1 */
    quarter_year          char(7)       NOT NULL,   /* Q1 2020 */
    quarter_start_date    date          NOT NULL,
    quarter_end_date      date          NOT NULL,
    year_number           int           NOT NULL,   /* 2020 */
    year_name             char(4)       NOT NULL,   /* 2020 */
    year_start_date       date          NOT NULL,
    year_end_date         date          NOT NULL,
    /* add business / fiscal date columns */
    fiscal_month_number   smallint      NOT NULL,   /* 1, 2, 3, etc.*/
    fiscal_month_name     char(3)       NOT NULL,   /* Jan */
    fiscal_month_year     char(8)       NOT NULL,   /* Jan 2020 */
    fiscal_quarter_number smallint      NOT NULL,   /* 1, 2, etc.*/
    fiscal_quarter_name   char(3)       NOT NULL,   /* FQ1*/
    fiscal_quarter_year   char(8)       NOT NULL,   /* FQ1 2020 */
    fiscal_year_number    int           NOT NULL,   /* 2020 */
    fiscal_year_name      char(7)       NOT NULL,   /* FY 2020 */
    business_day_value    decimal(5, 2) NOT NULL,
    CONSTRAINT dim_time_pk
        PRIMARY KEY CLUSTERED ( date_id ASC )
);
GO

/* index(es) */
CREATE UNIQUE NONCLUSTERED INDEX ix_dim_date_calendar_date
    ON dbo.dim_date ( calendar_date ASC );
GO


/*
    load with initial data

    set start and end dates for inital data to be loaded
     * default start date is 01 Jan 2020
     * default end date is set to end of current year
     * default fiscal month start date is 10 (Oct)
*/
WITH
    cte_tally ( n ) AS
    (
    -- SQL Prompt Formatting OFF
    SELECT      row_number() OVER ( ORDER BY ( SELECT NULL ))
    FROM        ( VALUES ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ) ) AS t0 ( n ) /* 10 rows */
    CROSS JOIN  ( VALUES ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ) ) AS t1 ( n ) /* 100 rows */
    CROSS JOIN  ( VALUES ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ) ) AS t2 ( n ) /* 1,000 rows */
    CROSS JOIN  ( VALUES ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ) ) AS t3 ( n ) /* 10,000 rows */
    CROSS JOIN  ( VALUES ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ), ( 0 ) ) AS t4 ( n ) /* 100,000 rows */
    -- SQL Prompt Formatting ON
    ),
    cte_calendar AS
    (
        SELECT  dateadd(DAY, t.n - 1, dt.table_start_date) AS calendar_date,
                10                                         AS first_fiscal_month
        FROM    cte_tally AS t
        /* 
        === set start and end dates here ===
        */
        CROSS APPLY
                (
                    SELECT  datefromparts(2020, 1, 1)                  AS table_start_date,
                            datefromparts(year(sysdatetime()), 12, 31) AS table_end_date
                )         AS dt
        WHERE   t.n <= datediff(DAY, dt.table_start_date, dt.table_end_date) + 1
    ),
    cte_calendar_dates AS
    (
        SELECT  convert(char(8), c.calendar_date, 112)                                                                               AS date_id,
                c.calendar_date                                                                                                      AS calendar_date,
                datepart(WEEKDAY, c.calendar_date)                                                                                   AS day_of_week_number,
                left(datename(WEEKDAY, c.calendar_date), 3)                                                                          AS day_of_week_name,
                datepart(WEEK, c.calendar_date)                                                                                      AS week_number,
                'Wk ' + right('00' + cast(datepart(WEEK, c.calendar_date) AS varchar(2)), 2)                                         AS week_name,
                'Wk ' + right('00' + cast(datepart(WEEK, c.calendar_date) AS varchar(2)), 2) + ' ' + datename(YEAR, c.calendar_date) AS week_year,
                datepart(MONTH, c.calendar_date)                                                                                     AS month_number,
                left(datename(MONTH, c.calendar_date), 3)                                                                            AS month_name,
                left(datename(MONTH, c.calendar_date), 3) + ' ' + datename(YEAR, c.calendar_date)                                    AS month_year,
                dateadd(DAY, - ( day(c.calendar_date) - 1 ), c.calendar_date)                                                        AS month_start_date,
                dateadd(DAY, - ( day(dateadd(MONTH, 1, c.calendar_date))), dateadd(MONTH, 1, c.calendar_date))                       AS month_end_date,
                datepart(QUARTER, c.calendar_date)                                                                                   AS quarter_number,
                'Q' + convert(varchar(5), datepart(QUARTER, c.calendar_date))                                                        AS quarter_name,
                'Q' + convert(varchar(5), datepart(QUARTER, c.calendar_date)) + ' ' + datename(YEAR, c.calendar_date)                AS quarter_year,
                dateadd(QUARTER, datediff(QUARTER, 0, c.calendar_date), 0)                                                           AS quarter_start_date,
                dateadd(QUARTER, 1, dateadd(QUARTER, datediff(QUARTER, 0, c.calendar_date), 0)) - 1                                  AS quarter_end_date,
                datename(YEAR, c.calendar_date)                                                                                      AS year_number,
                datename(YEAR, c.calendar_date)                                                                                      AS year_name,
                convert(date, datename(YEAR, c.calendar_date) + '0101')                                                              AS year_start_date,
                convert(date, datename(YEAR, c.calendar_date) + '1231')                                                              AS year_end_date,
                ( 12 - c.first_fiscal_month ) + 1                                                                                    AS fiscal_month_offset
        FROM    cte_calendar AS c
    )
INSERT INTO dbo.dim_date
(
        date_id,
        calendar_date,
        day_of_week_number,
        day_of_week_name,
        week_number,
        week_name,
        week_year,
        month_number,
        month_name,
        month_year,
        month_start_date,
        month_end_date,
        quarter_number,
        quarter_name,
        quarter_year,
        quarter_start_date,
        quarter_end_date,
        year_number,
        year_name,
        year_start_date,
        year_end_date,
        fiscal_month_number,
        fiscal_month_name,
        fiscal_month_year,
        fiscal_quarter_number,
        fiscal_quarter_name,
        fiscal_quarter_year,
        fiscal_year_number,
        fiscal_year_name,
        business_day_value
)
SELECT  d.date_id,
        d.calendar_date,
        d.day_of_week_number,
        d.day_of_week_name,
        d.week_number,
        d.week_name,
        d.week_year,
        d.month_number,
        d.month_name,
        d.month_year,
        d.month_start_date,
        d.month_end_date,
        d.quarter_number,
        d.quarter_name,
        d.quarter_year,
        d.quarter_start_date,
        d.quarter_end_date,
        d.year_number,
        d.year_name,
        d.year_start_date,
        d.year_end_date,
        datepart(MONTH, dateadd(MONTH, d.fiscal_month_offset, d.calendar_date))                            AS fiscal_month_number,
        d.month_name                                                                                       AS fiscal_month_name,
        d.month_year                                                                                       AS fiscal_month_year,
        datepart(QUARTER, dateadd(MONTH, d.fiscal_month_offset, d.calendar_date))                          AS fiscal_quarter_number,
        'FQ' + convert(char(4), datepart(QUARTER, dateadd(MONTH, d.fiscal_month_offset, d.calendar_date))) AS fiscal_quarter_name,
        'FQ' + convert(char(1), datepart(QUARTER, dateadd(MONTH, d.fiscal_month_offset, d.calendar_date))) + ' '
        + convert(char(4), datepart(YEAR, dateadd(MONTH, d.fiscal_month_offset, d.calendar_date)))         AS fiscal_quarter_year,
        datepart(YEAR, dateadd(MONTH, d.fiscal_month_offset, d.calendar_date))                             AS fiscal_year_number,
        'FY ' + convert(char(4), datepart(YEAR, dateadd(MONTH, d.fiscal_month_offset, d.calendar_date)))   AS fiscal_year_name,
        /* business day values; used to calculate business days per period */
        CASE
            WHEN datepart(dw, d.calendar_date) = 1
                THEN 0.00 /* Sunday */
            WHEN datepart(dw, d.calendar_date) = 7
                THEN 0.50 /* Saturday */
            ELSE 1
        END                                                                                                AS business_day_value
FROM    cte_calendar_dates AS d;



/*
    insert unknown member
*/
INSERT INTO dbo.dim_date
(
        date_id,
        calendar_date,
        day_of_week_number,
        day_of_week_name,
        week_number,
        week_name,
        week_year,
        month_number,
        month_name,
        month_year,
        month_start_date,
        month_end_date,
        quarter_number,
        quarter_name,
        quarter_year,
        quarter_start_date,
        quarter_end_date,
        year_number,
        year_name,
        year_start_date,
        year_end_date,
        fiscal_month_number,
        fiscal_month_name,
        fiscal_month_year,
        fiscal_quarter_number,
        fiscal_quarter_name,
        fiscal_quarter_year,
        fiscal_year_number,
        fiscal_year_name,
        business_day_value
)
SELECT  -1         AS date_id,
        '19000101' AS calendar_date,
        0          AS week_day_number,
        'N/A'      AS week_day_name,
        0          AS week_number,
        'N/A'      AS week_name,
        'N/A'      AS week_year,
        0          AS month_number,
        'N/A'      AS month_name,
        'N/A'      AS month_year,
        '19000101' AS month_start_date,
        '19000101' AS month_end_date,
        0          AS quarter_number,
        'N/A'      AS quarter_name,
        'N/A'      AS quarter_year,
        '19000101' AS quarter_start_date,
        '19000101' AS quarter_end_date,
        0          AS year_number,
        'N/A'      AS year_name,
        '19000101' AS year_start_date,
        '19000101' AS year_end_date,
        0          AS fiscal_month_number,
        'N/A'      AS fiscal_month_name,
        'N/A'      AS fiscal_month_year,
        0          AS fiscal_quarter_number,
        'N/A'      AS fiscal_quarter_name,
        'N/A'      AS fiscal_quarter_year,
        0          AS fiscal_quarter_number,
        'N/A'      AS fiscal_quarter_name,
        0          AS business_day_value
WHERE   NOT EXISTS
        (
            SELECT  1
            FROM    dbo.dim_date AS d
            WHERE   d.date_id = -1
        );

GO
