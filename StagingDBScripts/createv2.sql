--DROP DATABASE _Project
CREATE DATABASE _Project
go

USE _Project
go


EXEC sp_configure 'xp_cmdshell', 1;  
GO  
RECONFIGURE;
GO


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


DROP SCHEMA IF EXISTS Sport;
GO
CREATE SCHEMA Sport;
GO

DROP TABLE IF EXISTS Sport.Tournament
GO
CREATE TABLE Sport.Tournament(
	  id int PRIMARY KEY
	, tournament_name varchar(30)
	, country varchar(25)
	, modify_date datetime
	)
GO

DROP TABLE IF EXISTS Sport.Teams
GO
CREATE TABLE Sport.Teams (
	   id int PRIMARY KEY identity(1,1)
	 , team_name varchar(25)
	 , tournament_id int FOREIGN KEY REFERENCES Sport.Tournament(id)
	 , modify_date datetime
	 )
GO

DROP TABLE IF EXISTS Sport.Matches
GO
CREATE TABLE Sport.Matches(
	  id int PRIMARY KEY
	, modify_date datetime
	, home_team_id int FOREIGN KEY REFERENCES Sport.Teams(id)
	, away_team_id int FOREIGN KEY REFERENCES Sport.Teams(id)
	, start_date datetime
	, end_date datetime 
	, tournament_id int FOREIGN KEY REFERENCES Sport.Tournament(id)
	, status varchar(10)
	, result varchar(1)
	)
GO 
ALTER TABLE Sport.Matches
ADD CONSTRAINT CHK_Matches CHECK (status in ('In process','Upcoming','Finished') AND result in ('h','d','a'));
GO

DROP TABLE IF EXISTS  Sport.FullStatistic
GO
CREATE TABLE Sport.FullStatistic(
	  match_id int  FOREIGN KEY REFERENCES Sport.Matches(id)
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
	, modify_date datetime
	)
GO


DROP TABLE IF EXISTS Sport.Event
GO
CREATE TABLE Sport.Event (
	   id int PRIMARY KEY identity(1,1)
	 , match_id int  FOREIGN KEY REFERENCES Sport.Matches(id)
	 , deadline datetime
 	 , home_win_odds decimal(4,2)
 	 , draw_odds decimal(4,2)
 	 , away_win_odds decimal(4,2)
	 , modify_date datetime
	 )
GO

-- Finances
DROP SCHEMA IF EXISTS Finances;
GO
CREATE SCHEMA Finances;
GO

DROP TABLE IF EXISTS Finances.Regions
GO
CREATE TABLE Finances.Regions (
	  region_code varchar(2) PRIMARY KEY 
	, name varchar(10)
	, currency decimal(4,2)
	, currency_name varchar(3)
	, commision decimal(4,2)
	, time_zone smallint
	, modify_date datetime
)
GO

INSERT INTO Finances.Regions VALUES ('ua', 'Ukraine',27.7409, 'UAH',  0.01, 2, getdate()),
									('us', 'USA',1, 'USD',  0.02, 6, getdate()),
									('pl', 'Poland', 3.71979, 'PLN', 0.015, 1, getdate()),
									('fr', 'France',0.8728, 'EUR',  0.015, 1, getdate())
GO




DROP TABLE IF EXISTS Finances.UserAccount
GO
CREATE TABLE Finances.UserAccount (
	  id int PRIMARY KEY identity(1,1)
 	, first_name varchar(25)
	, second_name varchar(25)
	, region varchar(2)	FOREIGN KEY REFERENCES Finances.Regions(region_code)
	, tax decimal(10,2) 
	, modify_date datetime
	)
GO

DROP TABLE IF EXISTS Finances.UserInformation
GO
CREATE TABLE Finances.UserInformation (
	  user_id int identity(1,1)  FOREIGN KEY REFERENCES Finances.UserAccount(id)
	, email varchar(50)
	, password varchar(25)
	, phone_number varchar(25)
	, date_creating datetime
	, date_changing datetime
 	)
GO




DROP TABLE IF EXISTS Finances.CreditCard
GO
CREATE TABLE Finances.CreditCard (
	  id int PRIMARY KEY identity(1,1)
	, user_id int FOREIGN KEY REFERENCES Finances.UserAccount(id)
	, card_type varchar(25)
	, exp_month tinyint
	, exp_year smallint
	, card_number varchar(25)
	, modify_date datetime
	)
GO

DROP TABLE IF EXISTS Finances.BetsHistory
GO
CREATE TABLE Finances.BetsHistory (
	  id int PRIMARY KEY IDENTITY(1,1)
	, user_id int FOREIGN KEY REFERENCES Finances.UserAccount(id)
	, event_id int FOREIGN KEY REFERENCES Sport.Event(id)
	, coefficient decimal(4,2)
	, date datetime NOT NULL 
	, ante decimal(10,2)
	, status nvarchar(10)
	, bet_condition bit NULL
	, choice varchar(1)
	)
