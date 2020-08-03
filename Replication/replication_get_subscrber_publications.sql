/* ================================================================================================
Purpose:
    Lists publications on the Subscriber.

    *** Run against the database that is the Subscriber.
 
History:
    2011-12-07  Tom Hogan           Created.
================================================================================================ */

SELECT      DISTINCT
            publisher,
            publisher_db,
            publication,
            time    AS last_updated_datetime
FROM        dbo.MSreplication_subscriptions
ORDER BY    publisher,
            publisher_db,
            publication;
