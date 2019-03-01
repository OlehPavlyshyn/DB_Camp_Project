CREATE DATABASE _ProjectDWH
GO

USE _ProjectDWH
GO


CREATE SCHEMA Fact
GO


CREATE SCHEMA Dimention
GO

IF OBJECT_ID ( ' dbo.DatetoDateKey', 'F' ) IS NOT NULL   
    DROP FUNCTION  dbo.DatetoDateKey;
GO 
CREATE FUNCTION dbo.DatetoDateKey (@DATE datetime)  
RETURNS bigint
WITH EXECUTE AS CALLER  
AS  
BEGIN  
     DECLARE @DataKey bigint;  
     SET @DataKey=  convert(bigint,(convert(varchar, @DATE, 12)))
     RETURN(@DataKey);  
END;  
GO  

IF OBJECT_ID ( ' dbo.TimetoTimeKey ', 'F' ) IS NOT NULL   
    DROP FUNCTION  dbo.TimetoTimeKey;
GO 
CREATE FUNCTION dbo.TimetoTimeKey (@DATE datetime)  
RETURNS int
WITH EXECUTE AS CALLER  
AS  
BEGIN  
     DECLARE @TimeKey int;  
     SET @TimeKey= convert(int,(replace(convert(varchar(5), @DATE,108),':','')))
     RETURN(@TimeKey);  
END;  
GO  


EXEC sp_configure 'xp_cmdshell', 1;  
GO  
RECONFIGURE;
GO
--writing to log file

IF OBJECT_ID ( 'p_WritingLogs ', 'P' ) IS NOT NULL   
    DROP PROCEDURE p_WritingLogs;
GO  
CREATE PROCEDURE p_WritingLogs   
   @log varchar(max)
AS   
   	declare @cmdtxt as varchar(255)
	select @cmdtxt = 'echo ' + convert(varchar, getdate(), 121) + '        ' + @log + ' >> E:logs.log'
	exec master..xp_cmdshell @cmdtxt 
GO  



IF OBJECT_ID ( ' dbo.LogCreator ', 'F' ) IS NOT NULL   
    DROP FUNCTION  dbo.LogCreator;
GO  
CREATE FUNCTION dbo.LogCreator (@table varchar(20), @updated int, @inserted int,@time varchar(20))
RETURNS varchar(max)  
WITH EXECUTE AS CALLER  
AS  
BEGIN  
 DECLARE @res varchar(max)
 SET @res = 'Success data transfer for:' + @table + '.' + ' Updated rows: ' + convert(varchar, @updated) + '  Inserted rows: ' +  convert(varchar, @inserted) + '  total time:' + @time
  RETURN(@res) 
END;  
GO  


--DimTime

--Merge



DROP TABLE IF EXISTS Dimention.Date
GO
CREATE TABLE Dimention.Date (
	  id bigint 
	, date_value date 
	, month_day_number smallint
	, year_month_number smallint 
	, year_number smallint
	, week_day_number smallint
	, ua_month_name varchar(15)
	, pl_month_name varchar(15)
	, fr_month_name varchar(15)
	, us_month_name varchar(15)
	, ua_day_name varchar(15)
	, pl_day_name varchar(15)
	, fr_day_name varchar(15)
	, us_day_name varchar(15)
	, year_month VARCHAR(20)
	 CONSTRAINT PK_DateKey PRIMARY KEY  (id)
)
GO


IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Dimention.Time'))
BEGIN
DECLARE   @starttime datetime = '2019-02-12 00:00:00.000'
		, @endtime datetime = '2019-02-12 23:59:00.00'
;WITH   cte(time)
AS     (SELECT @starttime AS time 
        UNION ALL
        SELECT dateadd(minute,1,time) 
        FROM   cte
        WHERE  time < @endtime
       )

SELECT    dbo.TimetoTimeKey(time)							as id
		, convert(varchar(5),time,114 )							as time
		, DATEPART(hh,time)									as twenty_four_hour_clock
		, CASE WHEN DATEPART(hh,time) > 12
			THEN convert(varchar,(DATEPART(hh,time) -12)) + ' p.m'
		  WHEN DATEPART(hh,time) = 0
			THEN '12 a.m'
			ELSE  convert(varchar,(DATEPART(hh,time) )) + ' a.m'
		  END												as twelve_hour_clock
		, DATEPART(mi,time)									as minute
