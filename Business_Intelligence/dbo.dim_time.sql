/* ================================================================================================
Purpose:
    Creates a dimension table to hold time data.

History:
    Unknown     Unknown             Based on original script for DimDate and DimTime 
                                    from http://www.sqlservercentral.com/scripts/Data+Warehousing/65762/)
    Unknown     Craig Love          Updated.
    2012-02-07  Tom Hogan           Updated to use tally table, follow naming conventions.
================================================================================================ */
SET NOCOUNT ON;


-- declare variables
DECLARE @start_time datetime,
        @end_time   datetime;


-- ------------------------------------------------------------------------------------------------
-- create table
-- ------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS dbo.dim_time;

CREATE TABLE dbo.dim_time (
    time_id                int         NOT NULL,
    time                   varchar(5)  NOT NULL,
    hour                   varchar(3)  NOT NULL,
    military_hour          varchar(3)  NOT NULL,
    minute                 varchar(3)  NOT NULL,
    am_pm                  varchar(3)  NOT NULL,
    standard_time          varchar(11) NULL,
    minutes_since_midnight smallint    NULL,
    CONSTRAINT dim_time_pk
        PRIMARY KEY CLUSTERED ( time_id ASC )
);
GO

-- index(es)
CREATE UNIQUE NONCLUSTERED INDEX ix_dim_time_time
    ON dbo.dim_time ( time ASC );
GO
CREATE NONCLUSTERED INDEX ix_dim_time_standard_time
    ON dbo.dim_time ( standard_time ASC );
GO


-- ------------------------------------------------------------------------------------------------
-- load with initial data
-- ------------------------------------------------------------------------------------------------
--   set variables for the start and end times
SET @start_time = convert(varchar(15), '12:00:00 AM', 108);
SET @end_time = convert(varchar(15), '11:59:59 PM', 108);


-- get each minute of the day
WITH cte_time
AS
    (
    SELECT  dateadd(MINUTE, n - 1, @start_time) AS time
    FROM    dbo.tally
    WHERE   n <= datediff(MINUTE, @start_time, @end_time) + 1
    )
-- load table with time data
INSERT INTO dbo.dim_time (
            time_id,
            time,
            military_hour,
            hour,
            minute,
            am_pm,
            minutes_since_midnight
)
SELECT      ( row_number() OVER ( ORDER BY time )) - 1                  AS time_id,
            left(convert(varchar(5), time, 108), 5)                     AS time,
            right('00' + cast(datepart(HOUR, time) AS varchar(3)), 2)   AS military_hour,
            CASE
                WHEN datepart(HOUR, time) > 12
                    THEN right('00' + cast(datepart(HOUR, time) - 12 AS varchar(3)), 2)
                ELSE right('00' + cast(datepart(HOUR, time) AS varchar(3)), 2)
            END                                                         AS hour,
            right('00' + cast(datepart(MINUTE, time) AS varchar(2)), 2) AS minute,
            CASE
                WHEN datepart(HOUR, time) >= 12
                    THEN 'PM'
                ELSE 'AM'
            END                                                         AS am_pm,
            ( row_number() OVER ( ORDER BY time )) - 1                  AS minutes_since_midnight
            FROM        cte_time;


-- set standard time field
UPDATE  dbo.dim_time
SET     standard_time = hour + ':' + minute + ' ' + am_pm
WHERE   standard_time IS NULL
AND     hour <> '00';

UPDATE  dbo.dim_time
SET     standard_time = '12' + ':' + minute + ' ' + am_pm
WHERE   hour = '00';


-- insert unknown member
INSERT INTO dbo.dim_time (
            time_id,
            time,
            military_hour,
            hour,
            minute,
            am_pm,
            standard_time,
            minutes_since_midnight
)
VALUES      (
            -1,    -- time_id
            'N/A', -- time
            'N/A', -- military_hour
            'N/A', -- hour
            'N/A', -- minute
            'N/A', -- am_pm
            'N/A', -- standard_time
            0      -- minutes_since_midnight
            );

GO
