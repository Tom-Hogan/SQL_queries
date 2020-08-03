/* ================================================================================================
Purpose:
    Creates a dimension table to hold date data.  Uses variables to define the start and end values
    for the date range to be held in the table.

    1. Needs a tally table created to do the table population.
    2. Update start and end date variables.

History:
    2012-02-07  Tom Hogan           Created.
================================================================================================ */
SET NOCOUNT ON;

--   declare variables
DECLARE @start_date smalldatetime,
        @end_date   smalldatetime;


-- ------------------------------------------------------------------------------------------------
-- create table
-- ------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS dbo.dim_date;

CREATE TABLE dbo.dim_date (
    date_id            int           NOT NULL,
    calendar_date      datetime      NOT NULL,
    date_name          varchar(15)   NOT NULL,  -- 01/01/2008
    day_name           varchar(15)   NOT NULL,  -- Tuesday
    week_of_year       tinyint       NOT NULL,  -- 1, 2, 3, etc.
    week_name          varchar(10)   NOT NULL,  -- Wk 01
    week_full_name     varchar(20)   NOT NULL,  -- Wk 01 2008
    month_of_year      tinyint       NOT NULL,  -- 1, 2, 3, etc.
    month_name         varchar(10)   NOT NULL,  -- January
    month_full_name    varchar(20)   NOT NULL,  -- January 2008
    month_start_date   date          NOT NULL,
    month_end_date     date          NOT NULL,
    quarter_of_year    tinyint       NOT NULL,  -- 1, 2, etc.
    quarter_name       varchar(20)   NOT NULL,  -- Q1
    quarter_full_name  varchar(20)   NOT NULL,  -- Q1 2008
    quarter_start_date date          NOT NULL,
    quarter_end_date   date          NOT NULL,
    year_name          varchar(10)   NOT NULL,  -- 2008
    year_start_date    date          NOT NULL,
    year_end_date      date          NOT NULL,
    --  add business / fiscal date columns --
    business_day_value decimal(5, 2) NOT NULL,
    etl_audit_id       int           NULL,
    CONSTRAINT dim_time_pk
        PRIMARY KEY CLUSTERED ( date_id ASC )
);
GO

-- index(es)
CREATE UNIQUE NONCLUSTERED INDEX ix_dim_date_calendar_date
    ON dbo.dim_date ( calendar_date ASC );
GO


-- ------------------------------------------------------------------------------------------------
-- *** set start and end dates of dates to be inserted into the table
--     end date is set to end of current year, unless you change it
-- ------------------------------------------------------------------------------------------------
SET @start_date = '20080101';
SET @end_date = ( SELECT  cast(year(getdate()) AS varchar(4)) + '1231' );


-- ------------------------------------------------------------------------------------------------
-- load with initial data
-- ------------------------------------------------------------------------------------------------
--   get all dates between the given start and end dates
WITH cte_calendar
AS
    (
    SELECT  dateadd(DAY, n - 1, @start_date) AS calendar_date
    FROM    dbo.tally
    WHERE   n <= datediff(DAY, @start_date, @end_date) + 1
    )