INTO  Dimention.Time
FROM cte  OPTION (MAXRECURSION 0)
END
GO
ALTER TABLE  Dimention.Time
ALTER COLUMN id int NOT NULL
GO
ALTER TABLE  Dimention.Time
ADD CONSTRAINT PK_TimeKey PRIMARY KEY (id)
GO


DROP TABLE IF EXISTS Dimention.Regions
GO
CREATE TABLE Dimention.Regions (
	  code varchar(2) 
	, name varchar(10)
	, currency decimal(4,2)
	, currency_name varchar(3)
	, commision decimal(4,2)
	, time_zone smallint
	, modify_date_key bigint 
	CONSTRAINT PK_RegionCode PRIMARY KEY  (code),
    CONSTRAINT FK_Regions_DataKey FOREIGN KEY (modify_date_key)
	REFERENCES Dimention.Date(id)
)
GO
ALTER TABLE Dimention.Regions
NOCHECK CONSTRAINT FK_Regions_DataKey
GO


INSERT INTO Dimention.Regions VALUES ('ua', 'Ukraine',27.7409, 'UAH',  0.01, 2, dbo.DatetoDateKey(getdate())),
									('us', 'USA',1, 'USD',  0.02,6,  dbo.DatetoDateKey(getdate())),
									('pl', 'Poland', 3.71979, 'PLN', 0.015,1, dbo.DatetoDateKey(getdate())),
									('fr', 'France',0.8728, 'EUR', 1, 0.015, dbo.DatetoDateKey(getdate()))
GO

DROP TABLE IF EXISTS  Dimention.UserInfo
GO
CREATE TABLE Dimention.UserInfo (
	  id int
	, first_name varchar(25)
	, last_name varchar(25)
	, email varchar(50)
	, password varchar(25)
	, phone_number varchar(25)
	, date_creating_key bigint 
	, date_changing_key bigint 
	CONSTRAINT FK_UserInfo_UserAccount PRIMARY KEY (id),
    CONSTRAINT FK_UserInfo_dcr_DataKey FOREIGN KEY (date_creating_key)
	REFERENCES Dimention.Date(id),
	CONSTRAINT FK_UserInfo_dch_DataKey FOREIGN KEY (date_changing_key)
	REFERENCES Dimention.Date(id),
)
GO
ALTER TABLE Dimention.UserInfo
NOCHECK CONSTRAINT FK_UserInfo_dcr_DataKey
GO
ALTER TABLE Dimention.UserInfo
NOCHECK CONSTRAINT FK_UserInfo_dch_DataKey
GO

					

DROP TABLE IF EXISTS Fact.UserAccount
GO
CREATE TABLE Fact.UserAccount (
	  id int NOT NULL 
	, userinfo_id int NOT NULL 
	, region_code varchar(2) 
	, tax decimal(4,2)
	, modify_date_key bigint
	CONSTRAINT PK_UserAccount PRIMARY KEY  (id),
    CONSTRAINT FK_UserAccount_RegionCode FOREIGN KEY (region_code)
	REFERENCES Dimention.Regions(code),
    CONSTRAINT FK_UserAccount_DataKey FOREIGN KEY (modify_date_key)
	REFERENCES Dimention.Date(id),
	CONSTRAINT FK_UserAccount_UserInfo FOREIGN KEY (userinfo_id)
	REFERENCES Dimention.UserInfo(id),
)
GO 


DROP TABLE IF EXISTS Dimention.CreditCard
GO
CREATE TABLE Dimention.CreditCard (
	  id int
	, user_id int
	, card_type varchar(25)
	, exp_month tinyint
	, exp_year smallint
	, card_number  varchar(20)
	, modify_date_key bigint 
	CONSTRAINT PK_CreditCard PRIMARY KEY  (id),
    CONSTRAINT FK_CreditCard_UserCount FOREIGN KEY (user_id)
	REFERENCES Fact.UserAccount(id),
    CONSTRAINT FK_CreditCard_DataKey FOREIGN KEY (modify_date_key)
	REFERENCES Dimention.Date(id)
	) 
