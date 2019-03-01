USE _ProjectDWH
GO
--USerAccountv2
IF OBJECT_ID ( 'p_UserAcountv2', 'P' ) IS NOT NULL   
    DROP PROCEDURE p_UserAcountv2
GO  
CREATE PROCEDURE p_UserAcountv2
AS
	BEGIN TRANSACTION;  
	BEGIN TRY  
   		DECLARE   @updateCount int
				, @insertCount int
				, @starttime datetime
				, @endtime datetime
		DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));
		SET @starttime = getdate()
		MERGE Fact.UserAccount AS TARGET
		USING _Projectv2.Finances.UserAccount AS SOURCE 
		ON (TARGET.id = SOURCE.id) 
		WHEN MATCHED AND  convert(datetime,convert(varchar,TARGET.modify_date_key)) < SOURCE.modify_date
			THEN UPDATE 
			SET    TARGET.region_code = SOURCE.region 
				 , TARGET.tax = SOURCE.tax 
				 , TARGET.modify_date_key = dbo.DatetoDateKey(SOURCE.modify_date)
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (id, region_code, tax,modify_date_key,userinfo_id) 
			VALUES (SOURCE.id, SOURCE.region, SOURCE.tax, dbo.DatetoDateKey(SOURCE.modify_date),SOURCE.id)
		OUTPUT $action INTO @SummaryOfChanges;
			SET @insertCount = ISNULL((SELECT COUNT(*) FROM @SummaryOfChanges WHERE Change = 'INSERT' GROUP BY Change),0)
			SET @updateCount = ISNULL((SELECT COUNT(*)	FROM @SummaryOfChanges WHERE Change = 'UPDATED' GROUP BY Change),0)
		SET @endtime = getdate()
	END TRY  
	BEGIN CATCH 
		DECLARE @res varchar(max) 
		SET   @res = convert(varchar,ERROR_NUMBER()) + ' ' + convert(varchar,ERROR_SEVERITY())  +' ' + ERROR_MESSAGE() 
		exec p_WritingLogs @res
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION;  
	END CATCH;  
	IF @@TRANCOUNT > 0  
		COMMIT TRANSACTION
		DECLARE   @ress varchar(max)
				, @time varchar(15)  
		SET @time = convert(varchar,DATEDIFF(ms,@starttime,@endtime))
		SET @ress = dbo.LogCreator('UserAccount',@updateCount,@insertCount,@time)
		exec p_WritingLogs @ress
GO 

--USerInfo
IF OBJECT_ID ( 'p_UserInfov2', 'P' ) IS NOT NULL   
    DROP PROCEDURE p_UserInfov2
GO  
CREATE PROCEDURE p_UserInfov2
AS
	BEGIN TRANSACTION;  
	BEGIN TRY  
   		DECLARE   @updateCount int
				, @insertCount int
				, @starttime datetime
				, @endtime datetime
		DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));
		SET @starttime = getdate()
		;WITH CTE AS (
		SELECT ui.user_id, ua.first_name,ua.second_name, ui.email, ui.password,ui.phone_number,ui.date_creating,ui.date_changing
		FROM _Projectv2.Finances.UserAccount  ua
		JOIN _Projectv2.Finances.UserInformation ui 
		ON ui.user_id = ua.id)
		MERGE Dimention.UserInfo AS TARGET
		USING CTE AS SOURCE 
		ON (TARGET.id = SOURCE.user_id) 
		WHEN MATCHED AND  convert(datetime,convert(varchar,TARGET.date_changing_key)) < SOURCE.date_creating
			THEN UPDATE 
			SET    TARGET.first_name = SOURCE.first_name 
				 , TARGET.last_name = SOURCE.second_name 
				 , TARGET.email = SOURCE.email 
				 , TARGET.password = SOURCE.password
				 , TARGET.phone_number = SOURCE.phone_number 
				 , TARGET.date_changing_key = dbo.DatetoDateKey(SOURCE.date_changing)
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT  
			VALUES (SOURCE.user_id, SOURCE.first_name, SOURCE.second_name,SOURCE.email,SOURCE.password,SOURCE.phone_number, dbo.DatetoDateKey(SOURCE.date_creating),NULL)
		OUTPUT $action INTO @SummaryOfChanges;
			SET @insertCount = ISNULL((SELECT COUNT(*) FROM @SummaryOfChanges WHERE Change = 'INSERT' GROUP BY Change),0)
			SET @updateCount = ISNULL((SELECT COUNT(*)	FROM @SummaryOfChanges WHERE Change = 'UPDATED' GROUP BY Change),0)
		SET @endtime = getdate()
	END TRY  
	BEGIN CATCH 
		DECLARE @res varchar(max) 
		SET   @res = convert(varchar,ERROR_NUMBER()) + ' ' + convert(varchar,ERROR_SEVERITY())  +' ' + ERROR_MESSAGE() 
		exec p_WritingLogs @res
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION;  
	END CATCH;  
	IF @@TRANCOUNT > 0  
		COMMIT TRANSACTION
		DECLARE   @ress varchar(max)
				, @time varchar(15)  
		SET @time = convert(varchar,DATEDIFF(ms,@starttime,@endtime))
		SET @ress = dbo.LogCreator('UserInfo',@updateCount,@insertCount,@time)
		exec p_WritingLogs @ress
