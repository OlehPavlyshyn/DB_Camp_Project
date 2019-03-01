USE _Project
GO

CREATE TRIGGER t_SetResalt
ON Sport.FullStatistic
FOR INSERT
AS 
	BEGIN TRY  
		BEGIN TRANSACTION;
			DECLARE @date datetime = getdate() 
			UPDATE Sport.Matches
			SET   end_date = @date
				, modify_date = @date
				, result = CASE WHEN (SELECT home_team_goals - away_team_goals FROM inserted) > 0
								THEN 'h'
							  WHEN (SELECT home_team_goals - away_team_goals FROM inserted) = 0
								THEN 'd'
							  WHEN (SELECT home_team_goals - away_team_goals FROM inserted) < 0
								THEN 'a'
						  END
			WHERE id = (SELECT match_id FROM inserted)
		COMMIT TRANSACTION;  
	END TRY  
	BEGIN CATCH  
		THROW;  
		ROLLBACK TRANSACTION; 
	END CATCH;
GO 

--tr_BetEnlistment

CREATE TRIGGER tr_BetEnlistment
   ON Sport.Matches
   AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON;
    IF UPDATE (result) 
    BEGIN
		UPDATE Finances.BetsHistory
		SET   -- date = getdate()
			   status = 'finished'
			 , bet_condition = CASE WHEN choice = (SELECT result FROM inserted)
								THEN 1
							 ELSE 0
							END 
		WHERE event_id = (SELECT e.id FROM Sport.Event e RIGHT JOIN inserted u ON e.match_id =u.id) and status NOT LIKE 'deleted'
	END
  END
GO



