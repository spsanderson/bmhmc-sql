/*
Author: Steven P Sanderson II, MPH
Department: Finance, Revenue CYCLE

This query gets the detail behind teh Orders_Verbal_Telephone.sql query.

Version:
v1	- 2018-24-05	- Initial creation
v2	- 2018-06-11	- ADD excl_ord_for_CPOE_ind = 0
v3	- 2018-06-27	- Add medication orders
*/

DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2018-05-01';
SET @END   = '2018-06-01';
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
, CAST(A.ent_date AS date) AS [Ent_Date]
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
, CASE
	WHEN COALESCE(a.lab_ord_CPOE_ind, a.med_ord_CPOE_ind, a.rad_ord_CPOE_ind) = 1
		THEN 'CPOE'
		ELSE A.ord_src_modf_name
  END AS [CPOE_Flag]
, A.ord_src_modf_name
, A.med_ord_name_modf
, A.ord_type_abbr
, A.ord_sub_type_abbr
, A.phys_ent_ind
, A.cre_user_name

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
AND A.excl_ord_for_CPOE_ind = 0
AND A.med_ord_ind = 0
AND A.cre_user_id NOT IN (
	'154031'
)
AND A.ord_sub_type_abbr NOT IN (
	'Lab Order Only',
	'Rad Order Only'
)
AND A.med_ord_name_modf != 'GLUCOMETER TESTING'
AND B.vst_type_cd = 'I'
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
, A.Ent_Date
, A.ent_dtime
, A.Ord_Ent_Hr
, A.DOW_Name
, A.Ord_Ent_DOW
, A.Ord_Ent_Wk
, A.Ord_Ent_Mo
, A.Ord_Ent_Qtr
, A.Ord_Ent_Yr
, A.ord_no
, A.CPOE_Flag
, a.ord_src_modf_name
, A.med_ord_name_modf
, A.ord_type_abbr
, A.ord_sub_type_abbr
, A.phys_ent_ind
, A.cre_user_name

INTO #NON_MED_ORDERS

FROM #TEMPA AS A

ORDER BY A.CPOE_Flag
;

SELECT D.episode_no
, A.MedRecNo
, B.ord_obj_id
, A.POEOrdNo
, D.vst_type_cd
, D.pt_sts_cd
, D.hosp_svc
, B.req_pty_cd
, B.req_pty_name
, COALESCE(
	E.PRACT_RPT_NAME, 
	F.PRACT_RPT_NAME,
	G.PRACT_RPT_NAME, 
	H.PRACT_RPT_NAME,
	I.PRACT_RPT_NAME,
	J.PRACT_RPT_NAME,
	K.PRACT_RPT_NAME
) AS [PROVIDER_NAME]
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
	WHEN LEFT(B.REQ_PTY_CD, 1) = '9' 
		THEN 'PA / NP'
		ELSE 'Private'
  END AS [Hospitalist_NP_PA_Flag]
, CAST(B.ent_date AS date) AS [Ent_Date]
, B.ent_dtime
, DATEPART(HOUR, B.ENT_DTIME) AS [Ord_Ent_Hr]
, CASE
	WHEN DATEPART(WEEKDAY, B.ent_date) = 1 THEN 'SUNDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 2 THEN 'MONDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 3 THEN 'TUESDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 4 THEN 'WEDNESDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 5 THEN 'THURSDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 6 THEN 'FRIDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 7 THEN 'SATURDAY'
  END AS [DOW_Name]
, DATEPART(WEEKDAY, B.ent_date) AS [Ord_Ent_DOW]
, DATEPART(WEEK, B.ENT_DATE) AS [Ord_Ent_Wk]
, DATEPART(MONTH, B.ent_date) AS [Ord_Ent_Mo]
, DATEPART(QUARTER, B.ent_date) AS [Ord_Ent_Qtr]
, DATEPART(YEAR, B.ent_date) AS [Ord_Ent_Yr]
, B.ord_no
, CASE
	WHEN COALESCE(B.lab_ord_CPOE_ind, B.med_ord_CPOE_ind, B.rad_ord_CPOE_ind) = 1
		THEN 'CPOE'
		ELSE B.ord_src_modf_name
  END AS [CPOE_Flag]
, B.ord_src_modf_name
, B.med_ord_name_modf
, B.ord_type_abbr
, B.ord_sub_type_abbr
, B.phys_ent_ind
, B.cre_user_name

INTO #MED_ORDERSA

FROM smsmir.PHM_Ord AS A
LEFT OUTER JOIN smsdss.QOC_Ord_v AS B
ON A.AncilOrdNo = B.ord_obj_id
LEFT OUTER JOIN smsdss.QOC_vst_summ_v AS D
ON B.pref_vst_pms_id_col = D.pref_vst_pms_id_col
LEFT JOIN smsdss.pract_dim_v AS E
ON B.Req_Pty_Cd = E.src_pract_no
	AND E.orgz_cd = 'S0X0'
LEFT JOIN smsdss.pract_dim_v AS F
ON B.Req_Pty_Cd = F.src_pract_no
	AND F.orgz_cd = 'NTX0'