GO
ALTER TABLE Dimention.CreditCard
NOCHECK CONSTRAINT FK_CreditCard_DataKey
GO

DROP TABLE IF EXISTS Dimention.Tournament
GO
CREATE TABLE Dimention.Tournament (
	  id int 
	, english_tournament_name varchar(30)
	, spanish_tournament_name varchar(30)
	, french_tournament_name varchar(30)
	, modify_date_key bigint
	CONSTRAINT PK_Tournament PRIMARY KEY  (id),
    CONSTRAINT FK_Tournament_DataKey FOREIGN KEY (modify_date_key)
	REFERENCES Dimention.Date(id)
	)
GO
ALTER TABLE Dimention.Tournament
NOCHECK CONSTRAINT FK_Tournament_DataKey
GO 

DROP TABLE IF EXISTS Dimention.Teams
GO
CREATE TABLE Dimention.Teams (
	  id int
	, english_team_name varchar(25)
	, spanish_team_name varchar(25)
	, french_team_name varchar(25)
	, tournament_id int
	, modify_date_key bigint 
	CONSTRAINT PK_Teams PRIMARY KEY  (id),
	CONSTRAINT FK_Teams_Tournaments FOREIGN KEY (tournament_id)
	REFERENCES Dimention.Tournament(id),
    CONSTRAINT FK_Teams_DateKey FOREIGN KEY (modify_date_key)
	REFERENCES Dimention.Date(id)
	)
GO
ALTER TABLE Dimention.Teams
NOCHECK CONSTRAINT FK_Teams_DateKey
GO

DROP TABLE IF EXISTS Fact.Matches
GO
CREATE TABLE Fact.Matches (
	  id int 
	, home_team_id int 
	, away_team_id int
	, tournament_id int
	, start_date_key bigint 
	, start_time_key int
	, end_date_key bigint
	, end_time_key int
	, result varchar(1)
	CONSTRAINT PK_Matches PRIMARY KEY  (id),
	CONSTRAINT FK_Matches_home_team FOREIGN KEY (id)
	REFERENCES Dimention.Teams(id),
	CONSTRAINT FK_Matches_away_team FOREIGN KEY (id)
	REFERENCES Dimention.Teams(id),
	CONSTRAINT FK_Matches_Tournaments FOREIGN KEY (id)
	REFERENCES Dimention.Tournament(id),
	CONSTRAINT FK_Matches_start_date_DataKey FOREIGN KEY (start_date_key)
	REFERENCES Dimention.Date(id),
	CONSTRAINT FK_Matches_end_date_DataKey FOREIGN KEY (end_date_key)
	REFERENCES Dimention.Date(id),
	CONSTRAINT FK_Matches_End_Time_TimeKey FOREIGN KEY (end_time_key)
	REFERENCES Dimention.Time(id),
    CONSTRAINT FK_Matches_Start_Time_DataKey FOREIGN KEY (start_time_key)
	REFERENCES Dimention.Time(id)

)
GO
ALTER TABLE Fact.Matches
ADD CONSTRAINT CHK_Matches CHECK (result in ('h','d','a'));
GO
ALTER TABLE Fact.Matches
NOCHECK CONSTRAINT FK_Matches_home_team
GO
ALTER TABLE Fact.Matches
NOCHECK CONSTRAINT FK_Matches_away_team
GO
ALTER TABLE Fact.Matches
NOCHECK CONSTRAINT FK_Matches_start_date_DataKey
GO

ALTER TABLE Fact.Matches
NOCHECK CONSTRAINT FK_Matches_end_date_DataKey
GO
ALTER TABLE Fact.Matches 
ADD  CONSTRAINT FK_Matches_Tourn FOREIGN KEY (tournament_id)
REFERENCES Dimention.Tournament(id)



