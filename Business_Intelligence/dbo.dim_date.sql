/* ================================================================================================
Purpose:
    Creates a dimension table to hold date data.  Uses variables to define the start and end values
    for the date range to be held in the table.

Notes:
    1. Need to update start and end date variables for initial data.
    2. Tally CTE based on work done by Dwain Camps

History:
    2012-02-07  Tom Hogan           Created.
================================================================================================ */
SET NOCOUNT ON;


/*
    create table
*/
DROP TABLE IF EXISTS dbo.dim_date;

CREATE TABLE dbo.dim_date
(
    date_id            int           NOT NULL,
    calendar_date      date          NOT NULL,
    date_name          char(10)      NOT NULL,  /* 01/01/2008 */
    day_of_week_name   char(3)       NOT NULL,  /* Tue */
    day_of_week_number tinyint       NOT NULL,  /* 1, 2, 3, etc. */
    year_week          char(10)      NOT NULL,  /* Wk 01 2008 */
    week_name          char(5)       NOT NULL,  /* Wk 01 */
    week_number        tinyint       NOT NULL,  /* 1, 2, 3, etc. */
    year_month         char(8)       NOT NULL,  /* Jan 2008 */
    month_name         char(3)       NOT NULL,  /* Jan */
    month_number       tinyint       NOT NULL,  /* 1, 2, 3, etc. */
    month_start_date   date          NOT NULL,
    month_end_date     date          NOT NULL,
    year_quarter       char(7)       NOT NULL,  /* Q1 2008 */
    quarter_name       char(3)       NOT NULL,  /* Q1 */
    quarter_number     tinyint       NOT NULL,  /* 1, 2, etc. */
    quarter_start_date date          NOT NULL,
    quarter_end_date   date          NOT NULL,
    year_name          char(4)       NOT NULL,  /* 2008 */
    year_start_date    date          NOT NULL,
    year_end_date      date          NOT NULL,
    /* add business / fiscal date columns */
    business_day_value decimal(5, 2) NOT NULL,
    etl_audit_id       int           NULL,
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
     * default start date is 2008-01-01
     * default end date is set to end of current year
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
    SELECT  dateadd(DAY, t.n - 1, dt.table_start_date) AS calendar_date
    FROM    cte_tally AS t
    /* 
    === set start and end dates here ===
    */
    CROSS APPLY
            (
                SELECT  datefromparts(2008, 1, 1)                  AS table_start_date,
                        datefromparts(year(sysdatetime()), 12, 31) AS table_end_date
            )         AS dt
    WHERE   t.n <= datediff(DAY, dt.table_start_date, dt.table_end_date) + 1
)
INSERT INTO dbo.dim_date
(
        date_id,
        calendar_date,
        date_name,
        day_of_week_name,
        day_of_week_number,
        year_week,
        week_name,
        week_number,
        year_month,
        month_name,
        month_number,
        month_start_date,
        month_end_date,
        year_quarter,
        quarter_name,
        quarter_number,
        quarter_start_date,
        quarter_end_date,
        year_name,
        year_start_date,
        year_end_date,
        business_day_value
)
SELECT  convert(char(8), c.calendar_date, 112)                                                                               AS date_id,
        c.calendar_date                                                                                                      AS calendar_date,
        convert(varchar(10), c.calendar_date, 101)                                                                           AS date_name,
        left(datename(WEEKDAY, c.calendar_date), 3)                                                                          AS day_of_week_name,
        datepart(WEEKDAY, c.calendar_date)                                                                                   AS day_of_week_number,
        'Wk ' + right('00' + cast(datepart(WEEK, c.calendar_date) AS varchar(2)), 2) + ' ' + datename(YEAR, c.calendar_date) AS year_week,
        'Wk ' + right('00' + cast(datepart(WEEK, c.calendar_date) AS varchar(2)), 2)                                         AS week_name,
        datepart(WEEK, c.calendar_date)                                                                                      AS week_number,
        left(datename(MONTH, c.calendar_date), 3) + ' ' + datename(YEAR, c.calendar_date)                                    AS year_month,
        left(datename(MONTH, c.calendar_date), 3)                                                                            AS month_name,
        datepart(MONTH, c.calendar_date)                                                                                     AS month_number,
        dateadd(DAY, - ( day(c.calendar_date) - 1 ), c.calendar_date)                                                        AS month_start_date,
        dateadd(DAY, - ( day(dateadd(MONTH, 1, c.calendar_date))), dateadd(MONTH, 1, c.calendar_date))                       AS month_end_date,
        'Q' + convert(varchar(5), datepart(QUARTER, c.calendar_date)) + ' ' + datename(YEAR, c.calendar_date)                AS year_quarter,
        'Q' + convert(varchar(5), datepart(QUARTER, c.calendar_date))                                                        AS quarter_name,
        datepart(QUARTER, c.calendar_date)                                                                                   AS quarter_number,
        dateadd(QUARTER, datediff(QUARTER, 0, c.calendar_date), 0)                                                           AS quarter_start_date,
        dateadd(QUARTER, 1, dateadd(QUARTER, datediff(QUARTER, 0, c.calendar_date), 0)) - 1                                  AS quarter_end_date,
        datename(YEAR, c.calendar_date)                                                                                      AS year_name,
        convert(date, datename(YEAR, c.calendar_date) + '0101')                                                              AS year_start_date,
        convert(date, datename(YEAR, c.calendar_date) + '1231')                                                              AS year_end_date,
        /* business day values; used to calculate business days per period */
        CASE
            WHEN datepart(dw, c.calendar_date) = 1
                THEN 0.00 /* Sunday */
            WHEN datepart(dw, c.calendar_date) = 7
                THEN 0.50 /* Saturday */
            ELSE 1
        END                                                                                                                  AS business_day_value
