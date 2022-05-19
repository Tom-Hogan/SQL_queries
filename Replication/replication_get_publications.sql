/* ================================================================================================
Purpose:
    Lists all publications on the Distributor.

History:
    2011-12-07  Tom Hogan           Created.
================================================================================================ */
USE distribution;   /* change if your distribution database is named differently than the default */


SELECT      DISTINCT
            ps.name AS publication_server,
            p.publication,
            CASE
                WHEN p.publication_type = 0
                    THEN 'Transactional'
                WHEN p.publication_type = 1
                    THEN 'Snapshot'
                WHEN p.publication_type = 2
                    THEN 'Merge'
                ELSE ''
            END     AS publication_type,
            CASE
                WHEN p.immediate_sync = 1
                    THEN 'Yes'
                ELSE 'No'
            END     AS immediate_sync,
            CASE
                WHEN p.allow_push = 1
                    THEN 'Yes'
                ELSE 'No'
            END     AS allow_push,
            CASE
                WHEN p.allow_pull = 1
                    THEN 'Yes'
                ELSE 'No'
            END     AS allow_pull,
            a.publisher_db,
            ss.name AS subscription_server,
            s.subscriber_db,
            CASE
                WHEN s.status = 1
                    THEN 'Subscribed'
                WHEN s.status = 2
                    THEN 'Active'
                ELSE 'Inactive'
            END     AS subscription_status,
            CASE
                WHEN s.sync_type = 1
                    THEN 'Automatic'
                WHEN s.sync_type = 2
                    THEN 'No synchronization'
                ELSE ''
            END     AS subscription_sync_type
FROM        dbo.MSArticles          AS a
JOIN        dbo.MSPublications      AS p    ON  p.publication_id = a.publication_id
JOIN        master.sys.servers      AS ps   ON  ps.server_id = p.publisher_id
JOIN        dbo.MSSubscriptions     AS s    ON  s.publication_id = p.publication_id
JOIN        master.sys.servers      AS ss   ON  ss.server_id = s.subscriber_id
WHERE       s.subscriber_id > 0
ORDER BY    ps.name,
            a.publisher_db,
            p.publication,
            ss.name,
            s.subscriber_db;