DROP TABLE IF EXISTS  Dimention.FullStatistic
GO
CREATE TABLE Dimention.FullStatistic (
	  match_id int  
	, home_team_goals int
	, away_team_goals int
	, Referee varchar(25)
	, home_team_shots int
	, away_team_shots int
	, half_time_home_team_goals int
	, half_time_away_team_goals int
	, home_team_shots_on_target int
	, away_team_shots_on_target int
	, home_team_fouls int
	, away_team_fouls int
	, home_team_corners int 
	, away_team_corners int
	, home_team_yellow_cards int
	, away_team_yellow_cards int 
	, home_team_red_cards int
	, away_team_red_cards int
	, modify_date_key bigint
	CONSTRAINT FK_FullStatistic_Matches FOREIGN KEY (match_id)
	REFERENCES Fact.Matches(id),
    CONSTRAINT FK_FullStatistic_DataKey FOREIGN KEY (modify_date_key)
	REFERENCES Dimention.Date(id)
	)
GO
ALTER TABLE Dimention.FullStatistic
NOCHECK CONSTRAINT FK_FullStatistic_DataKey
GO


--facts
DROP TABLE IF EXISTS  Fact.Event
GO
CREATE TABLE Fact.Event (
	  id int 
	, match_id int 
	, home_win_odds decimal(4,2)
    , draw_odds decimal(4,2)
    , away_win_odds decimal(4,2)
	, modify_date_key bigint
	CONSTRAINT PK_Event PRIMARY KEY  (id),
    CONSTRAINT FK_Event_Matches FOREIGN KEY (match_id)
	REFERENCES Fact.Matches(id),
	CONSTRAINT FK_Event_DataKey FOREIGN KEY (modify_date_key)
	REFERENCES Dimention.Date(id)
)
GO
ALTER TABLE Fact.Event
NOCHECK CONSTRAINT FK_Event_DataKey
GO

DROP TABLE IF EXISTS  Fact.BetsHistory
GO
CREATE TABLE Fact.BetsHistory (
	  id int 
	, user_id int NOT NULL
	, event_id int  
	, coefficient decimal(4,2)
	, modify_date_key bigint 
	, modify_time_key int
	, ante decimal(10,2)
	, bet_condition bit NULL
	, choice varchar(1)
	CONSTRAINT PK_BetsHistory PRIMARY KEY  (id),
	CONSTRAINT FK_BetsHistory_Event FOREIGN KEY (event_id)
	REFERENCES Fact.Event(id),
	CONSTRAINT FK_BetsHistory_DataKey FOREIGN KEY (modify_date_key)
	REFERENCES Dimention.Date(id),
	CONSTRAINT FK_BetsHistory_TimeKey FOREIGN KEY (modify_time_key)
	REFERENCES Dimention.Time(id)
)
GO
ALTER TABLE Fact.BetsHistory
ADD CONSTRAINT CHK_Choice_Status CHECK (choice in ('h','d','a'));
GO
ALTER TABLE Fact.BetsHistory
NOCHECK CONSTRAINT FK_BetsHistory_DataKey
GO

ALTER TABLE Fact.BetsHistory
ADD CONSTRAINT FK_UserAccount_BetHistory FOREIGN KEY (user_id)
	REFERENCES Fact.UserAccount(id)
GO



DROP TABLE IF EXISTS Fact.TransactionHistory
GO
CREATE TABLE Fact.TransactionHistory (
	  id int identity(1,1)
	, user_id int
	, card_id int
	, sum decimal(10,2)
	, modify_date_key bigint
	, modify_time_key int 
	, commission decimal(10,2)
	, total decimal(10,2)
	, type varchar(7)    CHECK (type in ('cashout','cashin')) 
	CONSTRAINT PK_TransactionHistory PRIMARY KEY  (id),
    CONSTRAINT FK_TransactionHistory_UserAccount FOREIGN KEY (user_id)
	REFERENCES Fact.UserAccount(id),
	CONSTRAINT FK_TransactionHistory_DataKey FOREIGN KEY (modify_date_key)
	REFERENCES Dimention.Date(id),
	CONSTRAINT FK_TransactionHistory_ModifyTimeKey FOREIGN KEY (modify_time_key)
	REFERENCES Dimention.Time(id)
)
GO
ALTER TABLE Fact.TransactionHistory
NOCHECK CONSTRAINT FK_TransactionHistory_DataKey
GO