GO 

--Credit Card
IF OBJECT_ID ( 'p_CreditCardv2', 'P' ) IS NOT NULL   
    DROP PROCEDURE p_CreditCardv2
GO  
CREATE PROCEDURE p_CreditCardv2
AS
	BEGIN TRANSACTION;  
	BEGIN TRY  
   		DECLARE   @updateCount int
				, @insertCount int
				, @starttime datetime
				, @endtime datetime
		DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));
		SET @starttime = getdate()
		MERGE Dimention.CreditCard AS TARGET
		USING  _Projectv2.Finances.CreditCard AS SOURCE 
		ON (TARGET.id = SOURCE.id) 
		WHEN MATCHED AND  convert(datetime,convert(varchar,TARGET.modify_date_key)) < SOURCE.modify_date
			THEN UPDATE 
			SET    TARGET.exp_month = SOURCE.exp_month 
				 , TARGET.exp_year = SOURCE.exp_year 
				 , TARGET.card_number = SOURCE.card_number 
				 , TARGET.modify_date_key = dbo.DatetoDateKey(SOURCE.modify_date)
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT  
			VALUES (SOURCE.id, SOURCE.user_id, SOURCE.card_type,SOURCE.exp_month,SOURCE.exp_year,SOURCE.card_number, dbo.DatetoDateKey(SOURCE.modify_date))
		OUTPUT $action INTO @SummaryOfChanges;
			SET @insertCount = ISNULL((SELECT COUNT(*) FROM @SummaryOfChanges WHERE Change = 'INSERT' GROUP BY Change),0)
			SET @updateCount = ISNULL((SELECT COUNT(*)	FROM @SummaryOfChanges WHERE Change = 'UPDATED' GROUP BY Change),0)
		SET @endtime = getdate()
	END TRY  
	BEGIN CATCH 
		DECLARE @res varchar(max) 
		SET   @res = convert(varchar,ERROR_NUMBER()) + ' ' + convert(varchar,ERROR_SEVERITY())  +' ' + ERROR_MESSAGE() 
		exec p_WritingLogs @res
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION;  
	END CATCH;  
	IF @@TRANCOUNT > 0  
		COMMIT TRANSACTION
		DECLARE   @ress varchar(max)
				, @time varchar(15)  
		SET @time = convert(varchar,DATEDIFF(ms,@starttime,@endtime))
		SET @ress = dbo.LogCreator('Credit Card',@updateCount,@insertCount,@time)
		exec p_WritingLogs @ress
GO 


--Teams 

IF OBJECT_ID ( 'p_Teamsv2', 'P' ) IS NOT NULL   
    DROP PROCEDURE p_Teamsv2
