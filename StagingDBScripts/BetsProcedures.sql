USE _Project
GO


--GetCoeff
IF OBJECT_ID ( 'Finances.GetCoeff', 'f' ) IS NOT NULL   
    DROP FUNCTION Finances.GetCoeff;  
GO  
CREATE FUNCTION Finances.GetCoeff (@bet varchar(1), @event_id int) 
RETURNS decimal(4,2)
AS	
BEGIN
	DECLARE @res decimal(4,2);
	IF @bet = 'h'
		SET @res = (SELECT home_win_odds FROM Sport.Event WHERE id = @event_id)
	ELSE 
		BEGIN
		IF @bet = 'd'
			SET @res = (SELECT draw_odds FROM Sport.Event WHERE id = @event_id)
		ELSE
			SET @res = (SELECT away_win_odds FROM Sport.Event WHERE id = @event_id) 
		END
	RETURN @res
END
GO




---add bet version 2

IF OBJECT_ID ( 'Finances.AddBet', 'P' ) IS NOT NULL   
    DROP PROCEDURE Finances.AddBet;  
GO  
CREATE PROCEDURE Finances.AddBet  
	  @event_id int
    , @user_id int
	, @bet varchar(1)
	, @ante money
AS   
	DECLARE @date datetime = getdate()
	SET NOCOUNT ON; 
	IF EXISTS(SELECT * from Finances.UserAccount WHERE id = @user_id)
		BEGIN
			IF (SELECT deadline FROM Sport.Event WHERE id = @event_id) > @date
				BEGIN  
					IF (SELECT (ISNULL(total,0) -  @ante) FROM Finances.UserTotal WHERE user_id = @user_id) >= 0
						BEGIN TRY  
							BEGIN TRANSACTION;
								INSERT INTO Finances.BetsHistory VALUES (@user_id, @event_id, Finances.GetCoeff(@bet,@event_id),getdate(), @ante, 'In process',0,@bet) 
								SELECT 1 as result
							COMMIT TRANSACTION;  
						END TRY  
						BEGIN CATCH  
							THROW;  
							ROLLBACK TRANSACTION; 
						END CATCH; 
					ELSE 
						SELECT 'U don`t have enoughf money' as result
				END
			ELSE 
				SELECT 'U cant add your bet' as result
		END
	ELSE
		SELECT 'Rong rights' as result
GO

--updatebetv2
IF OBJECT_ID ( 'Finances.UpdateBet', 'P' ) IS NOT NULL   
	DROP PROCEDURE Finances.UpdateBet;  
GO  
CREATE PROCEDURE Finances.UpdateBet  
	  @id int 
	, @user_id int
	, @bet varchar(1) 
	, @ante money 
AS   
	DECLARE  @date datetime = getdate()
			, @total money = (SELECT ut.total + bh.ante  FROM Finances.UserTotal ut JOIN Finances.BetsHistory bh on bh.user_id = ut.user_id WHERE bh.id = @id)
	
	SET NOCOUNT ON;  
	IF @date < (SELECT deadline FROM Finances.BetsHistory bh JOIN Sport.Event e ON bh.event_id = e.id  WHERE bh.id = @id) 
			AND 
			   (SELECT status FROM Finances.BetsHistory WHERE id = @id) <> 'deleted'
		BEGIN
			IF @bet IS NOT NULL    
				BEGIN TRY  
					BEGIN TRANSACTION;
						UPDATE Finances.BetsHistory
						SET   coefficient = Finances.GetCoeff(@bet,(SELECT event_id FROM Finances.BetsHistory WHERE @id = id))
							, date = @date	
							, choice = @bet 
						WHERE @id = id
						SELECT 1
					COMMIT TRANSACTION;  
				END TRY  
				BEGIN CATCH  
					THROW;  
					ROLLBACK TRANSACTION; 
				END CATCH;  
			IF  @total > ISNULL(@ante,0)
				BEGIN TRY  
					BEGIN TRANSACTION; 
						UPDATE Finances.BetsHistory
						SET   ante = @ante
							, date = @date 
						WHERE @id = id
						SELECT 1
					COMMIT TRANSACTION;  
				END TRY  
				BEGIN CATCH  
					THROW;  
					ROLLBACK TRANSACTION; 
				END CATCH; 	
		END
	ELSE 
		SELECT 'U can`t change your bet '
GO 

--deleebetv2
IF OBJECT_ID ( 'Finances.DeleteBetv2 ', 'P' ) IS NOT NULL   
    DROP PROCEDURE Finances.DeleteBet;  
GO  
CREATE PROCEDURE Finances.DeleteBet  
	  @id int
    , @user_id int
AS   
	DECLARE @date datetime = getdate()
	SET NOCOUNT ON;  
	IF @date < (SELECT deadline FROM Finances.BetsHistory bh JOIN Sport.Event e ON bh.event_id = e.id  WHERE bh.id = @id)
	 and (SELECT status FROM Finances.BetsHistory where id =@id)  NOT LIKE 'deleted'
		BEGIN TRY  
			BEGIN TRANSACTION;
				UPDATE Finances.BetsHistory
				SET   status = 'deleted'
					, date = @date
				WHERE @id = id and status NOT LIKE 'deleted'
				SELECT 1
			COMMIT TRANSACTION;  
		END TRY  
		BEGIN CATCH  
			THROW;  
			ROLLBACK TRANSACTION; 
		END CATCH; 
	ELSE 
		SELECT 'U can`t change your bet '
GO 
