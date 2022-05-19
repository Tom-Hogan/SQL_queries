/* ================================================================================================
Purpose:
    Updates the owner of a reporting services subscription.

History:
    2010-04-26  Tom Hogan           Created.
================================================================================================ */
USE ReportServer;
SET NOCOUNT ON;


DECLARE @old_user_login nvarchar(520),
        @new_user_login nvarchar(520),
        @old_user_id    uniqueidentifier,
        @new_user_id    uniqueidentifier;

SET @old_user_login = N'domain\user_old'; /* update with subscription owner to be changed */
SET @new_user_login = N'domain\user_new'; /* update with new subscription owner */


/* get the user ID of the logins */
SET @old_user_id =
        (
            SELECT  UserID
            FROM    dbo.Users
            WHERE   UserName = @old_user_login
        );
SET @new_user_id =
        (
            SELECT  UserID
            FROM    dbo.Users
            WHERE   UserName = @new_user_login
        );


/* if the new user ID exist in reporting services, update old value with the new one */
IF @new_user_id IS NOT NULL
BEGIN
    UPDATE  dbo.Subscriptions
    SET     OwnerID = @new_user_id
    WHERE   OwnerID = @old_user_id;
END;
/* else return message that the new user is not in reporting services */
ELSE
BEGIN
    SELECT  'User ' + @new_user_login + ' does not exist in reporting services.';
END;
