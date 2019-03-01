USE _ProjectDWH3
GO

--Dim Datem, Time genering
DECLARE   @startdate datetime = '2019-02-17 15:47:20.787'
		, @enddate datetime = '2019-04-16 15:47:20.787'
;WITH   cte(date)
AS     (SELECT @startdate AS date -- anchor member
        UNION ALL
        SELECT dateadd(day,1,date) -- recursive member
        FROM   cte
        WHERE  date < @enddate -- terminator
       )
INSERT INTO  Dimention.Date
SELECT   dbo.DatetoDateKey(s.date)						as date_key 
	   , convert(varchar, date, 110)												as DateValue
	   , DATEPART(d, s.date)								as DayNumber
	   , DATEPART(m, s.date)								as MonthDayNumber
	   , DATEPART(yy, s.date)								as YearNumber
	   , DATEPART(dw, s.date)								as WeekDayNumber
	   , CASE DATEPART(m,s.date)	
			WHEN 1  THEN 'Cічень'  
			WHEN 2  THEN 'Лютий'  
			WHEN 3  THEN 'Березень'  
			WHEN 4  THEN 'Квітень'          
			WHEN 5  THEN 'Травень' 
			WHEN 6  THEN 'Червень' 
			WHEN 7  THEN 'Липень'
			WHEN 8  THEN 'Серпень' 
			WHEN 9  THEN 'Вересень' 
			WHEN 10 THEN 'Жовтень'
			WHEN 11 THEN 'Листопад'
			WHEN 12 THEN 'Грудень'
			END												as [UaMonthName]
	   , CASE DATEPART(m,s.date)	
			WHEN 1  THEN 'Styczeń'  
			WHEN 2  THEN 'Luty'  
			WHEN 3  THEN 'Marzec'  
			WHEN 4  THEN 'Kwiecień'          
			WHEN 5  THEN 'Maj' 
			WHEN 6  THEN 'Czerwiec' 
			WHEN 7  THEN 'Lipiec'
			WHEN 8  THEN 'Sierpień' 
			WHEN 9  THEN 'Wrzesień' 
			WHEN 10 THEN 'Październik'
			WHEN 11 THEN 'Listopad'
			WHEN 12 THEN 'Grudzień'
			END												as [PlMonthName]
	   , CASE DATEPART(m,s.date)	
			WHEN 1  THEN 'Janvier'  
			WHEN 2  THEN 'Février'  
			WHEN 3  THEN 'Mars'  
			WHEN 4  THEN 'Avril'          
			WHEN 5  THEN 'Mai' 
			WHEN 6  THEN 'Juin' 
			WHEN 7  THEN 'Juillet'
			WHEN 8  THEN 'Août' 
			WHEN 9  THEN 'Septembre' 
			WHEN 10 THEN 'Octobre'
			WHEN 11 THEN 'Novembre'
			WHEN 12 THEN 'Novembre'
			END												as [FrMonthName] 
	  , CAST(DATENAME(m, s.date) AS VARCHAR(10))			as [UsMonthName]
	  , CASE DATEPART(dw,s.date)	
			WHEN 1 THEN 'Неділя'  
			WHEN 2 THEN 'Понеділок'  
			WHEN 3 THEN 'Вівторок'  
			WHEN 4 THEN 'Cереда'          
			WHEN 5 THEN 'Четвер' 
			WHEN 6 THEN 'П''ятниця' 
			WHEN 7 THEN 'Субота'
			END												as UaDayName
	  , CASE DATEPART(dw,s.date)	
			WHEN 1 THEN 'Niedziela'  
			WHEN 2 THEN 'Poniedziałek'  
			WHEN 3 THEN 'Wtorek'  
			WHEN 4 THEN 'Środa'          
			WHEN 5 THEN 'Czwartek' 
			WHEN 6 THEN 'Piątek	' 
			WHEN 7 THEN 'Sobota'
			END												as PlDayName
	  , CASE DATEPART(dw,s.date)	
			WHEN 1 THEN 'Dimanche'  
			WHEN 2 THEN 'Lundi'  
			WHEN 3 THEN 'Mercredi'  
			WHEN 4 THEN 'Jeudi'          
			WHEN 5 THEN 'Vendredi' 
			WHEN 6 THEN 'Samedi' 
			WHEN 7 THEN 'Dimanche'
			END												as FrDayName
	  , CAST(DATENAME(dw, s.date) AS VARCHAR(10))			as UsDayName
	  , CAST(CONVERT(VARCHAR(7),s.date,20) AS VARCHAR(8))	as YearMonth
FROM CTE s OPTION (MAXRECURSION 0)
 
