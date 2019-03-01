USE _Project
GO 

--PayIN
IF OBJECT_ID ( 'Finances.PayIn', 'P' ) IS NOT NULL   
    DROP PROCEDURE Finances.PayIn;  
GO  
CREATE PROCEDURE Finances.PayIn  
	  @cc varchar(25)
    , @user_id int
	, @sum money
AS
			IF EXISTS(SELECT * FROM Finances.UserAccount WHERE id = @user_id) 
						BEGIN TRY  
							BEGIN TRANSACTION;
								IF NOT EXISTs (SELECT * FROM Finances.CreditCard WHERE card_number = @cc)
									INSERT INTO Finances.CreditCard VALUES (@user_id,NULL, NULL, NULL, @cc, getdate())
								INSERT INTO Finances.PayinHistory VALUES (@user_id, (SELECT id FROM Finances.CreditCard WHERE card_number = @cc), @sum, getdate(), 1)  			
							COMMIT TRANSACTION;  
						END TRY  
						BEGIN CATCH  
							THROW;  
							ROLLBACK TRANSACTION; 
						END CATCH; 
			ELSE 
			SELECT 'No such user'
GO

--PayOut 
IF OBJECT_ID ( 'Finances.PayOut', 'P' ) IS NOT NULL   
    DROP PROCEDURE Finances.PayOut;  
GO  
CREATE PROCEDURE Finances.PayOut  
	  @cc_id int
    , @user_id int
	, @sum money 
AS
	DECLARE @com  decimal(4,2) = (SELECT commision FROM Finances.Regions r JOIN Finances.UserAccount ua on r.region_code = ua.region WHERE ua.id = @user_id )
	DECLARE @total money = (@com * @sum) + @sum
			IF EXISTS(SELECT * FROM Finances.CreditCard WHERE user_id = @user_id and id = @cc_id)
						BEGIN
							IF (SELECT total FROM Finances.UserTotal WHERE user_id = @user_id ) > @total
								BEGIN
										BEGIN TRY  
											BEGIN TRANSACTION;
												INSERT INTO Finances.PayoutHistory VALUES (@user_id, @cc_id, @sum, getdate(), @com, @total, 1) 
										END TRY  
										BEGIN CATCH  
											THROW;  
											ROLLBACK TRANSACTION; 
										END CATCH; 
								END
							ELSE
								SELECT 'Not enough money'
						END
			ELSE
				SELECT 'Rong credit card id'
GO
