DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = '2017-01-01';
SET @END   = '2018-04-01';

SELECT A.MED_REC_NO
, A.PTNO_NUM
, A.unit_seq_no
, RTRIM(LTRIM(A.PT_NO)) AS [PT_NO]
, CAST(A.ADM_DATE AS DATE) AS [ADM_DATE]
, CAST(A.DSCH_DATE AS DATE) AS [DSCH_DATE]
, A.hosp_svc
, B.hosp_svc_name
, A.pt_type
, E.pt_type_desc
, A.drg_no
, A.drg_cost_weight
, C.drg_schm
, D.drg_name
, A.TOT_CHG_AMT
, A.from_file_ind

INTO #IP

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsdss.hosp_svc_dim_v AS B
ON A.hosp_svc = B.hosp_svc
	AND A.Regn_Hosp = B.orgz_cd
LEFT OUTER JOIN SMSMIR.vst_ext AS C
ON A.Pt_No = C.pt_id
	AND A.from_file_ind = C.from_file_ind
	AND A.unit_seq_no = C.unit_seq_no
LEFT OUTER JOIN smsmir.drg_mstr AS D
ON A.drg_no = D.drg_no
	AND C.drg_schm = D.drg_schm
LEFT OUTER JOIN smsdss.pt_type_dim_v AS E
ON A.pt_type = E.src_pt_type
	AND A.Regn_Hosp = E.orgz_cd

WHERE A.Plm_Pt_Acct_Type = 'I'
AND A.Dsch_Date >= @START
AND A.Dsch_Date < @END
AND A.Pt_No IN (
	SELECT DISTINCT(ACTV.PT_ID)
	FROM smsmir.actv AS ACTV
	WHERE LEFT(ACTV.ACTV_CD, 3) IN (
		'015','016','007','070'
	)
)

OPTION(FORCE ORDER)
;

-- GET NUCLEAR ACTIVITY
SELECT LTRIM(RTRIM(A.pt_id)) AS pt_id
, A.actv_cd
, A.actv_tot_qty
, A.chg_tot_amt
, B.actv_name
, A.from_file_ind

INTO #Nuclear

FROM smsmir.actv AS A
LEFT OUTER JOIN smsdss.actv_cd_dim_v AS B
ON A.actv_cd = B.actv_cd
	AND A.orgz_cd = B.orgz_cd

WHERE LEFT(A.actv_cd, 3) = '015'
AND A.pt_id IN (
	SELECT A.PT_NO
	FROM #IP AS A
)

GO
;

-- GET CARDIAC REHAB
SELECT LTRIM(RTRIM(A.pt_id)) AS pt_id
, A.actv_cd
, A.actv_tot_qty
, A.chg_tot_amt
, B.actv_name
, A.from_file_ind

INTO #CardRehab

FROM smsmir.actv AS A
LEFT OUTER JOIN smsdss.actv_cd_dim_v AS B
ON A.actv_cd = B.actv_cd
	AND A.orgz_cd = B.orgz_cd

WHERE LEFT(A.actv_cd, 3) = '016'
AND A.pt_id IN (
	SELECT A.PT_NO
	FROM #IP AS A
)

GO
;

-- GET CARDIAC DIAGNOSTIC
SELECT LTRIM(RTRIM(A.pt_id)) AS pt_id
, A.actv_cd
, A.actv_tot_qty
, A.chg_tot_amt
, B.actv_name
, A.from_file_ind

INTO #CardDiagnostic

FROM smsmir.actv AS A
LEFT OUTER JOIN smsdss.actv_cd_dim_v AS B
ON A.actv_cd = B.actv_cd
	AND A.orgz_cd = B.orgz_cd

WHERE LEFT(A.actv_cd, 3) = '007'
AND A.pt_id IN (
	SELECT A.PT_NO
	FROM #IP AS A
)

GO
;

-- GET CARDIAC CATH
SELECT LTRIM(RTRIM(A.pt_id)) AS pt_id
, A.actv_cd
, A.actv_tot_qty
, A.chg_tot_amt
, B.actv_name
, A.from_file_ind

INTO #CardCath

FROM smsmir.actv AS A
LEFT OUTER JOIN smsdss.actv_cd_dim_v AS B
ON A.actv_cd = B.actv_cd
	AND A.orgz_cd = B.orgz_cd

WHERE LEFT(A.actv_cd, 3) = '070'
AND A.pt_id IN (
	SELECT A.PT_NO
	FROM #IP AS A
)

GO
;

-- PULL IP DATA TOGETHER
SELECT IP.Med_Rec_No
, IP.PtNo_Num
, IP.PT_NO
, IP.unit_seq_no
, IP.ADM_DATE
, IP.DSCH_DATE
, IP.hosp_svc
, IP.hosp_svc_name
, IP.pt_type
, IP.pt_type_desc
, IP.drg_no
, IP.drg_cost_weight
, IP.drg_schm
, IP.drg_name
, IP.tot_chg_amt
, CC.actv_tot_qty AS [CardCath_Actv_Qty]
, CC.chg_tot_amt AS [CardCath_Actv_Chgs]
, CD.actv_tot_qty AS [CardDiag_Actv_Qty]
, CD.chg_tot_amt AS [CardDiag_Actv_Chgs]
, CR.actv_tot_qty AS [CardRehab_Actv_Qty]
, CR.chg_tot_amt AS [CardRehab_Actv_Chgs]
, N.actv_tot_qty AS [Nuclear_Actv_Qty]
, N.chg_tot_amt AS [Nuclear_Actv_Chgs]

FROM #IP AS IP
LEFT OUTER JOIN (
	SELECT CC.pt_id
	, CC.from_file_ind
	, SUM(CC.actv_tot_qty) AS actv_tot_qty
	, SUM(CC.chg_tot_amt) AS chg_tot_amt
	FROM #CardCath AS CC
	GROUP BY CC.pt_id, CC.from_file_ind
) AS CC
ON IP.PT_NO = CC.pt_id
	AND IP.from_file_ind = CC.from_file_ind
LEFT OUTER JOIN (
	SELECT CD.pt_id
	, CD.from_file_ind
	, SUM(CD.actv_tot_qty) AS actv_tot_qty
	, SUM(CD.chg_tot_amt) AS chg_tot_amt
	FROM #CardDiagnostic AS CD
	GROUP BY CD.pt_id, CD.from_file_ind
) AS CD
ON IP.PT_NO = CD.pt_id
	AND IP.from_file_ind = CD.from_file_ind
-- GET TOTAL CARDIAC REHAB ACTIVITY
LEFT OUTER JOIN (
	SELECT CR.pt_id
	, CR.from_file_ind
	, SUM(CR.actv_tot_qty) AS actv_tot_qty
	, SUM(CR.chg_tot_amt) AS chg_tot_amt
	FROM #CardRehab AS CR
	GROUP BY CR.pt_id, CR.from_file_ind
) AS CR
ON IP.PT_NO = CR.pt_id
	AND IP.from_file_ind = CR.from_file_ind
-- GET TOTAL NUCLEAR ACTIVITY
LEFT OUTER JOIN (
	SELECT N.pt_id
	, from_file_ind
	, SUM(N.actv_tot_qty) AS actv_tot_qty
	, SUM(N.chg_tot_amt) AS chg_tot_amt
	FROM #Nuclear AS N
	GROUP BY N.pt_id, N.from_file_ind
) AS N
ON IP.PT_NO = N.pt_id
	AND IP.from_file_ind = N.from_file_ind
;

--DROP TABLE #IP, #CardCath, #CardDiagnostic, #CardRehab, #Nuclear
--;