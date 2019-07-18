/*
***********************************************************************
File: discharge_summaries_within_36_hrs.sql

Input Parameters:
	None

Tables/Views:
	smsmir.ddc_doc
	smsmir.ddc_doc_vers
	smsdss.BMH_PLM_PtAcct_V
	smsmir.sr_ord
	smsdss.pract_dim_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the times of the following:
		1. Last Discharge Order DTime
		2. First Final Discharge/Transfer Summary DTime
		3. Discharge Orders 36 hours +- from Discharge DTime as outlier
		4. Datediff Discharge Order Discharge Summary 36 hours +- as outlier
		5. PDoc full use 10-01-2018

Revision History:
Date		Version		Description
----		----		----
2019-01-08	v1			Initial Creation
2019-01-23	v2			Add A.Plm_Pt_Acct_Type = 'I'
						Add DATEDIFF for vst_end_dtime and summary time
						Add AMA Flag
						Add Enc_Flag = 1
***********************************************************************
*/

-- Get initial discharged population with last discharge order dtim
WITH CTE1 AS (
	SELECT A.Med_Rec_No
	, A.PtNo_Num
	, A.Pt_No
	, A.Atn_Dr_No
	, PDV.pract_rpt_name
	, A.vst_end_dtime
	, SO.ord_no
	, SO.pty_cd
	, SO.pty_name
	, SO.Ent_DTime
	, SO.[DATE]
	, SO.[TIME]
	, A.dsch_disp

	FROM smsdss.BMH_PLM_PtAcct_V AS A
	LEFT OUTER JOIN (
		SELECT B.episode_no
		, B.ord_no
		, B.pty_cd
		, B.pty_name
		, B.Ent_DTime
		, B.[DATE]
		, B.[TIME]

		FROM (
			SELECT EPISODE_NO
			, ORD_NO
			, pty_cd
			, pty_name
			, ent_dtime               AS [Ent_DTime]
			, CAST(ENT_DTIME AS DATE) AS [DATE]
			, CAST(ENT_DTIME AS TIME) AS [TIME]
			, ROW_NUMBER() OVER(
								PARTITION BY EPISODE_NO 
								ORDER BY ORD_NO DESC
								) AS ROWNUM
			FROM smsmir.sr_ord
			WHERE svc_desc = 'DISCHARGE TO'
			AND episode_no < '20000000'
		) B

		WHERE B.ROWNUM = 1
	) SO
	ON A.PtNo_Num = SO.episode_no
	LEFT OUTER JOIN smsdss.pract_dim_v AS PDV
	ON A.Atn_Dr_No = PDV.src_pract_no
		AND A.Regn_Hosp = PDV.orgz_cd

	WHERE A.Dsch_Date >= '2018-10-01'
	AND A.Dsch_Date < '2019-01-01'
	AND A.tot_chg_amt > 0
	AND A.Plm_Pt_Acct_Type = 'I'
	AND LEFT(A.PTNO_NUM, 1) != '2'
	AND LEFT(A.PTNO_NUM, 4) != '1999'
	AND PDV.src_spclty_cd = 'HOSIM'
)

SELECT C1.Med_Rec_No
, C1.PtNo_Num
, C1.Pt_No
, C1.Atn_Dr_No
, C1.pract_rpt_name
, C1.vst_end_dtime
, C1.ord_no
, C1.pty_cd
, C1.pty_name
, C1.Ent_DTime
, C1.[DATE]
, C1.[TIME]
, C1.dsch_disp

INTO #BasePop

FROM CTE1 AS C1

--SELECT * FROM #BasePop WHERE PtNo_Num = ''
;

