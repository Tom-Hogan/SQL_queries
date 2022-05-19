CREATE PROCEDURE dbo.insert_inferred_dim_sales_rep
    @sales_rep_key nvarchar(20)
AS
/* ================================================================================================
Purpose:
    Checks if a record already exists for the given sales rep identifier (sales rep key).
    If it does not exists, an inferred member is inserted.

Example:
    EXEC dbo.insert_inferred_dim_sales_rep
        @sales_rep_key = 'TEST001'

History:
    2013-04-29  Tom Hogan           Created.
================================================================================================ */
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;


    DECLARE @sales_rep_id int;

    /* strip spaces from passed-in value */
    SET @sales_rep_key = trim(@sales_rep_key);


    /* check for existence of record with given key */
    SET @sales_rep_id =
            (
                SELECT  sales_rep_id
                FROM    dbo.dim_sales_rep
                WHERE   sales_rep_key = @sales_rep_key
            );


    /*  if a record with the given key was not found, insert a rew record */
    IF @sales_rep_id IS NULL
    BEGIN
        INSERT INTO dbo.dim_sales_rep
        (
                sales_rep_key,
                last_name,
                first_name,
                middle_initial,
                full_name,
                sales_manager_last_name,
                sales_manager_first_name,
                sales_manager_middle_initial,
                sales_manager_full_name,
                rvp_last_name,
                rvp_first_name,
                rvp_middle_initial,
                rvp_full_name,
                sales_role,
                inactive_flag,
                inferred_member_flag
        )
        SELECT  @sales_rep_key AS sales_rep_key,
                'N/A'          AS last_name,
                'N/A'          AS first_name,
                ''             AS middle_initial,
                'N/A'          AS full_name,
                'N/A'          AS sales_manager_last_name,
                'N/A'          AS sales_manager_first_name,
                ''             AS sales_manager_middle_initial,
                'N/A'          AS sales_manager_full_name,
                'N/A'          AS rvp_last_name,
                'N/A'          AS rvp_first_name,
                ''             AS rvp_middle_initial,
                'N/A'          AS rvp_full_name,
                'N/A'          AS sales_role,
                0              AS inactive_flag,
                1              AS inferred_member_flag;

        SET @sales_rep_id = scope_identity();
    END;


    SELECT  sales_rep_id,
            sales_rep_key
    FROM    dbo.dim_sales_rep
    WHERE   sales_rep_id = @sales_rep_id;

END;
GO
