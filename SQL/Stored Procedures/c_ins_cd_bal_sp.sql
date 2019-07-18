USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [smsdss].[c_ins_cd_bal_sp]
AS

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

/*
***********************************************************************
File: c_ins_cd_bal_sp.sql

Input Parameters:
	None

Tables/Views:
	smsmir.mir_pyr_plan
    smsmir.vst_rpt

Creates Table:
	smsdss.c_ins_cd_bal_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Create a report table of the balace sitting with insurance daily.

Revision History:
Date		Version		Description
----		----		----
2019-06-28	v1			Initial Creation
***********************************************************************
*/

IF NOT EXISTS (
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name = 'c_ins_cd_bal_tbl' AND xtype = 'U'
)

BEGIN

	CREATE TABLE smsdss.c_ins_cd_bal_tbl (
        pt_id VARCHAR(20),
        fc VARCHAR(2),
        credit_rating VARCHAR(3),
        hosp_svc VARCHAR(5),
        pyr_cd VARCHAR(5),
        pyr_cd_desc VARCHAR(100),
        pyr_group VARCHAR(50),
        pyr_seq_no char(1),
        ins_cd_bal money,
        age_in_days INT,
        RunDate DATE,
        RunDateTime DATETIME2
    )
    ;
        -- NON-UNITIZED
    SELECT PYRPLAN.pt_id
    , VST.cr_rating
    , VST.fc
    , VST.hosp_svc
    , CAST(DATEDIFF(DD, VST.VST_END_DATE, GETDATE()) AS int) AS [Age_In_Days]
    , PYRPLAN.pyr_cd
    , PYRPLAN.pyr_seq_no
    , PYRPLAN.tot_amt_due                                AS [Ins_Cd_Bal]
    , [RunDate] = CAST(GETDATE() AS date)
    , [RunDateTime] = GETDATE()

    INTO #TEMPA

    FROM SMSMIR.PYR_PLAN AS PYRPLAN
    LEFT JOIN smsmir.vst_rpt VST
    ON PYRPLAN.pt_id = VST.pt_id

    WHERE VST.vst_end_date IS NOT NULL
    AND VST.tot_bal_amt != 0
    AND VST.fc not in (
        '1','2','3','4','5','6','7','8','9'
    )
    AND LEFT(VST.pt_id, 5) NOT IN ('00007', '00009')
    AND LEFT(VST.PT_ID, 6) != '000009'

    ORDER BY PYRPLAN.pt_id
    , PYRPLAN.pyr_cd
    ;

    SELECT a.pt_id
    , a.fc
    , a.cr_rating
    , a.hosp_svc
    , a.pyr_cd
    , pdv.pyr_cd_desc
    , pdv.pyr_group2
    , a.pyr_seq_no
    , a.Ins_Cd_Bal
    , a.Age_In_Days
    , a.RunDate
    , a.RunDateTime

    INTO #TEMPB

    FROM #TEMPA as a
    left outer join smsdss.pyr_dim_v as pdv
    on a.pyr_cd = pdv.pyr_cd
        and pdv.orgz_cd = 's0x0'

    WHERE A.Ins_Cd_Bal != 0

    ORDER BY a.pt_id, a.pyr_seq_no
    ;

    -- UNITIZED
    SELECT A.pt_id
    , '' AS FC
    , '' AS CREDIT_RATING
    , '' AS HOSP_SVC
    , A.pyr_cd
    , PDV.pyr_cd_desc
    , PDV.pyr_group2
	, A.pyr_seq_no
    , A.tot_amt_due AS [Ins_Cd_Bal]
    , '' AS [AGE_IN_DAYS]
    , [RunDate] = CAST(GETDATE() AS date)
    , [RunDateTime] = GETDATE()

    INTO #TEMPC

    FROM SMSMIR.mir_pyr_plan AS A
    LEFT OUTER JOIN smsdss.pyr_dim_v AS PDV
    ON a.pyr_cd = pdv.pyr_cd
        AND pdv.orgz_cd = 's0x0'

    WHERE LEFT(A.PT_ID, 5) IN ('00007')
    AND A.pt_id IN (
        SELECT DISTINCT VST.PT_ID
        FROM SMSMIR.vst_rpt AS VST
        WHERE vst.tot_bal_amt != 0
        AND VST.unit_seq_no != '99999999'
        AND VST.fc not in (
            '1','2','3','4','5','6','7','8','9'
        )
    )
    ;
	INSERT INTO smsdss.c_ins_cd_bal_tbl

    SELECT A.PT_ID
    , A.FC
    , A.CR_RATING
    , A.HOSP_SVC
    , A.pyr_cd
    , A.pyr_cd_desc
    , A.pyr_group2
    , A.pyr_seq_no
    , A.INS_CD_BAL
    , A.Age_In_Days
    , A.RunDate
    , A.RunDateTime

    FROM #TEMPB AS A

    UNION

    SELECT C.PT_ID
    , C.FC
    , C.CREDIT_RATING
    , C.HOSP_SVC
    , C.pyr_cd
    , C.pyr_cd_desc
    , C.pyr_group2
    , C.pyr_seq_no
    , C.INS_CD_BAL
    , C.Age_In_Days
    , C.RunDate
    , C.RunDateTime

    FROM #TEMPC AS C
	;

	DROP TABLE #TEMPA;
	DROP TABLE #TEMPB;
	DROP TABLE #TEMPC;