LEFT JOIN smsdss.pract_dim_v AS G
ON B.Req_Pty_Cd = G.src_pract_no
	AND G.orgz_cd = 'XNT'
LEFT JOIN smsdss.pract_dim_v AS H
ON B.Req_Pty_Cd = H.src_pract_no
	AND H.orgz_cd = '0002'
LEFT JOIN smsmir.pract_mstr  AS I
ON B.Req_Pty_Cd = I.pract_no
	AND I.iss_orgz_cd = '0002'
LEFT JOIN smsmir.pract_mstr  AS J
ON B.Req_Pty_Cd = J.pract_no
	AND J.iss_orgz_cd = 'NTX0'
LEFT JOIN smsmir.pract_mstr  AS K
ON B.Req_Pty_Cd = K.pract_no
	AND K.iss_orgz_cd = 'S0X0'

WHERE B.ent_date >= @START
AND B.ent_date < @END
AND B.phys_req_ind = 1
-- ip_ord_ind = 1 means the encounter is for an inpatient visit
AND B.ip_ord_ind = 1
-- med_ord_ind = 1 means the order was for medication
AND B.med_ord_ind = 1
-- POEOrdNo is null means the order originated from Pharmacy so it is not a revision of a CPOE
AND A.POEOrdNo IS NULL
-- These NDC numbers represent communication orders NOT medication orders
AND A.NDC NOT IN (
	'99999-9999-22',
	'99999-9999-23',
	'99999-9999-24',
	'99999-9999-28',
	'99999-9999-37',
	'99999-9999-44',
	'99999-9999-47',
	'99999-9999-48',
	'99999-9999-50',
	'99999-9999-55',
	'99999-9999-57',
	'99999-9999-62',
	'99999-9999-88B',
	'99999-9999-90',
	'99999-9999-91',
	'99999-9999-91A',
	'99999-9999-92Y',
	'99999-9999-93',
	'99999-9999-94A',
	'99999-9999-95',
	'99999-9999-96',
	'99999-9999-97',
	'99999-9999-98'
)
-- excl_ord_for_CPOE_ind = 0 means that this order cannot be a CPOE type order example Per Protocol
AND B.excl_ord_for_CPOE_ind = 0
;

SELECT D.episode_no
, A.MedRecNo
, B.ord_obj_id
, A.POEOrdNo
, D.vst_type_cd
, D.pt_sts_cd
, D.hosp_svc
, B.req_pty_cd
, B.req_pty_name
, COALESCE(
	E.PRACT_RPT_NAME, 
	F.PRACT_RPT_NAME,
	G.PRACT_RPT_NAME, 
	H.PRACT_RPT_NAME,
	I.PRACT_RPT_NAME,
	J.PRACT_RPT_NAME,
	K.PRACT_RPT_NAME
) AS [PROVIDER_NAME]
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
	WHEN LEFT(B.REQ_PTY_CD, 1) = '9' 
		THEN 'PA / NP'
		ELSE 'Private'
  END AS [Hospitalist_NP_PA_Flag]
, CAST(B.ent_date AS date) AS [Ent_Date]
, B.ent_dtime
, DATEPART(HOUR, B.ENT_DTIME) AS [Ord_Ent_Hr]
, CASE
	WHEN DATEPART(WEEKDAY, B.ent_date) = 1 THEN 'SUNDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 2 THEN 'MONDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 3 THEN 'TUESDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 4 THEN 'WEDNESDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 5 THEN 'THURSDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 6 THEN 'FRIDAY'
	WHEN DATEPART(WEEKDAY, B.ent_date) = 7 THEN 'SATURDAY'
  END AS [DOW_Name]
, DATEPART(WEEKDAY, B.ent_date) AS [Ord_Ent_DOW]
, DATEPART(WEEK, B.ENT_DATE) AS [Ord_Ent_Wk]
, DATEPART(MONTH, B.ent_date) AS [Ord_Ent_Mo]
, DATEPART(QUARTER, B.ent_date) AS [Ord_Ent_Qtr]
, DATEPART(YEAR, B.ent_date) AS [Ord_Ent_Yr]
, B.ord_no
, CASE
	WHEN COALESCE(B.lab_ord_CPOE_ind, B.med_ord_CPOE_ind, B.rad_ord_CPOE_ind) = 1
		THEN 'CPOE'
		ELSE B.ord_src_modf_name
  END AS [CPOE_Flag]
, B.ord_src_modf_name
, B.med_ord_name_modf
, B.ord_type_abbr
, B.ord_sub_type_abbr
, B.phys_ent_ind
, B.cre_user_name

INTO #MED_ORDERSB

FROM smsmir.PHM_Ord AS A
LEFT OUTER JOIN smsdss.QOC_Ord_v AS B
ON A.AncilOrdNo = B.ord_obj_id
LEFT OUTER JOIN smsdss.QOC_vst_summ_v AS D
ON B.pref_vst_pms_id_col = D.pref_vst_pms_id_col
LEFT JOIN smsdss.pract_dim_v AS E
ON B.Req_Pty_Cd = E.src_pract_no
	AND E.orgz_cd = 'S0X0'
