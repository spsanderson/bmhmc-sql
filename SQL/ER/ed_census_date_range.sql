/*
***********************************************************************
File: ed_census_date_range.sql

Input Parameters:
	none

Tables/Views:
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]

Creates Table:
	none

Functions:
	none

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get ED Census by hour for a date range

Revision History:
Date		Version		Description
----		----		----
2020-06-03	v1			Initial Creation
2020-06-05	v2			Drop # tables and use @ tables
						Make dates dynamic
***********************************************************************
*/


/*
For a date range, must always set @StartDate to at lest 3 days before datetime of interest
*/
DECLARE @TODAY AS DATE;
DECLARE @StartDate AS DATETIME2;
DECLARE @EndDate AS DATETIME2;
DECLARE @DateOfInterest AS DATETIME2;

SET @TODAY = GETDATE();
SET @DateOfInterest = DATEADD(mm, DATEDIFF(mm, 0, @TODAY) - 2, 0);
SET @StartDate = DATEADD(DAY, - 3, @DateOfInterest);
SET @EndDate = @TODAY;

DECLARE @TEMPA TABLE (
	Arrival DATETIME2,
	Departure DATETIME2
)

DECLARE @FINAL_TBL TABLE (
	Date DATETIME2,
	ED_Census INT
)

INSERT INTO @TEMPA
SELECT Arrival,
	CASE 
		WHEN Access_Rm_Assigned IS NOT NULL
			THEN Access_Rm_Assigned
		WHEN TimeLeftED = '-- ::00'
			THEN NULL
		ELSE TimeLeftED
		END AS [Departure]
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
WHERE ARRIVAL >= @StartDate
	AND ARRIVAL < @EndDate;


WITH dates AS (
	SELECT CAST(@StartDate AS DATETIME2) AS dte
	
	UNION ALL
	
	SELECT DATEADD(HOUR, 1, dte)
	FROM dates
	WHERE dte < @EndDate
	)

INSERT INTO @FINAL_TBL
SELECT dates.dte [Date],
	SUM(CASE 
			WHEN Arrival <= dte
				AND Departure >= dte
				THEN 1
			ELSE 0
			END) ED_Census
FROM dates
LEFT JOIN @TEMPA AS A ON A.Arrival <= DATEADD(HOUR, 1, dates.dte)
	AND A.Departure >= dates.dte
WHERE dates.dte < @EndDate
GROUP BY dates.dte
ORDER BY dates.dte
OPTION (MAXRECURSION 0);

SELECT *
FROM @FINAL_TBL AS FT
WHERE FT.[Date] >= @DateOfInterest;