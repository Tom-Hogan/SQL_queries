/* ================================================================================================
Purpose:
    Lists publications and associated articles on the Publisher.
 
History:
    2011-12-07  Tom Hogan           Created.
================================================================================================ */
SELECT      p.name                            AS publication,
            CASE
                WHEN p.status = 1
                    THEN 'Active'
                ELSE 'Inactive'
            END                               AS publication_status,
            CASE
                WHEN p.repl_freq = 0
                    THEN 'Transactional'
                ELSE 'Snapshot'
            END                               AS publication_type,
            CASE
                WHEN p.replicate_ddl = 0
                    THEN 'N'
                ELSE 'Y'
            END                               AS replicate_ddl,
            a.name                            AS article_name,
            s.SrvName                         AS subscriber_server,
            a.dest_owner + '.' + a.dest_table AS dest_table,
            CASE
                WHEN s.subscription_type = 0
                    THEN 'Push'
                WHEN s.subscription_type = 1
                    THEN 'Pull'
                ELSE ''
            END                               AS subscription_type,
            CASE
                WHEN s.nosync_type = 0
                    THEN 'Automatic'
                WHEN s.nosync_type = 1
                    THEN 'Replication support only'
                WHEN s.nosync_type = 2
                    THEN 'Initialize with backup'
                WHEN s.nosync_type = 3
                    THEN 'Initialize from log sequence number (LSN)'
                ELSE ''
            END                               AS subsciption_initialization,
            CASE
                WHEN s.status = 1
                    THEN 'Subscribed'
                WHEN s.status = 2
                    THEN 'Active'
                ELSE 'Inactive'
            END                               AS subscription_status,
            CASE
                WHEN a.filter = 0
                    THEN 'N'
                ELSE 'Y'
            END                               AS artcle_filtered
FROM        dbo.sysPublications     AS p
JOIN        dbo.sysArticles         AS a    ON  a.pubid = p.pubid
JOIN        dbo.sysSubscriptions    AS s    ON  s.artid = a.artid
                                            AND s.SrvID > 0
ORDER BY    p.name,
            a.name,
            s.SrvName;
