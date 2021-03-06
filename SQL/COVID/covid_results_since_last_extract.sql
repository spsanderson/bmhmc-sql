/*
***********************************************************************
File: covid_results_since_last_extract.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_covid_extract_tbl

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the covid lab results for patients who meet the following criteria
    1. Distinct_Visit_Flag = '1'
	2. In_House = '1'
	3. order_status = 'Result Signed'

Revision History:
Date		Version		Description
----		----		----
2021-01-22	v1			Initial Creation
2021-02-01	v2			Add @right_now between '' and '' to case statement
						Add ORDER BY to final select
						Add group_num != 0 to WHERE clause
2021-03-04	v3			Add Admission Date before unit/room column
*************************************************************************
*/

DECLARE @right_now AS DATETIME2;
DECLARE @seven_pm_yday AS DATETIME2;
DECLARE @seven_am_tday AS DATETIME2;
DECLARE @nine_am_tday AS DATETIME2;
DECLARE @eleven_am_tday AS DATETIME2;
DECLARE @three_pm_tday AS DATETIME2;
DECLARE @seven_pm_tday AS DATETIME2;

SET @right_now = getdate();
SET @seven_pm_yday = DATEADD(HOUR, 19, CONVERT(VARCHAR(10), GETDATE() - 1, 110));
SET @seven_am_tday = DATEADD(HOUR, 7, CONVERT(VARCHAR(10), GETDATE(), 110));
SET @nine_am_tday = DATEADD(HOUR, 9, CONVERT(VARCHAR(10), GETDATE(), 110));
SET @eleven_am_tday = DATEADD(HOUR, 11, CONVERT(VARCHAR(10), GETDATE(), 110));
SET @three_pm_tday = DATEADD(HOUR, 15, CONVERT(VARCHAR(10), GETDATE(), 110));
SET @seven_pm_tday = DATEADD(MINUTE, 1140, DATEDIFF(DAY, 0, GETDATE()));

WITH cte
AS (
	SELECT mrn,
		PTNO_NUM,
		Pt_Name,
		Adm_Dtime,
		Nurs_sta,
		bed,
		result_clean,
		Result_DTime,
		first_positive_flag_dtime,
		CASE 
			WHEN Result_DTime >= @seven_pm_yday
				AND Result_DTime < @seven_am_tday
				AND @right_now BETWEEN @seven_am_tday AND @nine_am_tday
				THEN 1
			WHEN Result_DTime >= @seven_am_tday
				AND Result_DTime < @nine_am_tday
				AND @right_now BETWEEN @nine_am_tday AND @eleven_am_tday
				THEN 2
			WHEN Result_DTime >= @nine_am_tday
				AND Result_DTime < @eleven_am_tday
				AND @right_now BETWEEN @eleven_am_tday AND @three_pm_tday
				THEN 3
			WHEN Result_DTime >= @eleven_am_tday
				AND Result_DTime < @three_pm_tday
				AND @right_now BETWEEN @three_pm_tday AND @seven_pm_tday
				THEN 4
			WHEN Result_DTime >= @three_pm_tday
				AND Result_DTime < @seven_pm_tday
				AND @right_now >= @seven_pm_tday
				THEN 5
			ELSE 0
			END AS [group_number]
	FROM smsdss.c_covid_extract_tbl
	WHERE Distinct_Visit_Flag = '1'
		AND In_House = '1'
		AND order_status = 'Result Signed'
	)
SELECT *
FROM cte
WHERE group_number = (
		SELECT max(group_number)
		FROM cte
		WHERE group_number != 0
		)
ORDER BY Pt_Name