LEFT JOIN smsdss.pract_dim_v AS F
ON B.Req_Pty_Cd = F.src_pract_no
	AND F.orgz_cd = 'NTX0'
LEFT JOIN smsdss.pract_dim_v AS G
ON B.Req_Pty_Cd = G.src_pract_no
	AND G.orgz_cd = 'XNT'
LEFT JOIN smsdss.pract_dim_v AS H
ON B.Req_Pty_Cd = H.src_pract_no
	AND H.orgz_cd = '0002'
LEFT JOIN smsmir.pract_mstr  AS I
ON B.Req_Pty_Cd = I.pract_no
	AND I.iss_orgz_cd = '0002'
LEFT JOIN smsmir.pract_mstr  AS J
ON B.Req_Pty_Cd = J.pract_no
	AND J.iss_orgz_cd = 'NTX0'
LEFT JOIN smsmir.pract_mstr  AS K
ON B.Req_Pty_Cd = K.pract_no
	AND K.iss_orgz_cd = 'S0X0'

WHERE B.ent_date >= @START
AND B.ent_date < @END
AND B.phys_req_ind = 1
-- get inpatient visitis only
AND B.ip_ord_ind = 1
-- get medication orders only
AND B.med_ord_ind = 1
-- POEOrdNo is null means the order originated from Pharmacy so it is not a revision of a CPOE
AND A.POEOrdNo IS NOT NULL
AND A.NDC NOT IN (
	'99999-9999-22',
	'99999-9999-23',
	'99999-9999-24',
	'99999-9999-28',
	'99999-9999-37',
	'99999-9999-44',
	'99999-9999-47',
	'99999-9999-48',
	'99999-9999-50',
	'99999-9999-55',
	'99999-9999-57',
	'99999-9999-62',
	'99999-9999-88B',
	'99999-9999-90',
	'99999-9999-91',
	'99999-9999-91A',
	'99999-9999-92Y',
	'99999-9999-93',
	'99999-9999-94A',
	'99999-9999-95',
	'99999-9999-96',
	'99999-9999-97',
	'99999-9999-98'
)
-- we only want orders that are qualified for CPOE
AND B.excl_ord_for_CPOE_ind = 0
;

SELECT A.*
-- this was done in order to exclude duplicative rows in the data set
, RN = ROW_NUMBER() OVER(
       PARTITION BY Medrecno--A.EPISODENO
       , ORD_OBJ_ID
       , poeordno

       ORDER BY Medrecno -- A.EPISODENO
       , ORD_OBJ_ID
       , poeordno
)
INTO #TEMPC
FROM (
       SELECT *
       FROM #MED_ORDERSA
       UNION
       SELECT *
       FROM #MED_ORDERSB
) A
;

SELECT C.episode_no
, C.vst_type_cd
, C.pt_sts_cd
, C.hosp_svc
, C.req_pty_cd
, C.PROVIDER_NAME
, C.spclty_cd
, CASE
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'IM' THEN 'Internal Medicine'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'SG' THEN 'Surgery'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'FP' THEN 'Family Practice'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'OB' THEN 'Ob/Gyn'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'PE' THEN 'Pediatrics'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'PS' THEN 'Pyschiatry'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'DT' THEN 'Dentistry'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'AN' THEN 'Anesthesiology'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'RD' THEN 'Radiology'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'IP' THEN 'Internal Medicine/Pediatrics'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'ME' THEN 'Medical Education'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'ED' THEN 'Emergency Department'
	WHEN RIGHT(C.SPCLTY_CD, 2) = 'AH' THEN 'Allied Health Professional'
	ELSE ''
  END AS SPCLTY_DESC
, C.Hospitalist_NP_PA_Flag
, C.Ent_Date
, C.ent_dtime
, C.Ord_Ent_Hr
, C.DOW_Name
, C.Ord_Ent_DOW
, C.Ord_Ent_Wk
, C.Ord_Ent_Mo
, C.Ord_Ent_Qtr
, C.Ord_Ent_Yr
, C.ord_no
, C.CPOE_Flag
, C.ord_src_modf_name
, C.med_ord_name_modf
, C.ord_type_abbr
, C.ord_sub_type_abbr
, C.phys_ent_ind
, C.cre_user_name

INTO #MED_ORDERS

FROM #TEMPC AS C
WHERE C.RN = 1
;

SELECT ALLORDERS.*

INTO #ALLORDERS

FROM (
	SELECT MEDS.*
	FROM #MED_ORDERS AS MEDS
	UNION
	SELECT NON_MEDS.*
	FROM #NON_MED_ORDERS AS NON_MEDS
) AS ALLORDERS
;

SELECT *
FROM #ALLORDERS
ORDER BY CPOE_Flag
;

DROP TABLE #TEMPA, #TEMPC, #NON_MED_ORDERS, #MED_ORDERSA, #MED_ORDERSB, #MED_ORDERS, #ALLORDERS
GO
;