GO  
CREATE PROCEDURE p_Teamsv2
AS
	BEGIN TRANSACTION;  
	BEGIN TRY  
		DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));
   		DECLARE   @updateCount int
				, @insertCount int
				, @starttime datetime
				, @endtime datetime
		SET @starttime = getdate()
		MERGE Dimention.Teams AS TARGET
		USING  _Projectv2.Sport.Teams AS SOURCE 
		ON (TARGET.id = SOURCE.id) 
		WHEN MATCHED AND  convert(datetime,convert(varchar,TARGET.modify_date_key)) < SOURCE.modify_date
			THEN UPDATE 
			SET    TARGET.english_team_name = SOURCE.team_name 
				 , TARGET.spanish_team_name = SOURCE.team_name 
				 , TARGET.french_team_name = SOURCE.team_name 
				 , TARGET.tournament_id = SOURCE.tournament_id 
				 , TARGET.modify_date_key = dbo.DatetoDateKey(SOURCE.modify_date)
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT  
			VALUES (SOURCE.id, SOURCE.team_name,SOURCE.team_name,SOURCE.team_name,SOURCE.tournament_id, dbo.DatetoDateKey(SOURCE.modify_date))
		OUTPUT $action INTO @SummaryOfChanges;
			SET @insertCount = ISNULL((SELECT COUNT(*) FROM @SummaryOfChanges WHERE Change = 'INSERT' GROUP BY Change),0)
			SET @updateCount = ISNULL((SELECT COUNT(*)	FROM @SummaryOfChanges WHERE Change = 'UPDATED' GROUP BY Change),0)
		SET @endtime = getdate()
	END TRY  
	BEGIN CATCH 
		DECLARE @res varchar(max) 
		SET   @res = convert(varchar,ERROR_NUMBER()) + ' ' + convert(varchar,ERROR_SEVERITY())  +' ' + ERROR_MESSAGE() 
		exec p_WritingLogs @res
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION;  
	END CATCH;  
	IF @@TRANCOUNT > 0  
		COMMIT TRANSACTION
		DECLARE   @ress varchar(max)
				, @time varchar(15)  
		SET @time = convert(varchar,DATEDIFF(ms,@starttime,@endtime))
		SET @ress = dbo.LogCreator('Teams',@updateCount,@insertCount,@time)
		exec p_WritingLogs @ress
GO 

--Tournaments

IF OBJECT_ID ( 'p_Tournamentsv2', 'P' ) IS NOT NULL   
    DROP PROCEDURE p_Tournamentsv2
GO  
CREATE PROCEDURE p_Tournamentsv2
AS
	BEGIN TRANSACTION;  
	BEGIN TRY  
   		DECLARE   @updateCount int
				, @insertCount int
				, @starttime datetime
				, @endtime datetime
		DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));
		SET @starttime = getdate()
		MERGE Dimention.Tournament AS TARGET
		USING  _Projectv2.Sport.Tournament AS SOURCE 
		ON (TARGET.id = SOURCE.id) 
		WHEN MATCHED AND  convert(datetime,convert(varchar,TARGET.modify_date_key)) < SOURCE.modify_date
			THEN UPDATE 
			SET    TARGET.english_tournament_name = SOURCE.tournament_name 
				 , TARGET.spanish_tournament_name = SOURCE.tournament_name 
				 , TARGET.french_tournament_name = SOURCE.tournament_name 
				 , TARGET.modify_date_key = dbo.DatetoDateKey(SOURCE.modify_date)
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT  
			VALUES (SOURCE.id, SOURCE.tournament_name,SOURCE.tournament_name,SOURCE.tournament_name, dbo.DatetoDateKey(SOURCE.modify_date))
		OUTPUT $action INTO @SummaryOfChanges;
			SET @insertCount = ISNULL((SELECT COUNT(*) FROM @SummaryOfChanges WHERE Change = 'INSERT' GROUP BY Change),0)
			SET @updateCount = ISNULL((SELECT COUNT(*)	FROM @SummaryOfChanges WHERE Change = 'UPDATED' GROUP BY Change),0)
		SET @endtime = getdate()
	END TRY  
	BEGIN CATCH 
		DECLARE @res varchar(max) 
		SET   @res = convert(varchar,ERROR_NUMBER()) + ' ' + convert(varchar,ERROR_SEVERITY())  +' ' + ERROR_MESSAGE() 
		exec p_WritingLogs @res
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION;  
	END CATCH;  
	IF @@TRANCOUNT > 0  
		COMMIT TRANSACTION
		DECLARE   @ress varchar(max)
				, @time varchar(15)  
		SET @time = convert(varchar,DATEDIFF(ms,@starttime,@endtime))
		SET @ress = dbo.LogCreator('Tournaments',@updateCount,@insertCount,@time)
		exec p_WritingLogs @ress