-- load table with date data
INSERT INTO dbo.dim_date (
            date_id,
            calendar_date,
            date_name,
            day_name,
            week_of_year,
            week_name,
            week_full_name,
            month_of_year,
            month_name,
            month_full_name,
            month_start_date,
            month_end_date,
            quarter_of_year,
            quarter_name,
            quarter_full_name,
            quarter_start_date,
            quarter_end_date,
            year_name,
            year_start_date,
            year_end_date,
            business_day_value
)
SELECT      convert(char(8), c.calendar_date, 112)                                                                               AS date_id,
            c.calendar_date,
            convert(varchar(10), c.calendar_date, 101)                                                                           AS date_name,
            datename(WEEKDAY, c.calendar_date)                                                                                   AS day_name,
            datepart(WEEK, c.calendar_date)                                                                                      AS week_of_year,
            'Wk ' + right('00' + cast(datepart(WEEK, c.calendar_date) AS varchar(2)), 2)                                         AS week_name,
            'Wk ' + right('00' + cast(datepart(WEEK, c.calendar_date) AS varchar(2)), 2) + ' ' + datename(YEAR, c.calendar_date) AS week_full_name,
            datepart(MONTH, c.calendar_date)                                                                                     AS month_of_year,
            datename(MONTH, c.calendar_date)                                                                                     AS month_name,
            datename(MONTH, c.calendar_date) + ' ' + datename(YEAR, c.calendar_date)                                             AS month_full_name,
            dateadd(DAY, - ( day(c.calendar_date) - 1 ), c.calendar_date)                                                        AS month_start_date,
            dateadd(DAY, - ( day(dateadd(MONTH, 1, c.calendar_date))), dateadd(MONTH, 1, c.calendar_date))                       AS month_end_date,
            datepart(QUARTER, c.calendar_date)                                                                                   AS quarter_of_year,
            'Q' + convert(varchar(20), datepart(QUARTER, c.calendar_date))                                                       AS quarter_name,
            'Q' + convert(varchar(20), datepart(QUARTER, c.calendar_date)) + ' ' + datename(YEAR, c.calendar_date)               AS quarter_full_name,
            dateadd(QUARTER, datediff(QUARTER, 0, c.calendar_date), 0)                                                           AS quarter_start_date,
            dateadd(QUARTER, 1, dateadd(QUARTER, datediff(QUARTER, 0, c.calendar_date), 0)) - 1                                  AS quarter_end_date,
            datename(YEAR, c.calendar_date)                                                                                      AS year_name,
            convert(date, datename(YEAR, c.calendar_date) + '0101')                                                              AS year_start_date,
            convert(date, datename(YEAR, c.calendar_date) + '1231')                                                              AS year_end_date,
            -- business day values; used to calculate business days per period
            CASE
                WHEN datepart(dw, c.calendar_date) = 1
                    THEN 0.00 -- Sunday
                WHEN datepart(dw, c.calendar_date) = 7
                    THEN 0.50 -- Saturday
                ELSE 1
            END                                                                                                                  AS business_day_value
FROM        cte_calendar AS c;


-- examples to populate business / fiscal day counts
/*
-- example to get business / fiscal day count in given period 
SELECT  date_id,
        sum(business_day_value) OVER ( PARTITION BY month_start_date
                                       ORDER BY date_id
                                     ) AS business_day_of_month
FROM    dbo.dim_date;

-- example to get total business days in given period
SELECT      month_start_date,
            sum(business_day_value) AS business_days_in_month
FROM        dbo.dim_date
GROUP BY    month_start_date
ORDER BY    month_start_date;
-- */

-- insert unknown member
INSERT INTO dbo.dim_date (
            date_id,
            calendar_date,
            date_name,
            day_name,
            week_of_year,
            week_name,
            week_full_name,
            month_of_year,
            month_name,
            month_full_name,
            month_start_date,
            month_end_date,
            quarter_of_year,
            quarter_name,
            quarter_full_name,
            quarter_start_date,
            quarter_end_date,
            year_name,
            year_start_date,
            year_end_date,
            business_day_value
)
SELECT      a.date_id,
            a.calendar_date,
            a.date_name,
            a.day_name,
            a.week_of_year,
            a.week_name,
            a.week_full_name,
            a.month_of_year,
            a.month_name,
            a.month_full_name,
            a.month_start_date,
            a.month_end_date,
            a.quarter_of_year,
            a.quarter_name,
            a.quarter_full_name,
            a.quarter_start_date,
            a.quarter_end_date,
            a.year_name,
            a.year_start_date,
            a.year_end_date,
            a.business_day_value
FROM        (
            VALUES  ( -1, '19000101', 'N/A', 'N/A', 0, 'N/A', 'N/A', 0, 'N/A', 'N/A',
                     '19000101', '19000101', 0, 'N/A', 'N/A', '19000101', '19000101', 'N/A',
                     '19000101', '19000101', 0
                    )
            ) AS a  ( date_id, calendar_date, date_name, day_name, week_of_year, week_name, week_full_name, month_of_year, month_name, month_full_name,
                      month_start_date, month_end_date, quarter_of_year, quarter_name, quarter_full_name, quarter_start_date, quarter_end_date, year_name,
                      year_start_date, year_end_date, business_day_value
                    )
WHERE       NOT EXISTS  (
                        SELECT  1
                        FROM    dbo.dim_date AS d
                        WHERE   d.date_id = a.date_id
                        );

GO
