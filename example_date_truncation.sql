/* ================================================================================================
Purpose:
    Examples of ways to manipulate dates.
 
History:
    From Dwain Camps
    http://www.sqlservercentral.com/blogs/dwainsql/2014/04/04/manipulating-dates-and-times-in-t-sql/_
================================================================================================ */

-- get current datetime
SELECT  getdate();

-- take the days difference between today's date and 1900-01-01
SELECT  datediff(DAY, 0, getdate());

-- add back the days difference to 1900-01-01
SELECT  dateadd(DAY, datediff(DAY, 0, getdate()), 0);

-- truncate to the minute, hour, month or year simply by specifying a different first argument to both functions:
SELECT  dateadd(MINUTE, datediff(MINUTE, 0, getdate()), 0);
SELECT  dateadd(HOUR, datediff(HOUR, 0, getdate()), 0);
SELECT  dateadd(MONTH, datediff(MONTH, 0, getdate()), 0);
SELECT  dateadd(YEAR, datediff(YEAR, 0, getdate()), 0);
