/*
Author: Steven P Sanderson II, MPH
Department: Finance, Revenue CYCLE

This query gets the detail behind teh Orders_Verbal_Telephone.sql query.
*/

DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2017-05-01';
SET @END   = '2018-05-01';
-----

SELECT B.episode_no
, B.vst_type_cd
, B.pt_sts_cd
, B.hosp_svc
, A.req_pty_cd
, COALESCE(
	E.PRACT_RPT_NAME, 
	F.PRACT_RPT_NAME,
	G.PRACT_RPT_NAME, 
	H.PRACT_RPT_NAME,
	I.PRACT_RPT_NAME,
	J.PRACT_RPT_NAME,
	K.PRACT_RPT_NAME
) AS PROVIDER_NAME
, CASE
	WHEN E.spclty_cd IS NOT NULL AND E.spclty_cd != '?' THEN E.spclty_cd
	WHEN F.spclty_cd IS NOT NULL AND F.spclty_cd != '?' THEN F.spclty_cd
	WHEN G.spclty_cd IS NOT NULL AND G.spclty_cd != '?' THEN G.spclty_cd
	WHEN H.spclty_cd IS NOT NULL AND H.spclty_cd != '?' THEN H.spclty_cd
	WHEN I.spclty_cd1 IS NOT NULL AND I.spclty_cd1 != '?' THEN I.spclty_cd1
	WHEN J.spclty_cd1 IS NOT NULL AND J.spclty_cd1 != '?' THEN J.spclty_cd1
	WHEN K.spclty_cd1 IS NOT NULL AND K.spclty_cd1 != '?' THEN K.spclty_cd1
  END AS [spclty_cd]
, CASE
	WHEN (
		E.src_spclty_cd = 'HOSIM' OR
		F.src_spclty_cd = 'HOSIM' OR
		G.src_spclty_cd = 'HOSIM' OR
		H.src_spclty_cd = 'HOSIM' OR
		I.spclty_cd1    = 'HOSIM' OR
		J.spclty_cd1    = 'HOSIM' OR
		K.spclty_cd1    = 'HOSIM'
	)
		THEN 'Hospitalist'
	WHEN LEFT(A.REQ_PTY_CD, 1) = '9' 
		THEN 'PA / NP'
		ELSE 'Private'
  END AS [Hospitalist_NP_PA_Flag]
, A.ent_dtime
, DATEPART(HOUR, A.ENT_DTIME) AS [Ord_Ent_Hr]
, CASE
	WHEN DATEPART(WEEKDAY, A.ent_date) = 1 THEN 'SUNDAY'
	WHEN DATEPART(WEEKDAY, A.ent_date) = 2 THEN 'MONDAY'
	WHEN DATEPART(WEEKDAY, A.ent_date) = 3 THEN 'TUESDAY'
	WHEN DATEPART(WEEKDAY, A.ent_date) = 4 THEN 'WEDNESDAY'
	WHEN DATEPART(WEEKDAY, A.ent_date) = 5 THEN 'THURSDAY'
	WHEN DATEPART(WEEKDAY, A.ent_date) = 6 THEN 'FRIDAY'
	WHEN DATEPART(WEEKDAY, A.ent_date) = 7 THEN 'SATURDAY'
  END AS [DOW_Name]
, DATEPART(WEEKDAY, A.ent_date) AS [Ord_Ent_DOW]
, DATEPART(WEEK, A.ENT_DATE) AS [Ord_Ent_Wk]
, DATEPART(MONTH, A.ent_date) AS [Ord_Ent_Mo]
, DATEPART(QUARTER, A.ent_date) AS [Ord_Ent_Qtr]
, DATEPART(YEAR, A.ent_date) AS [Ord_Ent_Yr]
, A.ord_no
, A.ord_src_modf_name
, A.med_ord_name_modf
, A.ord_type_abbr
, A.ord_sub_type_abbr

INTO #TEMPA

FROM smsdss.QOC_Ord_v AS A
LEFT OUTER JOIN smsdss.QOC_vst_summ_v AS B
ON A.pref_vst_pms_id_col = B.pref_vst_pms_id_col
LEFT JOIN smsdss.pract_dim_v AS E
ON A.Req_Pty_Cd = E.src_pract_no
	AND E.orgz_cd = 'S0X0'
LEFT JOIN smsdss.pract_dim_v AS F
ON A.Req_Pty_Cd = F.src_pract_no
	AND F.orgz_cd = 'NTX0'
LEFT JOIN smsdss.pract_dim_v AS G
ON A.Req_Pty_Cd = G.src_pract_no
	AND G.orgz_cd = 'XNT'
LEFT JOIN smsdss.pract_dim_v AS H
ON A.Req_Pty_Cd = H.src_pract_no
	AND H.orgz_cd = '0002'
LEFT JOIN smsmir.pract_mstr  AS I
ON A.Req_Pty_Cd = I.pract_no
	AND I.iss_orgz_cd = '0002'
LEFT JOIN smsmir.pract_mstr  AS J
ON A.Req_Pty_Cd = J.pract_no
	AND J.iss_orgz_cd = 'NTX0'
LEFT JOIN smsmir.pract_mstr  AS K
ON A.Req_Pty_Cd = K.pract_no
	AND K.iss_orgz_cd = 'S0X0'

WHERE A.phys_req_ind = 1
AND A.ent_date >= @START
AND A.ent_date < @END
AND A.req_pty_cd IS NOT NULL
AND A.req_pty_cd NOT IN (
	'000000', '000059', '000099','000666','004337'
	,'4337','999998'
)

GO
;

SELECT A.episode_no
, A.vst_type_cd
, A.pt_sts_cd
, A.hosp_svc
, A.req_pty_cd
, A.PROVIDER_NAME
, A.spclty_cd
, CASE
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'IM' THEN 'Internal Medicine'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'SG' THEN 'Surgery'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'FP' THEN 'Family Practice'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'OB' THEN 'Ob/Gyn'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'PE' THEN 'Pediatrics'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'PS' THEN 'Pyschiatry'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'DT' THEN 'Dentistry'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'AN' THEN 'Anesthesiology'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'RD' THEN 'Radiology'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'IP' THEN 'Internal Medicine/Pediatrics'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'ME' THEN 'Medical Education'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'ED' THEN 'Emergency Department'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'AH' THEN 'Allied Health Professional'
	ELSE ''
  END AS SPCLTY_DESC
, A.Hospitalist_NP_PA_Flag
, A.ent_dtime
, A.Ord_Ent_Hr
, A.DOW_Name
, A.Ord_Ent_DOW
, A.Ord_Ent_Wk
, A.Ord_Ent_Mo
, A.Ord_Ent_Qtr
, A.Ord_Ent_Yr
, A.ord_no
, A.ord_src_modf_name
, A.med_ord_name_modf
, A.ord_type_abbr
, A.ord_sub_type_abbr

FROM #TEMPA AS A

GO
;

DROP TABLE #TEMPA
GO
;