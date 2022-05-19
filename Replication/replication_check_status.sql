/* ================================================================================================
Purpose:
    List status of replication publications on the Distributor.

Notes:
    Contains commented out predefined WHERE clause to filter results for a specific publication.

History:
    2011-12-07  Tom Hogan           Created.
    2016-10-21  Tom Hogan           Added publication type, status and agent names.
================================================================================================ */
USE distribution; /* change if your distribution database is named differently than the default */


/* transactional / snapshot */
SELECT      s.name              AS publication_server,
            a.publisher_db,
            p.publication_id,
            a.publication,
            CASE
                WHEN p.publication_type = 0
                    THEN N'Transactional'
                WHEN p.publication_type = 1
                    THEN N'Snapshot'
                WHEN p.publication_type = 2
                    THEN N'Merge'
                ELSE N'Unknown'
            END                 AS publication_type,
            CASE
                WHEN h.RunStatus = 1
                    THEN N'Started'
                WHEN h.RunStatus = 2
                    THEN N'Succeeded'
                WHEN h.RunStatus = 3
                    THEN N'In Progress'
                WHEN h.RunStatus = 4
                    THEN N'Idle'
                WHEN h.RunStatus = 5
                    THEN N'Retrying'
                WHEN h.RunStatus = 6
                    THEN N'Failed'
                ELSE N'Unknown'
            END                 AS publication_status,
            h.time              AS last_distribution_sync,
            h.comments,
            a.name              AS distribution_agent_name,
            isnull(sn.name, '') AS snapshot_agent_name,
            isnull(lr.name, '') AS logreader_agent_name
FROM        dbo.MSdistribution_agents   AS a
JOIN        dbo.MSPublications          AS p    ON  p.publication = a.publication
JOIN        master.sys.servers          AS s    ON  s.server_id = p.publisher_id
            /* get latest synchronization status */
LEFT JOIN   (
                SELECT  h2.agent_id,
                        h2.time,
                        h2.comments,
                        h2.RunStatus,
                        row_number() OVER ( PARTITION BY h2.agent_id
                                            ORDER BY h2.agent_id,
                                                     h2.time DESC
                                          ) AS transaction_order
                FROM    dbo.MSdistribution_history  AS h2
                WHERE   h2.comments NOT LIKE '<stats%'
            )                           AS h    ON  h.agent_id = a.id
                                                AND h.transaction_order = 1
LEFT JOIN   dbo.MSsnapshot_agents       AS sn   ON  sn.id = p.publication_id
LEFT JOIN   dbo.MSlogreader_agents      AS lr   ON  lr.publisher_id = p.publisher_id
                                                AND lr.publisher_db = p.publisher_db
WHERE       a.subscriber_db <> 'virtual'
            /*
            === to get specific publication ===
            */
--AND         a.publication = 'publication_name'
UNION ALL
/* merge */
SELECT      s.name              AS publication_server,
            a.publisher_db,
            p.publication_id,
            a.publication,
            CASE
                WHEN p.publication_type = 0
                    THEN N'Transactional'
                WHEN p.publication_type = 1
                    THEN N'Snapshot'
                WHEN p.publication_type = 2
                    THEN N'Merge'
                ELSE N'Unknown'
            END                 AS publication_type,
            CASE
                WHEN h.RunStatus = 1
                    THEN N'Started'
                WHEN h.RunStatus = 2
                    THEN N'Succeeded'
                WHEN h.RunStatus = 3
                    THEN N'In Progress'
                WHEN h.RunStatus = 4
                    THEN N'Idle'
                WHEN h.RunStatus = 5
                    THEN N'Retrying'
                WHEN h.RunStatus = 6
                    THEN N'Failed'
                ELSE N'Unknown'
            END                 AS publication_status,
            h.time              AS last_distribution_sync,
            h.comments,
            a.name              AS distribution_agent_name,
            isnull(sn.name, '') AS snapshot_agent_name,
            isnull(lr.name, '') AS logreader_agent_name
FROM        dbo.MSmerge_agents      AS a
JOIN        dbo.MSPublications      AS p    ON  p.publication = a.publication
JOIN        master.sys.servers      AS s    ON  s.server_id = p.publisher_id
            /* get latest synchronization status */
LEFT JOIN   (
                SELECT  h2.agent_id,
                        h2.time,
                        h2.comments,
                        3                   AS RunStatus,
                        row_number() OVER ( PARTITION BY h2.agent_id
                                            ORDER BY h2.agent_id,
                                                     h2.time DESC
                                          ) AS transaction_order
                FROM    dbo.MSmerge_history AS h2
                WHERE   h2.comments NOT LIKE '<stats%'
            )                       AS h    ON  h.agent_id = a.id
                                            AND h.transaction_order = 1
LEFT JOIN   dbo.MSsnapshot_agents   AS sn   ON  sn.id = p.publication_id
LEFT JOIN   dbo.MSlogreader_agents  AS lr   ON  lr.publisher_id = p.publisher_id
                                            AND lr.publisher_db = p.publisher_db
WHERE       a.subscriber_db <> 'virtual'
            /*
            === to get specific publication ===
            */
--AND         a.publication = 'publication_name'
ORDER BY    publisher_db,
            publication;