GO 


--Matches

IF OBJECT_ID ( 'p_Matchesv2', 'P' ) IS NOT NULL   
    DROP PROCEDURE p_Matchesv2
GO  
CREATE PROCEDURE p_Matchesv2
AS
	BEGIN TRANSACTION;  
	BEGIN TRY  
		DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));
   		DECLARE   @insertCount int
				, @updateCount int
				, @starttime datetime
				, @endtime datetime
		SET @starttime = getdate()
		MERGE Fact.Matches AS TARGET
		USING  _Projectv2.Sport.MAtches AS SOURCE 
		ON (TARGET.id = SOURCE.id) 
			WHEN NOT MATCHED BY TARGET AND SOURCE.Status = 'finished' THEN 
			INSERT  
			VALUES (SOURCE.id, SOURCE.home_team_id,SOURCE.away_team_id,SOURCE.tournament_id,
			 dbo.DatetoDateKey(SOURCE.start_date), dbo.TimetoTimeKey(SOURCE.start_date), dbo.DatetoDateKey(SOURCE.end_date) , dbo.TimetoTimeKey(SOURCE.end_date),SOURCE.result)
		OUTPUT $action INTO @SummaryOfChanges;
			SET @insertCount = ISNULL((SELECT COUNT(*) FROM @SummaryOfChanges WHERE Change = 'INSERT' GROUP BY Change),0)
			SET @updateCount = ISNULL((SELECT COUNT(*)	FROM @SummaryOfChanges WHERE Change = 'UPDATED' GROUP BY Change),0)
		SET @endtime = getdate()
	END TRY  
	BEGIN CATCH 
		DECLARE @res varchar(max) 
		SET   @res = convert(varchar,ERROR_NUMBER()) + ' ' + convert(varchar,ERROR_SEVERITY())  +' ' + ERROR_MESSAGE() 
		exec p_WritingLogs @res
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION;  
	END CATCH;  
	IF @@TRANCOUNT > 0  
		COMMIT TRANSACTION
		DECLARE   @ress varchar(max)
				, @time varchar(15)  
		SET @time = convert(varchar,DATEDIFF(ms,@starttime,@endtime))
		SET @ress = dbo.LogCreator('Matches',0,@insertCount,@time)
		exec p_WritingLogs @ress
GO 

--Events

IF OBJECT_ID ( 'p_Eventsv2', 'P' ) IS NOT NULL   
    DROP PROCEDURE p_Eventsv2
GO  
CREATE PROCEDURE p_Eventsv2
AS
	BEGIN TRANSACTION;  
	BEGIN TRY  
		DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));
   		DECLARE   @insertCount int
				, @updateCount int
				, @starttime datetime
				, @endtime datetime
		SET @starttime = getdate()
		;WITH CTE AS (SELECT e.id,match_id,home_win_odds,draw_odds,away_win_odds,m.modify_date  FROM  _Projectv2.Sport.Matches m 
		JOIN  _Projectv2.Sport.Event e on e.match_id = m.id  WHERE status = 'finished')
		
		MERGE Fact.Event AS TARGET
		USING  CTE AS SOURCE 
		ON (TARGET.id = SOURCE.id) 
			WHEN NOT MATCHED BY TARGET   THEN 
			INSERT  
			VALUES (SOURCE.id, SOURCE.match_id,SOURCE.home_win_odds,SOURCE.draw_odds,
			 SOURCE.away_win_odds, dbo.DatetoDateKey(SOURCE.modify_date))
		OUTPUT $action INTO @SummaryOfChanges;
			SET @insertCount = ISNULL((SELECT COUNT(*) FROM @SummaryOfChanges WHERE Change = 'INSERT' GROUP BY Change),0)
			SET @updateCount = ISNULL((SELECT COUNT(*)	FROM @SummaryOfChanges WHERE Change = 'UPDATED' GROUP BY Change),0)
		SET @endtime = getdate()
	END TRY  
	BEGIN CATCH 
		DECLARE @res varchar(max) 
		SET   @res = convert(varchar,ERROR_NUMBER()) + ' ' + convert(varchar,ERROR_SEVERITY())  +' ' + ERROR_MESSAGE() 
		exec p_WritingLogs @res
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION;  
	END CATCH;  
	IF @@TRANCOUNT > 0  
		COMMIT TRANSACTION
		DECLARE   @ress varchar(max)
				, @time varchar(15)  
		SET @time = convert(varchar,DATEDIFF(ms,@starttime,@endtime))
		SET @ress = dbo.LogCreator('Events',0,@insertCount,@time)
		exec p_WritingLogs @ress
