/* ================================================================================================
Purpose:
    Example of the queries you will need to run on the Distributor and Subscriber in order to kill
    a replication transaction.  This will usually be due to an error that there is no other way
    to solve.

Notes: 
    Each query needs to be run against the appropriate server and database.

History:
    2011-12-07  Tom Hogan           Created
================================================================================================ */
RAISERROR(N'Remember! Each query needs to be run separately.', 20, 1) WITH LOG;
GO


/*
    run this section against the Distributor
    === take the most recent xact_seqno, this will be the erroring transaction ===
*/
EXEC sys.sp_helpsubscriptionerrors 
    @publisher = 'Publisher_Server',
    @publisher_db = 'DB1',
    @publication = 'DB1_repl1',
    @subscriber = 'Subscriber_Server',
    @subscriber_db = 'SDB1';


/*
    run this section against the Subscriber
    this will skip the transaction associated with the xaxt_seqno
    === you will need to manually apply any transactions skipped ===
*/
EXEC sys.sp_setsubscriptionxactseqno 
    @publisher = 'Publisher_Server',
    @publisher_db = 'DB1',
    @publication = 'DB1_repl1',
    @xact_seqno = 0x0015AC970002E99D000100000000;
