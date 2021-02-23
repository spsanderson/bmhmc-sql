/*
***********************************************************************
File: c_covid_exception_report_query.sql

Input Parameters:
	DECLARE @TODAY DATE;
    DECLARE @YESTERDAY DATE;
    DECLARE @TODAY_AT_NINE DATETIME;
    DECLARE @YESTERDAY_AT_NINE DATETIME;

    SET @TODAY = GETDATE();
    SET @YESTERDAY = GETDATE() - 1;
    SET @TODAY_AT_NINE = DATEADD(HOUR, 9, CONVERT(VARCHAR(10), GETDATE(), 110));
    SET @YESTERDAY_AT_NINE = DATEADD(HOUR, 9, CONVERT(VARCHAR(10), GETDATE() - 1, 110));

Tables/Views:
	smsdss.c_covid_hhs_positive_admitted_tbl

Creates Table:
	None

Functions:
	Enter Here

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	The covid hhs admitted exception report

Revision History:
Date		Version		Description
----		----		----
2021-01-29	v1			Initial Creation
***********************************************************************
*/
DECLARE @TODAY DATE;
DECLARE @YESTERDAY DATE;
DECLARE @TODAY_AT_NINE DATETIME;
DECLARE @YESTERDAY_AT_NINE DATETIME;

SET @TODAY = GETDATE();
SET @YESTERDAY = GETDATE() - 1;
SET @TODAY_AT_NINE = DATEADD(HOUR, 9, CONVERT(VARCHAR(10), GETDATE(), 110));
SET @YESTERDAY_AT_NINE = DATEADD(HOUR, 9, CONVERT(VARCHAR(10), GETDATE() - 1, 110));

WITH CTE AS (
	SELECT PTNO_NUM
	FROM smsdss.c_covid_hhs_positive_admitted_tbl
	WHERE CAST(SP_Run_DateTime AS DATE) = @YESTERDAY

	EXCEPT

	SELECT PTNO_NUM
	FROM SMSDSS.c_covid_hhs_positive_admitted_tbl
	WHERE CAST(SP_RUN_DATETIME AS DATE) = @TODAY
)

SELECT B.*,
[QUERY_RUN_DATETIME] = GETDATE()
FROM CTE AS A
LEFT OUTER JOIN SMSDSS.c_covid_extract_tbl AS B
ON A.PTNO_NUM = B.PTNO_NUM
WHERE B.Distinct_Visit_Flag = '1'
AND DC_DTIME NOT BETWEEN @YESTERDAY_AT_NINE AND @TODAY_AT_NINE