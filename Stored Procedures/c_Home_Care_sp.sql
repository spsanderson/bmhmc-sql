USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_Home_Care_sp]    Script Date: 8/22/2018 9:21:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [smsdss].[c_Home_Care_sp]
AS

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

/*
***********************************************************************
File: c_Home_Care_sp.sql

Input Parameters: None

Tables/Views:
	smsdss.BMH_UserTwoField_Fact
	smsdss.BMH_PLM_PtAcct_V

Creates Table: 
	smsdss.c_Home_Care_Rpt_Tbl

Functions: None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Creates a table for homecare Start of Care, Not taken under care where 
the patient was an inpatient previously.

Revision History:
Date		Version		Description
----		----		----
2016-01-01	v1			Initial Creation
2018-08-22	v2			Complete re-write
***********************************************************************
*/

IF NOT EXISTS(
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name='c_Home_Care_Rpt_Tbl' AND xtype='U'
)

BEGIN

	SELECT PtNo_Num
	, UserDataKey
	, UserDataText as hc_mr_epi
	, SeqNo
	, LastDataCngDTime as Entered_Into_Invision
	, LoadDate

	INTO #A

	FROM [smsdss].[BMH_UserTwoField_Fact]

	WHERE UserDataKey IN (644) -- 2HCMREPI

	ORDER BY LastDataCngDTime
	;

	SELECT PtNo_Num
	, UserDataKey
	, CAST(
		LEFT(UserDataText, 2) + '-' + RIGHT(LEFT(UserDataText, 4), 2) +
		'-' + RIGHT(UserDataText, 2)
		AS DATE
		) 	  AS [HC_SOC_DATE]
	, SeqNo
	, LastDataCngDTime
	, LoadDate

	INTO #B

	FROM [smsdss].[BMH_UserTwoField_Fact]

	WHERE UserDataKey IN (647) -- 2SOCDATE
	;

	SELECT PtNo_Num
	, UserDataKey
	, CAST(
		LEFT(UserDataText, 2) + '-' + RIGHT(LEFT(UserDataText, 4), 2) +
		'-' + RIGHT(UserDataText, 2)
		AS DATE
		) 	  AS [HC_NTUC_DATE]
	, SeqNo
	, LastDataCngDTime
	, LoadDate

	INTO #C

	FROM [smsdss].[BMH_UserTwoField_Fact]

	WHERE UserDataKey IN (645) -- 2NTUCDTE
	;

	SELECT PtNo_Num
	, UserDataKey
	, UserDataText as [HC_NTUC_RSN]
	, SeqNo
	, LastDataCngDTime
	, LoadDate

	INTO #D

	FROM [smsdss].[BMH_UserTwoField_Fact]

	WHERE UserDataKey IN (646) -- 2NTUCRSN
	;

	INSERT INTO smsdss.c_Home_Care_Rpt_Tbl

	SELECT A.PTNO_NUM          AS [PtNo_Num]
	, A.HC_MR_EPI              AS [Home Care MR/EPI]
	, B.HC_SOC_DATE            AS [Start of Care Date]
	, C.HC_NTUC_DATE           AS [NTUC Date]
	, D.HC_NTUC_RSN            AS [NTUC Reason]
	, A.Entered_Into_Invision  AS [Information Entered into Invision On]
	, E.dsch_disp              AS [BMH Coded Disposition]
	, E.vst_start_dtime        AS [BMH Admit DateTime]
	, E.vst_end_dtime          AS [BMH Discharge DateTime]

	FROM #A                      AS A
	LEFT OUTER JOIN #B           AS B
	ON A.PTNO_NUM = B.PTNO_NUM
	LEFT OUTER JOIN #C           AS C
	ON A.PTNO_NUM = C.PTNO_NUM
	LEFT OUTER JOIN #D           AS D
	ON A.PTNO_NUM = D.PTNO_NUM
	-- add plm_ptacct_v admit datetime, disch datetime & coded dispo
	LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS E
	ON A.PTNO_NUM = E.PtNo_Num
	AND E.PtNo_Num < '20000000'
	AND E.Plm_Pt_Acct_Type = 'I'

	WHERE A.PTNO_NUM NOT IN (SELECT ZZZ.PTNO_NUM FROM smsdss.c_Home_Care_Rpt_Tbl AS ZZZ)
	;

	DROP TABLE #A, #B, #C, #D
	;