DROP VIEW IF EXISTS Dimention.UserCount 
GO
CREATE VIEW Dimention.UserCount 
AS
WITH PayIN(id,sum) AS (
	SELECT ua.id , isnull(sum(sum),0) FROM Fact.TransactionHistory ph
	 RIGHT JOIN  Fact.UserAccount ua ON ua.id = ph.user_id WHERE type = 'cashin'
	GROUP BY ua.id
), PayOut(id ,sum) as (
	SELECT ua.id , isnull(sum(sum),0) FROM Fact.TransactionHistory ph
	 RIGHT JOIN  Fact.UserAccount ua ON ua.id = ph.user_id WHERE type = 'cashout'
	GROUP BY ua.id
), Lose(id ,sum) AS (
	SELECT ua.id, sum(ante) FROM Fact.BetsHistory bh 
	RIGHT JOIN  Fact.UserAccount ua ON ua.id = bh.user_id WHERE bet_condition = 0 
	GROUP BY ua.id
),
Win(id,sum) AS (
	SELECT ua.id, sum(ante*coefficient -(ante*coefficient)*ua.tax) FROM Fact.BetsHistory bh 
	RIGHT JOIN  Fact.UserAccount ua ON ua.id = bh.user_id WHERE bet_condition = 1
	GROUP BY ua.id 
)
SELECT i.id , i.sum total_payin, ISNULL(o.sum,0) total_payout , ISNULL(l.sum,0) total_lose,convert(money,ISNULL(w.sum,0)) total_win,(i.sum - isnull(o.sum,0) - isnull(l.sum,0) + isnull(w.sum,0)) total FROM PayIN i LEFT JOIN PayOut o on o.id = i.id 
	LEFT JOIN Lose l ON l.id = i.id
	LEFT JOIN Win w ON w.id = i.id
GO


DROP VIEW IF EXISTS  Dimention.TeamsInfo 
GO
CREATE VIEW Dimention.TeamsInfo 
AS
WITH CTE AS ( 
SELECT m.home_team_id team, case when  result = 'h' THEN 1 ELSE 0 END as won,
							case when  result = 'd' THEN 1 ELSE 0 END as draw,
							case when  result = 'a' THEN 1 ELSE 0 END as lost,
fs.home_team_goals goals, fs.home_team_goals ga, fs.home_team_shots shots, fs.home_team_shots_on_target shots_on_target, fs.home_team_yellow_cards yellow_cards ,fs.home_team_red_cards red_cards
FROM Fact.Matches m JOIN Dimention.FullStatistic  fs on fs.match_id = m.id   
UNION ALL
SELECT m.away_team_id team, case when  result = 'a' THEN 1 ELSE 0 END as won,
							case when  result = 'd' THEN 1 ELSE 0 END as draw,
							case when  result = 'h' THEN 1 ELSE 0 END as lost,
fs.away_team_goals goals,fs.home_team_goals ga, fs.away_team_shots shots, fs.away_team_shots_on_target shots_on_target, fs.away_team_yellow_cards yellow_cards ,fs.away_team_red_cards red_cards
FROM Fact.Matches m JOIN Dimention.FullStatistic  fs on fs.match_id = m.id   
) 
SELECT t.id,t.tournament_id , ROW_NUMBER( ) OVER (PARTITION BY tournament_id ORDER by tournament_id,(sum(won) * 3+ sum(draw *1)) DESC) position, (sum(won) * 3+ sum(draw *1)) points,
 count(team) matches,sum(won) won, sum(draw) draw, sum(lost) lost, sum(goals) goals_for,sum(ga) goals_against, sum(shots) shots, sum(shots_on_target) shots_on_target, sum(yellow_cards) yellow_cards, sum(red_cards)  red_cards
FROM CTE c FULL JOIN  Dimention.Teams t  on t.id = c.team 
GROUP BY id,tournament_id
GO