END

ELSE BEGIN

    -- NON-UNITIZED
    SELECT PYRPLAN.pt_id
    , VST.cr_rating
    , VST.fc
    , VST.hosp_svc
    , CAST(DATEDIFF(DD, VST.VST_END_DATE, GETDATE()) AS int) AS [Age_In_Days]
    , PYRPLAN.pyr_cd
    , PYRPLAN.pyr_seq_no
    , PYRPLAN.tot_amt_due                                AS [Ins_Cd_Bal]
    , [RunDate] = CAST(GETDATE() AS date)
    , [RunDateTime] = GETDATE()

    INTO #TEMPAA

    FROM SMSMIR.PYR_PLAN AS PYRPLAN
    LEFT JOIN smsmir.vst_rpt VST
    ON PYRPLAN.pt_id = VST.pt_id

    WHERE VST.vst_end_date IS NOT NULL
    AND VST.tot_bal_amt != 0
    AND VST.fc not in (
        '1','2','3','4','5','6','7','8','9'
    )
    AND LEFT(VST.pt_id, 5) NOT IN ('00007', '00009')
    AND LEFT(VST.PT_ID, 6) != '000009'

    ORDER BY PYRPLAN.pt_id
    , PYRPLAN.pyr_cd
    ;

    SELECT a.pt_id
    , a.fc
    , a.cr_rating
    , a.hosp_svc
    , a.pyr_cd
    , pdv.pyr_cd_desc
    , pdv.pyr_group2
    , a.pyr_seq_no
    , a.Ins_Cd_Bal
    , a.Age_In_Days
    , a.RunDate
    , a.RunDateTime

    INTO #TEMPBB

    FROM #TEMPAA as a
    left outer join smsdss.pyr_dim_v as pdv
    on a.pyr_cd = pdv.pyr_cd
        and pdv.orgz_cd = 's0x0'

    WHERE A.Ins_Cd_Bal != 0

    ORDER BY a.pt_id, a.pyr_seq_no
    ;

    -- UNITIZED
    SELECT A.pt_id
    , '' AS FC
    , '' AS CREDIT_RATING
    , '' AS HOSP_SVC
    , A.pyr_cd
    , PDV.pyr_cd_desc
    , PDV.pyr_group2
	, A.pyr_seq_no
    , A.tot_amt_due AS [Ins_Cd_Bal]
    , '' AS [AGE_IN_DAYS]
    , [RunDate] = CAST(GETDATE() AS date)
    , [RunDateTime] = GETDATE()

    INTO #TEMPCC

    FROM SMSMIR.mir_pyr_plan AS A
    LEFT OUTER JOIN smsdss.pyr_dim_v AS PDV
    ON a.pyr_cd = pdv.pyr_cd
        AND pdv.orgz_cd = 's0x0'

    WHERE LEFT(A.PT_ID, 5) IN ('00007')
    AND A.pt_id IN (
        SELECT DISTINCT VST.PT_ID
        FROM SMSMIR.vst_rpt AS VST
        WHERE vst.tot_bal_amt != 0
        AND VST.unit_seq_no != '99999999'
        AND VST.fc not in (
            '1','2','3','4','5','6','7','8','9'
        )
    )
    ;

	INSERT INTO smsdss.c_ins_cd_bal_tbl
	
	SELECT ZZZ.*

	FROM (
		SELECT A.PT_ID
		, A.FC
		, A.CR_RATING
		, A.HOSP_SVC
		, A.pyr_cd
		, A.pyr_cd_desc
		, A.pyr_group2
		, A.pyr_seq_no
		, A.INS_CD_BAL
		, A.Age_In_Days
		, A.RunDate
		, A.RunDateTime

		FROM #TEMPBB AS A

		UNION

		SELECT C.PT_ID
		, C.FC
		, C.CREDIT_RATING
		, C.HOSP_SVC
		, C.pyr_cd
		, C.pyr_cd_desc
		, C.pyr_group2
		, C.pyr_seq_no
		, C.INS_CD_BAL
		, C.Age_In_Days
		, C.RunDate
		, C.RunDateTime

		FROM #TEMPCC AS C
	) AS ZZZ

    -- MAKE SURE IT WAS NOT RUN FOR THE DAY ALREADY
	WHERE CAST(GETDATE() AS date) <> isnull((SELECT MAX(RunDate) FROM smsdss.c_ins_cd_bal_tbl), getdate() - 1)
	;

	DROP TABLE #TEMPAA;
	DROP TABLE #TEMPBB;
	DROP TABLE #TEMPCC;

END
;