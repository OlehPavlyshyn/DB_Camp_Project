--add users
IF OBJECT_ID ( 'Finances.AddUser', 'P' ) IS NOT NULL   
    DROP PROCEDURE Finances.AddUser;  
GO  
CREATE PROCEDURE Finances.AddUser  
	  @firstn varchar(25)
	, @lastn varchar(25)
	, @mail varchar(50)
	, @password varchar(25)
	, @loc varchar(2)
	, @tax decimal(4,2)
	, @phone varchar(25)
AS   
	IF NOT EXISTS(SELECT * FROM Finances.UserInformation WHERE email = @mail)
		BEGIN TRY  
			BEGIN TRANSACTION;
				INSERT INTO Finances.UserAccount VALUES (@firstn,@lastn,@loc,@tax,getdate())
				INSERT INTO Finances.UserInformation VALUES (@mail, @password, @phone, getdate(), NULL)
				SELECT 1
			COMMIT TRANSACTION;  
		END TRY  
		BEGIN CATCH  
			THROW;  
			ROLLBACK TRANSACTION; 
		END CATCH;  

GO