GO
ALTER TABLE Finances.BetsHistory
ADD CONSTRAINT CHK_Choice_Status CHECK (choice in ('h','d','a') AND status in ('In process','Deleted','Finished'));
GO

DROP TABLE IF EXISTS Finances.PayoutHistory
GO
CREATE TABLE Finances.PayoutHistory (
	  id int PRIMARY KEY identity(1,1)
	, user_id int FOREIGN KEY REFERENCES Finances.UserAccount(id)
	, card_id int FOREIGN KEY REFERENCES Finances.CreditCard(id)
	, sum decimal(10,2)
	, date datetime
	, commission decimal(10,2)
	, total_sum decimal(10,2)
	, status bit
	)
GO

DROP TABLE IF EXISTS Finances.PayinHistory
GO
CREATE TABLE Finances.PayinHistory (
	  id int PRIMARY KEY identity(1,1)
	, user_id int FOREIGN KEY REFERENCES Finances.UserAccount(id)
	, card_id int FOREIGN KEY REFERENCES Finances.CreditCard(id)
	, sum decimal(10,2)
	, date datetime
	, status bit
	)
GO




DROP VIEW IF EXISTS Sport.TeamsInfo 
GO
CREATE VIEW Sport.TeamsInfo 
WITH SCHEMABINDING 
AS
WITH CTE AS ( 
SELECT m.home_team_id team, case when  result = 'h' THEN 1 ELSE 0 END as won,
							case when  result = 'd' THEN 1 ELSE 0 END as draw,
							case when  result = 'a' THEN 1 ELSE 0 END as lost,
fs.home_team_goals goals, fs.home_team_goals ga, fs.home_team_shots shots, fs.home_team_shots_on_target shots_on_target, fs.home_team_yellow_cards yellow_cards ,fs.home_team_red_cards red_cards
FROM Sport.Matches m JOIN Sport.FullStatistic  fs on fs.match_id = m.id   
UNION 
SELECT m.away_team_id team, case when  result = 'a' THEN 1 ELSE 0 END as won,
							case when  result = 'd' THEN 1 ELSE 0 END as draw,
							case when  result = 'h' THEN 1 ELSE 0 END as lost,
fs.away_team_goals goals,fs.home_team_goals ga, fs.away_team_shots shots, fs.away_team_shots_on_target shots_on_target, fs.away_team_yellow_cards yellow_cards ,fs.away_team_red_cards red_cards
FROM Sport.Matches m JOIN Sport.FullStatistic  fs on fs.match_id = m.id   
) 
SELECT t.id,t.tournament_id , ROW_NUMBER( ) OVER (PARTITION BY tournament_id ORDER by tournament_id,(sum(won) * 3+ sum(draw *1)) DESC) position, (sum(won) * 3+ sum(draw *1)) points,
 count(team) matches,sum(won) won, sum(draw) draw, sum(lost) lost, sum(goals) goals_for,sum(ga) goals_against, sum(shots) shots, sum(shots_on_target) shots_on_target, sum(yellow_cards) yellow_cards, sum(red_cards)  red_cards
FROM CTE c FULL JOIN  Sport.Teams t  on t.id = c.team
GROUP BY id,tournament_id
GO

DROP VIEW IF EXISTS Finances.UserTotal
GO
CREATE VIEW Finances.UserTotal (user_id , total) 
AS
WITH CTE( user_id , sum ) AS (
SELECT bh.user_id , bh.ante * bh.coefficient - (bh.ante * bh.coefficient *ua.tax) as  sum FROM  Finances.BetsHistory bh  JOIN Finances.UserAccount ua
on bh.user_id = ua.id
WHERE bet_condition = 1  
UNION ALL
SELECT user_id ,sum FROM Finances.PayinHistory WHERE status = 1
UNION ALL
SELECT user_id ,-total_sum FROM Finances.PayoutHistory
UNION ALL
SELECT user_id , -(ante) FROM Finances.BetsHistory 
WHERE bet_condition = 0  and status NOT LIKE 'deleted' 
)
SELECT user_id, convert(money,(ROUND(sum(sum),2))) FROM CTE GROUP BY user_id
GO



CREATE TABLE ##EventData (
    [id] int,
    [home_team_id] int,
    [away_team_id] int,
    [tournament_id] int,
    [start_date] datetime,
    [deadline] datetime,
    [home_win_odds] decimal(4,2),
    [draw_odds] decimal(4,2),
    [away_win_odds] decimal(4,2)
)