-- Get Discharge Summaries
WITH CTE2 AS (
	SELECT a.episode_no
	, a.pt_id
	, a.vst_id
	, a.vst_no
	, a.parent_doc_obj_id
	, a.doc_obj_id
	, a.doc_concept_id
	, a.doc_name
	, a.doc_author
	, a.staff_obj_id
	, a.cre_dtime
	, b.coll_dtime
	, b.sign_dtime
	, b.doc_sts
	, b.vers_id

	FROM smsmir.ddc_doc AS A
	LEFT OUTER JOIN smsmir.ddc_doc_vers AS B
	ON a.doc_obj_id = b.doc_obj_id
		AND a.episode_no = b.episode_no

	WHERE a.doc_name = 'Discharge / Transfer Summary'
	AND b.doc_sts IN ('FINAL')
	AND A.episode_no IN (
		SELECT XXX.PtNo_Num
		FROM #BasePop AS XXX
	)
	AND b.vers_id = (
					SELECT MIN(xxx.vers_id) 
					FROM smsmir.ddc_doc_vers AS XXX
					WHERE xxx.doc_obj_id = a.doc_obj_id 
					AND xxx.episode_no = a.episode_no
					AND XXX.doc_sts = B.doc_sts
					)

)

SELECT C2.episode_no
, C2.doc_name
, C2.doc_author
, C2.Cre_DTime
, C2.Coll_DTime
, C2.Sign_DTime
, C2.DOC_STS
, C2.Vers_ID

INTO #DischargeSummaries

FROM CTE2 AS C2

--SELECT * FROM #DischargeSummaries WHERE episode_no = ''
;

-- PULL IT ALL TOGETHER
SELECT A.Med_Rec_No
, A.PtNo_Num
, A.Atn_Dr_No AS [Atn_Dr_ID]
, UPPER(A.pract_rpt_name) AS [Atn_Dr_Name]
, A.vst_end_dtime AS [Dsch_DTime]
, A.ord_no
, A.pty_cd AS [Dsch_Ord_Provider_ID]
, UPPER(A.pty_name) AS [Dsch_Ord_Provider_Name]
, A.Ent_DTime
, B.doc_name
, B.doc_author
, B.doc_sts
, B.cre_dtime
, B.coll_dtime
, B.sign_dtime
, CASE
	WHEN A.ord_no IS NULL
		THEN 0
		ELSE 1
  END AS [DSCH_ORD_FLAG]
, CASE
	WHEN B.doc_name IS NULL
		THEN 0
		ELSE 1
  END AS [DSCH_SUMMARY_FLAG]
, DATEDIFF(HOUR, A.ENT_DTIME, B.SIGN_DTIME) AS [Hrs_DCO_to_DCS]
, CASE
	WHEN DATEDIFF(HOUR, A.Ent_DTime, B.sign_dtime) < -36
		THEN 1
		ELSE 0
  END AS [EARLY_DCO_to_DCS_Flag]
, CASE
	WHEN DATEDIFF(HOUR, A.Ent_DTime, B.sign_dtime) > 36
		THEN 1
		ELSE 0
  END AS [LATE_DCO_to_DCS_Flag]
, DATEDIFF(HOUR, A.vst_end_dtime, B.SIGN_DTIME) AS [HRS_DC_to_DCS]
, CASE
	WHEN DATEDIFF(HOUR, A.vst_end_dtime, B.sign_dtime) < -36
		THEN 1
		ELSE 0
  END AS [EARLY_DC_to_DCS_Flag]
, CASE
	WHEN DATEDIFF(HOUR, A.vst_end_dtime, B.sign_dtime) > 36
		THEN 1
		ELSE 0
  END AS [LATE_DC_to_DCS_Flag]
, [AMA_Flag] = CASE WHEN RIGHT(RTRIM(LTRIM(A.DSCH_DISP)), 2) = 'MA' THEN 1 ELSE 0 END
, [Enc_Flag] = 1


FROM #BasePop AS A
LEFT OUTER JOIN #DischargeSummaries AS B
ON A.PtNo_Num = B.episode_no

ORDER BY A.vst_end_dtime
;

DROP TABLE #BasePop, #DischargeSummaries
;