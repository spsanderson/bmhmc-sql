USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_Readmit_Dashboard_Detail_sp.sql

Input Parameters: None

Tables/Views:
	smsdss.BMH_PLM_PtAcct_V
    smsdss.pract_dim_v
    Customer.Custom_DRG
	smsdss.c_LIHN_Svc_Line_Tbl
	smsdss.vReadmits

Creates Table: 
	smsdss.c_Readmit_Dashboard_Detail_Tbl

Functions: None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

This sp creates a table to get all relevant discharges to be used 
for 30 day inpatient readmission statistics.

Revision History:
Date		Version		Description
----		----		----
2018-07-13	v1			Initial Creation
2018-07-18	v2			Add Discharge Month to table
2018-07-19	v3			Add payor category
						Fix to lag by one month
2018-08-13  v4			Fix ELSE BEGIN start and end dates
***********************************************************************
*/

ALTER PROCEDURE [smsdss].[c_Readmit_Dashboard_Detail_sp]
AS

IF NOT EXISTS(
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name = 'c_Readmit_Dashboard_Detail_Tbl' AND xtype = 'U'
)

BEGIN

	DECLARE @START DATE;
	DECLARE @END   DATE;
	DECLARE @TODAY DATETIME;

	SET @TODAY = GETDATE();
	SET @START = DATEADD(M, DATEDIFF(M, 0, @TODAY) - 19,0);
	SET @END   = DATEADD(M, DATEDIFF(M, 0, @TODAY) - 1, 0);

	CREATE TABLE smsdss.c_Readmit_Dashboard_Detail_Tbl (
		Atn_Dr_No CHAR(6)
		, pract_rpt_name VARCHAR(100)
		, med_staff_dept VARCHAR(100)
		, spclty_desc VARCHAR(100)
		, Hospitalist_Private VARCHAR(50)
		, Hospitaslit_Private_Flag TINYINT
		, Med_Rec_No VARCHAR(10)
		, PtNo_Num VARCHAR(8)
		, Payor_Category VARCHAR(100)
		, Adm_Date DATE
		, Dsch_Date DATE
		, Dsch_YR SMALLINT
		, Dsch_Qtr TINYINT
		, Dsch_Month TINYINT
		, Rpt_Month INT
		, Rpt_Qtr INT
		, Dsch_Week INT
		, Dsch_Day INT
		, Dsch_Day_Name VARCHAR(15)
		, LOS INT
		, drg_no VARCHAR(3)
		, drg_cost_weight FLOAT(4)
		, APRDRGNO VARCHAR(3)
		, SEVERITY_OF_ILLNESS CHAR(1)
		, LIHN_Svc_Line VARCHAR(100)
		, DSCH_DISP VARCHAR(5)
		, Dsch_Disp_Desc VARCHAR(150)
		, RA_Flag TINYINT
		, READMIT VARCHAR(8)
		, INTERIM TINYINT
	)

	INSERT INTO smsdss.c_Readmit_Dashboard_Detail_Tbl

	SELECT Atn_Dr_No
	, B.pract_rpt_name
	, B.med_staff_dept
	, B.spclty_desc
	, [Hospitalist_Private] = CASE WHEN B.src_spclty_cd = 'HOSIM' THEN 'Hospitalist' ELSE 'Private' END 
	, [Hospitaslit_Private_Flag] = CASE WHEN B.src_spclty_cd = 'HOSIM' THEN 1 ELSE 0 END 
	, A.Med_Rec_No
	, A.PtNo_Num
	, F.pyr_group2 AS [Payor_Category]
	, CAST(A.ADM_DATE AS date) AS [Adm_Date]
	, CAST(A.DSCH_DATE AS date) AS [Dsch_Date]
	, DATEPART(YEAR, A.DSCH_DATE) AS [Dsch_YR]
	, DATEPART(QUARTER, A.Dsch_Date) AS [Dsch_Qtr]
	, DATEPART(MONTH, A.DSCH_DATE) AS [Dsch_Month]
	, [Rpt_Month] = CASE
		WHEN DATEPART(MONTH, A.DSCH_DATE) < 10
			THEN CAST(DATEPART(YEAR, A.DSCH_DATE) AS VARCHAR) + '0' + CAST(DATEPART(MONTH, A.Dsch_Date) AS varchar)
			ELSE CAST(DATEPART(YEAR, A.DSCH_DATE) AS varchar) + CAST(DATEPART(MONTH, A.Dsch_Date) AS varchar)
		END
	, [Rpt_Qtr] = CAST(DATEPART(YEAR, A.DSCH_DATE) AS varchar) + CAST(DATEPART(QUARTER, A.DSCH_date) AS varchar)
	, DATEPART(WEEK, A.DSCH_DATE) AS [Dsch_Week]
	, DATEPART(WEEKDAY, A.DSCH_DATE) AS [Dsch_Day]
	, DATENAME(WEEKDAY, A.DSCH_DATE) AS [Dsch_Day_Name]
	, CAST(A.Days_Stay AS int) AS [LOS]
	, drg_no
	, drg_cost_weight
	, C.APRDRGNO
	, C.SEVERITY_OF_ILLNESS
	, D.LIHN_Svc_Line
	, RTRIM(LTRIM(A.dsch_disp)) AS [DSCH_DISP]
	, CASE
		WHEN RIGHT(RTRIM(LTRIM(a.dsch_disp)), 2) = 'HR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
		WHEN RIGHT(RTRIM(LTRIM(a.dsch_disp)), 2) = 'TW' THEN 'Home, Adult Home, Assisted Living with Homecare'
	  END AS [Dsch_Disp_Desc]
	, CASE
		WHEN E.[READMIT] IS NOT NULL
			THEN 1
			ELSE 0
	  END AS [RA_Flag]
	, E.READMIT
	, E.INTERIM

	FROM smsdss.BMH_PLM_PtAcct_V AS A
	LEFT OUTER JOIN smsdss.pract_dim_v AS B
	ON A.Atn_Dr_No = B.src_pract_no
		AND A.Regn_Hosp = B.orgz_cd
	LEFT OUTER JOIN Customer.Custom_DRG AS C
	ON A.PtNo_Num = C.PATIENT#
	LEFT OUTER JOIN smsdss.c_LIHN_Svc_Line_Tbl AS D
	ON A.PtNo_Num = D.Encounter
		AND A.prin_dx_cd_schm = D.prin_dx_cd_schme
	LEFT OUTER JOIN smsdss.vReadmits AS E
	ON A.PtNo_Num = E.[INDEX]
		AND E.[INTERIM] < 31
		AND E.[READMIT SOURCE DESC] != 'Scheduled Admission'
	LEFT OUTER JOIN smsdss.pyr_dim_v AS F
	ON A.Pyr1_Co_Plan_Cd = F.pyr_cd
		AND A.Regn_Hosp = F.orgz_cd

	WHERE A.DSCH_DATE >= @START
	AND A.Dsch_Date < @END
	AND A.tot_chg_amt > 0
	AND A.drg_no IS NOT NULL
	AND A.dsch_disp IN ('AHR','ATW')
	AND C.APRDRGNO NOT IN (	
		SELECT ZZZ.[APR-DRG]
		FROM smsdss.c_ppr_apr_drg_global_exclusions AS ZZZ
	)

