USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_Home_Care_sp]    Script Date: 1/13/2016 2:32:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [smsdss].[c_Home_Care_sp]
AS

BEGIN

	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

	IF OBJECT_ID('smsdss.c_Home_Care_Rpt_Tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_Home_Care_Rpt_Tbl;

	DECLARE @HC_MRN TABLE (
		PK INT IDENTITY(1, 1)   PRIMARY KEY
		, PTNO_NUM              INT
		, USERDATAKEY           VARCHAR(4)
		, HC_MR_EPI             VARCHAR(10)
		, SEQ_NUM               INT
		, Entered_Into_Invision DATETIME
		, Loaded_Into_DSS       DATETIME
	);

	WITH CTE1 AS (
		SELECT PtNo_Num
		, UserDataKey
		, UserDataText
		, SeqNo
		, LastDataCngDTime
		, LoadDate

		FROM [smsdss].[BMH_UserTwoField_Fact]

		WHERE UserDataKey IN (644) -- 2HCMREPI
	)

	INSERT INTO @HC_MRN
	SELECT *
	FROM CTE1

	--SELECT * FROM @HC_MRN

	DECLARE @HC_SOC_DATE TABLE (
		PK INT IDENTITY(1, 1)   PRIMARY KEY
		, PTNO_NUM              INT
		, USERDATAKEY           VARCHAR(4)
		, HC_SOC_DATE           DATE
		, SEQ_NUM               INT
		, Entered_Into_Invision DATETIME
		, Loaded_Into_DSS       DATETIME
	);

	WITH CTE2 AS (
		SELECT PtNo_Num
		, UserDataKey
		, CAST(
			LEFT(UserDataText, 2) + '-' + RIGHT(LEFT(UserDataText, 4), 2) +
			'-' + RIGHT(UserDataText, 2)
			AS DATE
			) 	  AS [SOC DATE]
		, SeqNo
		, LastDataCngDTime
		, LoadDate

		FROM [smsdss].[BMH_UserTwoField_Fact]

		WHERE UserDataKey IN (647) -- 2SOCDATE
	)

	INSERT INTO @HC_SOC_DATE
	SELECT *
	FROM CTE2

	--SELECT * FROM @HC_SOC_DATE

	DECLARE @HC_NTUC_DATE TABLE (
		PK INT IDENTITY(1, 1)   PRIMARY KEY
		, PTNO_NUM              INT
		, USERDATAKEY           VARCHAR(4)
		, HC_NTUC_DATE          DATE
		, SEQ_NUM               INT
		, Entered_Into_Invision DATETIME
		, Loaded_Into_DSS       DATETIME
	);

	WITH CTE3 AS (
		SELECT PtNo_Num
		, UserDataKey
		, CAST(
			LEFT(UserDataText, 2) + '-' + RIGHT(LEFT(UserDataText, 4), 2) +
			'-' + RIGHT(UserDataText, 2)
			AS DATE
			) 	  AS [NTUC DATE]
		, SeqNo
		, LastDataCngDTime
		, LoadDate

		FROM [smsdss].[BMH_UserTwoField_Fact]

		WHERE UserDataKey IN (645) -- 2NTUCDTE
	)

	INSERT INTO @HC_NTUC_DATE
	SELECT *
	FROM CTE3

	--SELECT * FROM @HC_NTUC_DATE

	DECLARE @HC_NTUC_RSN TABLE (
		PK INT IDENTITY(1, 1)   PRIMARY KEY
		, PTNO_NUM              INT
		, USERDATAKEY           VARCHAR(4)
		, HC_NTUC_RSN           VARCHAR(50)
		, SEQ_NUM               INT
		, Entered_Into_Invision DATETIME
		, Loaded_Into_DSS       DATETIME
	);

	WITH CTE3 AS (
		SELECT PtNo_Num
		, UserDataKey
		, UserDataText
		, SeqNo
		, LastDataCngDTime
		, LoadDate

		FROM [smsdss].[BMH_UserTwoField_Fact]

		WHERE UserDataKey IN (646) -- 2NTUCRSN
	)

	INSERT INTO @HC_NTUC_RSN
	SELECT *
	FROM CTE3

	--SELECT * FROM @HC_NTUC_RSN

	SELECT A.PTNO_NUM          AS [PtNo_Num]
	, A.HC_MR_EPI              AS [Home Care MR/EPI]
	, B.HC_SOC_DATE            AS [Start of Care Date]
	, C.HC_NTUC_DATE           AS [NTUC Date]
	, D.HC_NTUC_RSN            AS [NTUC Reason]
	, A.Entered_Into_Invision  AS [Information Entered into Invision On]
	, E.dsch_disp              AS [BMH Coded Disposition]
	, E.vst_start_dtime        AS [BMH Admit DateTime]
	, E.vst_end_dtime          AS [BMH Discharge DateTime]

	INTO smsdss.c_Home_Care_Rpt_Tbl

	FROM @HC_MRN                            AS A
	LEFT OUTER JOIN @HC_SOC_DATE            AS B
	ON A.PTNO_NUM = B.PTNO_NUM
	LEFT OUTER JOIN @HC_NTUC_DATE           AS C
	ON A.PTNO_NUM = C.PTNO_NUM
	LEFT OUTER JOIN @HC_NTUC_RSN            AS D
	ON A.PTNO_NUM = D.PTNO_NUM
	-- add plm_ptacct_v admit datetime, disch datetime & coded dispo
	LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS E
	ON A.PTNO_NUM = E.PtNo_Num
		AND E.PtNo_Num < '20000000'
		AND E.Plm_Pt_Acct_Type = 'I'

END