FROM    cte_calendar AS c;


/*
    examples to populate business / fiscal day counts
*/
/*
/* to get business / fiscal day count in given period */
SELECT  date_id,
        sum(business_day_value) OVER ( PARTITION BY month_start_date
                                       ORDER BY date_id
                                     ) AS business_day_of_month
FROM    dbo.dim_date;

/* to get total business days in given period */
SELECT      month_start_date,
            sum(business_day_value) AS business_days_in_month
FROM        dbo.dim_date
GROUP BY    month_start_date
ORDER BY    month_start_date;
-- */


/*
    insert unknown member
*/
INSERT INTO dbo.dim_date
(
        date_id,
        calendar_date,
        date_name,
        day_of_week_name,
        day_of_week_number,
        year_week,
        week_name,
        week_number,
        year_month,
        month_name,
        month_number,
        month_start_date,
        month_end_date,
        year_quarter,
        quarter_name,
        quarter_number,
        quarter_start_date,
        quarter_end_date,
        year_name,
        year_start_date,
        year_end_date,
        business_day_value
)
SELECT  -1         AS date_id,
        '19000101' AS calendar_date,
        'N/A'      AS date_name,
        'N/A'      AS day_of_week_name,
        0          AS day_of_week_number,
        'N/A'      AS year_week,
        'N/A'      AS week_name,
        0          AS week_number,
        'N/A'      AS year_month,
        'N/A'      AS month_name,
        0          AS month_number,
        '19000101' AS month_start_date,
        '19000101' AS month_end_date,
        'N/A'      AS year_quarter,
        'N/A'      AS quarter_name,
        0          AS quarter_number,
        '19000101' AS quarter_start_date,
        '19000101' AS quarter_end_date,
        'N/A'      AS year_name,
        '19000101' AS year_start_date,
        '19000101' AS year_end_date,
        0          AS business_day_value
WHERE   NOT EXISTS
        (
            SELECT  1
            FROM    dbo.dim_date AS d
            WHERE   d.date_id = -1
        );

GO
