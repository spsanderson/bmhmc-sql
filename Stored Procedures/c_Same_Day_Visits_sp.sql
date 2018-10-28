USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
*****************************************************************************  
File: c_Same_Day_Visits_sp.sql      

Input  Parameters:
	None 

Tables/Views:   
	smsdss.BMH_PLM_PtAcct_V
  
Functions:   
	None

Author: Steve P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose:
	Get the MRN and Visit number of those patients with more than one visit
	in a given Admit DATE
      
Revision History: 
Date		Version		Description
----		----		----
2018-10-10	v1			Initial Creation
-------------------------------------------------------------------------------- 
*/

CREATE PROCEDURE [smsdss].[c_Same_Day_Visits_sp]
AS

IF NOT EXISTS(
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name = 'c_Same_Day_Visits_Tbl' AND xtype = 'U'
)

BEGIN

	CREATE TABLE smsdss.c_Same_Day_Visits_Tbl (
		Med_Rec_No    VARCHAR(8)
		, PtNo_Num    VARCHAR(12)
		, Adm_Date    DATE
		, Dsch_Date   DATE
		, hosp_svc    VARCHAR(4)
		, RunDate     DATE
		, RunDateTime DATETIME
		, Visit_Count SMALLINT
	)
	;

	SELECT Adm_Date
	, MED_REC_NO
	, COUNT(DISTINCT(PTNO_NUM)) AS [VISIT_COUNT]

	INTO #TEMPA

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Adm_Date >= '2010-01-01'
	AND LEFT(PTNO_NUM, 1) NOT IN ('2','5','7')

	GROUP BY Adm_Date, Med_Rec_No
	;

	INSERT INTO smsdss.c_Same_Day_Visits_Tbl

	SELECT A.Med_Rec_No
	, A.PtNo_Num
	, A.Adm_Date
	, A.Dsch_Date
	, A.hosp_svc
	, [RunDate] = CAST(getdate() as date)
	, [RunDateTime] = GETDATE()
	, B.VISIT_COUNT

	FROM smsdss.BMH_PLM_PtAcct_V AS A
	INNER JOIN #TEMPA AS B
	ON A.Med_Rec_No = B.MED_REC_NO
		AND A.Adm_Date = B.Adm_Date

	WHERE B.VISIT_COUNT > 1

	ORDER BY A.Med_Rec_No
	, A.PtNo_Num
	;

	DROP TABLE #TEMPA
	;

END

ELSE BEGIN

	SELECT Adm_Date
	, MED_REC_NO
	, COUNT(DISTINCT(PTNO_NUM)) AS [VISIT_COUNT]

	INTO #TEMPB

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Adm_Date >= DATEADD(DAY, DATEDIFF(DAY, 0, CAST(GETDATE() AS date)) - 1, 0)
	AND LEFT(PTNO_NUM, 1) NOT IN ('2','5','7')

	GROUP BY Adm_Date, Med_Rec_No
	;

	INSERT INTO smsdss.c_Same_Day_Visits_Tbl

	SELECT A.Med_Rec_No
	, A.PtNo_Num
	, A.Adm_Date
	, A.Dsch_Date
	, A.hosp_svc
	, [RunDate] = CAST(getdate() as date)
	, [RunDateTime] = GETDATE()
	, B.VISIT_COUNT

	FROM smsdss.BMH_PLM_PtAcct_V AS A
	INNER JOIN #TEMPB AS B
	ON A.Med_Rec_No = B.MED_REC_NO
		AND A.Adm_Date = B.Adm_Date

	WHERE B.VISIT_COUNT > 1
	AND A.PtNo_Num NOT IN (
		SELECT ZZZ.PTNO_NUM
		FROM smsdss.c_Same_Day_Visits_Tbl AS ZZZ
	)

	ORDER BY A.Med_Rec_No
	, A.PtNo_Num
	;

	DROP TABLE #TEMPB
	;

END
;