END

ELSE BEGIN

	SELECT PtNo_Num
	, UserDataKey
	, UserDataText as hc_mr_epi
	, SeqNo
	, LastDataCngDTime as Entered_Into_Invision
	, LoadDate

	INTO #AA

	FROM [smsdss].[BMH_UserTwoField_Fact]

	WHERE UserDataKey IN (644) -- 2HCMREPI

	ORDER BY LastDataCngDTime
	;

	SELECT PtNo_Num
	, UserDataKey
	, CAST(
		LEFT(UserDataText, 2) + '-' + RIGHT(LEFT(UserDataText, 4), 2) +
		'-' + RIGHT(UserDataText, 2)
		AS DATE
		) 	  AS [HC_SOC_DATE]
	, SeqNo
	, LastDataCngDTime
	, LoadDate

	INTO #BB

	FROM [smsdss].[BMH_UserTwoField_Fact]

	WHERE UserDataKey IN (647) -- 2SOCDATE
	;

	SELECT PtNo_Num
	, UserDataKey
	, CAST(
		LEFT(UserDataText, 2) + '-' + RIGHT(LEFT(UserDataText, 4), 2) +
		'-' + RIGHT(UserDataText, 2)
		AS DATE
		) 	  AS [HC_NTUC_DATE]
	, SeqNo
	, LastDataCngDTime
	, LoadDate

	INTO #CC

	FROM [smsdss].[BMH_UserTwoField_Fact]

	WHERE UserDataKey IN (645) -- 2NTUCDTE
	;

	SELECT PtNo_Num
	, UserDataKey
	, UserDataText as [HC_NTUC_RSN]
	, SeqNo
	, LastDataCngDTime
	, LoadDate

	INTO #DD

	FROM [smsdss].[BMH_UserTwoField_Fact]

	WHERE UserDataKey IN (646) -- 2NTUCRSN
	;

	INSERT INTO smsdss.c_Home_Care_Rpt_Tbl

	SELECT A.PTNO_NUM          AS [PtNo_Num]
	, A.HC_MR_EPI              AS [Home Care MR/EPI]
	, B.HC_SOC_DATE            AS [Start of Care Date]
	, C.HC_NTUC_DATE           AS [NTUC Date]
	, D.HC_NTUC_RSN            AS [NTUC Reason]
	, A.Entered_Into_Invision  AS [Information Entered into Invision On]
	, E.dsch_disp              AS [BMH Coded Disposition]
	, E.vst_start_dtime        AS [BMH Admit DateTime]
	, E.vst_end_dtime          AS [BMH Discharge DateTime]

	FROM #AA                      AS A
	LEFT OUTER JOIN #BB           AS B
	ON A.PTNO_NUM = B.PTNO_NUM
	LEFT OUTER JOIN #CC           AS C
	ON A.PTNO_NUM = C.PTNO_NUM
	LEFT OUTER JOIN #DD           AS D
	ON A.PTNO_NUM = D.PTNO_NUM
	-- add plm_ptacct_v admit datetime, disch datetime & coded dispo
	LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS E
	ON A.PTNO_NUM = E.PtNo_Num
	AND E.PtNo_Num < '20000000'
	AND E.Plm_Pt_Acct_Type = 'I'

	WHERE A.PTNO_NUM NOT IN (SELECT ZZZ.PTNO_NUM FROM smsdss.c_Home_Care_Rpt_Tbl AS ZZZ)
	;

	DROP TABLE #AA, #BB, #CC, #DD
	;

END