GO 


--BetHistory


IF OBJECT_ID ( 'p_BetHistoryv2', 'P' ) IS NOT NULL   
    DROP PROCEDURE p_BetHistoryv2
GO  
CREATE PROCEDURE p_BetHistoryv2
AS
	BEGIN TRANSACTION;  
	BEGIN TRY  
		DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));
   		DECLARE   @insertCount int
				, @updateCount int
				, @starttime datetime
				, @endtime datetime
		SET @starttime = getdate()	
		MERGE Fact.BetsHistory AS TARGET
		USING  _Projectv2.Finances.BetsHistory  AS SOURCE 
		ON (TARGET.id = SOURCE.id) 
			WHEN NOT MATCHED BY TARGET AND SOURCE.status = 'finished'   THEN 
			INSERT  
			VALUES (SOURCE.id, SOURCE.user_id,SOURCE.event_id,SOURCE.coefficient,
			 dbo.DatetoDateKey(SOURCE.date), dbo.TimetoTimeKey(SOURCE.date),SOURCE.ante,SOURCE.bet_condition , SOURCE.choice)
		OUTPUT $action INTO @SummaryOfChanges;
			SET @insertCount = ISNULL((SELECT COUNT(*) FROM @SummaryOfChanges WHERE Change = 'INSERT' GROUP BY Change),0)
			SET @updateCount = ISNULL((SELECT COUNT(*)	FROM @SummaryOfChanges WHERE Change = 'UPDATED' GROUP BY Change),0)
		SET @endtime = getdate()
	END TRY  
	BEGIN CATCH 
		DECLARE @res varchar(max) 
		SET   @res = convert(varchar,ERROR_NUMBER()) + ' ' + convert(varchar,ERROR_SEVERITY())  +' ' + ERROR_MESSAGE() 
		exec p_WritingLogs @res
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION;  
	END CATCH;  
	IF @@TRANCOUNT > 0  
		COMMIT TRANSACTION
		DECLARE   @ress varchar(max)
				, @time varchar(15)  
		SET @time = convert(varchar,DATEDIFF(ms,@starttime,@endtime))
		SET @ress = dbo.LogCreator('BetHistory',0,@insertCount,@time)
		exec p_WritingLogs @ress
GO 


IF OBJECT_ID ( 'p_Transactions', 'P' ) IS NOT NULL   
    DROP PROCEDURE p_Transactions
