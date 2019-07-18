/*
This query is for Medication Orders - CPOE

v1	- 2018-06-08	- Create initial medication order cpoe query for leapfrog survey
v2	- 2018-06-27	- Add pract_dim_v and pract_mstr to get provider entery specialty
*/

SELECT EpisodeNo
, MedRecNo
, POEOrdNo
, AncilOrdNo
, B.ord_obj_id
, B.ord_no
, PrimName
, GnrcName
, b.med_ord_name_modf
, b.ent_dtime
, b.ent_name
, b.req_pty_name
, B.req_pty_cd
, B.ord_src_modf_name
, B.med_ord_CPOE_ind

INTO #TEMPA

FROM smsmir.PHM_Ord AS A
LEFT OUTER JOIN smsdss.QOC_Ord_v AS B
ON A.AncilOrdNo = B.ord_obj_id
LEFT OUTER JOIN smsdss.QOC_vst_summ_v AS D
ON B.pref_vst_pms_id_col = D.pref_vst_pms_id_col

WHERE B.ent_date >= '2018-03-01'
AND B.ent_date < '2018-06-01'
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
-- This goes from pharmacy to dss to get the encounter number to only take orders from pharmacy if multiple orders in 
-- soarian exist
SELECT EpisodeNo
, MedRecNo
, POEOrdNo
, AncilOrdNo
, B.ord_obj_id
, B.ord_no
, PrimName
, GnrcName
, b.med_ord_name_modf
, b.ent_dtime
, b.ent_name
, b.req_pty_name
, B.req_pty_cd
, B.ord_src_modf_name
, B.med_ord_CPOE_ind

INTO #TEMPB

FROM smsmir.PHM_Ord AS A
LEFT OUTER JOIN smsdss.QOC_Ord_v AS B
ON A.POEOrdNo = B.ord_obj_id
LEFT OUTER JOIN smsdss.QOC_vst_summ_v AS D
ON B.pref_vst_pms_id_col = D.pref_vst_pms_id_col

WHERE B.ent_date >= '2018-03-01'
AND B.ent_date < '2018-06-01'
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
       PARTITION BY A.Medrecno--A.EPISODENO
       , ORD_OBJ_ID
       , poeordno

       ORDER BY A.Medrecno -- A.EPISODENO
       , ORD_OBJ_ID
       , poeordno
)
INTO #TEMPC
FROM (
       SELECT *
       FROM #TEMPA
       UNION
       SELECT *
       FROM #TEMPB
) A
;

SELECT A.*
, COALESCE(
	E.src_spclty_cd,
	F.SRC_SPCLTY_CD,
	G.SRC_SPCLTY_CD,
	H.SRC_SPCLTY_CD, 
	I.SPCLTY_CD1,
	J.SPCLTY_CD1,
	K.SPCLTY_CD1
) AS [Spclty_Cd]

FROM #TEMPC AS A
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

-- RN=1 excludes the duplicate rows from above
WHERE A.RN = 1
;

DROP TABLE #TEMPA, #TEMPB, #TEMPC
;