END

ELSE BEGIN

	DECLARE @STARTB DATE;
	DECLARE @ENDB   DATE;
	DECLARE @TODAYB DATETIME;

	SET @TODAYB = GETDATE();
	SET @STARTB = DATEADD(M, DATEDIFF(M, 0, @TODAYB) - 19,0);
	SET @ENDB   = DATEADD(M, DATEDIFF(M, 0, @TODAYB) - 1, 0);

	TRUNCATE TABLE SMSDSS.C_READMIT_DASHBOARD_DETAIL_TBL

	INSERT INTO smsdss.c_Readmit_Dashboard_Detail_Tbl

	SELECT Atn_Dr_No
	, B.pract_rpt_name
	, B.med_staff_dept
	, B.spclty_desc
	, [Hospitalist_Private] = CASE WHEN B.src_spclty_cd = 'HOSIM' THEN 'Hospitalist' ELSE 'Private' END 
	, [Hospitaslit_Private_Flag] = CASE WHEN B.src_spclty_cd = 'HOSIM' THEN 1 ELSE 0 END 
	, A.Med_Rec_No
	, A.PtNo_Num
	, F.pyr_group2 AS [Payor_Category]
	, CAST(A.ADM_DATE AS date) AS [Adm_Date]
	, CAST(A.DSCH_DATE AS date) AS [Dsch_Date]
	, DATEPART(YEAR, A.DSCH_DATE) AS [Dsch_YR]
	, DATEPART(QUARTER, A.Dsch_Date) AS [Dsch_Qtr]
	, DATEPART(MONTH, A.DSCH_DATE) AS [Dsch_Month]
	, [Rpt_Month] = CASE
		WHEN DATEPART(MONTH, A.DSCH_DATE) < 10
			THEN CAST(DATEPART(YEAR, A.DSCH_DATE) AS VARCHAR) + '0' + CAST(DATEPART(MONTH, A.Dsch_Date) AS varchar)
			ELSE CAST(DATEPART(YEAR, A.DSCH_DATE) AS varchar) + CAST(DATEPART(MONTH, A.Dsch_Date) AS varchar)
		END
	, [Rpt_Qtr] = CAST(DATEPART(YEAR, A.DSCH_DATE) AS varchar) + CAST(DATEPART(QUARTER, A.DSCH_date) AS varchar)
	, DATEPART(WEEK, A.DSCH_DATE) AS [Dsch_Week]
	, DATEPART(WEEKDAY, A.DSCH_DATE) AS [Dsch_Day]
	, DATENAME(WEEKDAY, A.DSCH_DATE) AS [Dsch_Day_Name]
	, CAST(A.Days_Stay AS int) AS [LOS]
	, drg_no
	, drg_cost_weight
	, C.APRDRGNO
	, C.SEVERITY_OF_ILLNESS
	, D.LIHN_Svc_Line
	, RTRIM(LTRIM(A.dsch_disp)) AS [DSCH_DISP]
	, CASE
		WHEN RIGHT(RTRIM(LTRIM(a.dsch_disp)), 2) = 'HR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
		WHEN RIGHT(RTRIM(LTRIM(a.dsch_disp)), 2) = 'TW' THEN 'Home, Adult Home, Assisted Living with Homecare'
	  END AS [Dsch_Disp_Desc]
	, CASE
		WHEN E.[READMIT] IS NOT NULL
			THEN 1
			ELSE 0
	  END AS [RA_Flag]
	, E.READMIT
	, E.INTERIM

	FROM smsdss.BMH_PLM_PtAcct_V AS A
	LEFT OUTER JOIN smsdss.pract_dim_v AS B
	ON A.Atn_Dr_No = B.src_pract_no
		AND A.Regn_Hosp = B.orgz_cd
	LEFT OUTER JOIN Customer.Custom_DRG AS C
	ON A.PtNo_Num = C.PATIENT#
	LEFT OUTER JOIN smsdss.c_LIHN_Svc_Line_Tbl AS D
	ON A.PtNo_Num = D.Encounter
		AND A.prin_dx_cd_schm = D.prin_dx_cd_schme
	LEFT OUTER JOIN smsdss.vReadmits AS E
	ON A.PtNo_Num = E.[INDEX]
		AND E.[INTERIM] < 31
		AND E.[READMIT SOURCE DESC] != 'Scheduled Admission'
	LEFT OUTER JOIN smsdss.pyr_dim_v AS F
	ON A.Pyr1_Co_Plan_Cd = F.pyr_cd
		AND A.Regn_Hosp = F.orgz_cd

	WHERE A.DSCH_DATE >= @STARTB
	AND A.Dsch_Date < @ENDB
	AND A.tot_chg_amt > 0
	AND A.drg_no IS NOT NULL
	AND A.dsch_disp IN ('AHR','ATW')
	AND C.APRDRGNO NOT IN (	
		SELECT ZZZ.[APR-DRG]
		FROM smsdss.c_ppr_apr_drg_global_exclusions AS ZZZ
	)

END
;