GO  
CREATE PROCEDURE p_Transactions
AS
	BEGIN TRANSACTION;  
	BEGIN TRY  
   		DECLARE   @insertCount int
				, @starttime datetime
				, @endtime datetime
		SET @starttime = getdate()
		INSERT INTO Fact.TransactionHistory
			SELECT   user_id
					, card_id
					, sum
					, dbo.DatetoDateKey(date)
					, dbo.TimetoTimeKey(date)
					, 0.00
					, sum
					, 'cashin'
			FROM _Projectv2.Finances.PayinHistory 
			WHERE status = 1 and (SELECT isnull(max(modify_date_key + convert(float,modify_time_key)/10000),1) FROM Fact.TransactionHistory) < (dbo.DatetoDateKey(date) + convert(float,dbo.TimetoTimeKey(date))/10000)
			UNION 
			SELECT    user_id
					, card_id
					, sum
					, dbo.DatetoDateKey(date)
					, dbo.TimetoTimeKey(date)
					, commission
					, total_sum
					, 'cashout'
			FROM _Projectv2.Finances.PayoutHistory 
			WHERE status = 1 and (SELECT isnull(max(modify_date_key + convert(float,modify_time_key)/10000),1) FROM Fact.TransactionHistory) < (dbo.DatetoDateKey(date) + convert(float,dbo.TimetoTimeKey(date))/10000)

		SET @insertCount = @@ROWCOUNT
		SET @endtime = getdate()
	END TRY  
	BEGIN CATCH 
		DECLARE @res varchar(max) 
		SET   @res = convert(varchar,ERROR_NUMBER()) + ' ' + convert(varchar,ERROR_SEVERITY())  +' ' + ERROR_MESSAGE() 
		exec p_WritingLogs @res
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION;  
	END CATCH;  

	IF @@TRANCOUNT > 0  
		COMMIT TRANSACTION
		DECLARE   @ress varchar(max)
				, @time varchar(15)  
		SET @time = convert(varchar,DATEDIFF(ms,@starttime,@endtime))
		SET @ress = dbo.LogCreator('Transaction',0,@insertCount,@time)
		exec p_WritingLogs @ress
GO

--FullStatistic

IF OBJECT_ID ( 'p_FullStatistic', 'P' ) IS NOT NULL   
    DROP PROCEDURE p_FullStatistic
GO  
CREATE PROCEDURE p_FullStatistic
AS
	BEGIN TRANSACTION;  
	BEGIN TRY  
   		DECLARE   @insertCount int
				, @starttime datetime
				, @endtime datetime
		DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));
		SET @starttime = getdate()
		MERGE Dimention.FullStatistic AS TARGET
		USING  _Projectv2.Sport.FullStatistic  AS SOURCE 
		ON (TARGET.match_id = SOURCE.match_id) 
			WHEN NOT MATCHED BY TARGET   THEN 
			INSERT  
			VALUES ( SOURCE.match_id 
				, SOURCE.home_team_goals 
				, SOURCE.away_team_goals 
				, SOURCE.Referee 
				, SOURCE.home_team_shots 
				, SOURCE.away_team_shots 
				, SOURCE.half_time_home_team_goals
				, SOURCE.half_time_away_team_goals 
				, SOURCE.home_team_shots_on_target 
				, SOURCE.away_team_shots_on_target 
				, SOURCE.home_team_fouls 
				, SOURCE.away_team_fouls 
				, SOURCE.home_team_corners 
				, SOURCE.away_team_corners 
				, SOURCE.home_team_yellow_cards 
				, SOURCE.away_team_yellow_cards 
				, SOURCE.home_team_red_cards 
				, SOURCE.away_team_red_cards 
				, dbo.DatetoDateKey(SOURCE.modify_date))
		OUTPUT $action INTO @SummaryOfChanges;
			SET @insertCount = ISNULL((SELECT COUNT(*) FROM @SummaryOfChanges WHERE Change = 'INSERT' GROUP BY Change),0)
			SET @endtime = getdate()
	END TRY  
	BEGIN CATCH 
		DECLARE @res varchar(max) 
		SET   @res = convert(varchar,ERROR_NUMBER()) + ' ' + convert(varchar,ERROR_SEVERITY())  +' ' + ERROR_MESSAGE() 
		exec p_WritingLogs @res
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION;  
	END CATCH;  

	IF @@TRANCOUNT > 0  
		COMMIT TRANSACTION
		DECLARE   @ress varchar(max)
				, @time varchar(15)  
		SET @time = convert(varchar,DATEDIFF(ms,@starttime,@endtime))
		SET @ress = dbo.LogCreator('FullStatistic',0,@insertCount,@time)
		exec p_WritingLogs @ress
GO
