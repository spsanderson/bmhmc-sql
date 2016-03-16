-- GET THE DX
DECLARE @DX TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter           INT
	, Diagnosis           VARCHAR(500)
	, RN                  INT
);

WITH DX AS (
	SELECT b.episode_no
	, b.desc_as_written
	, ROW_NUMBER() OVER(
		PARTITION BY b.episode_no
		ORDER BY b.ent_dtime
	) AS RN

	FROM smsdss.c_sr_orders_finance_rpt_v AS B
	INNER JOIN smsmir.hl7_vst             AS A
	ON a.pt_id = b.episode_no
		AND a.pt_sts_cd = 'ia'

	WHERE b.svc_desc = 'Diagnosis'
	AND Order_Status <> 'Discontinue'
	AND ovrd_dup_ind <> '1'
)

INSERT INTO @DX
SELECT * FROM DX
WHERE DX.RN = 1

-- PULL IT TOGETHER
SELECT A.pt_id
, F.Pt_Name
, B.nurse_sta
, B.bed
, CAST(F.Days_Stay AS INT) AS LOS
, F.Pt_Age                 AS Age_At_Admit
, D.pt_med_rec_no
, B.adm_dtime
, A.hosp_svc
, B.adm_type
, A.pt_type
, A.fc
, A.atn_pract_no
, C.pract_rpt_name
, C.src_spclty_cd
, C.spclty_desc
, E.Diagnosis
, F.User_Pyr1_Cat
, CASE
	WHEN LEFT(F.Pyr1_Co_Plan_Cd, 1) IN ('A','Z')
		THEN 'Medicare'
	WHEN LEFT(F.Pyr1_Co_Plan_Cd, 1) = 'B'
		THEN 'Blue Cross'
	WHEN LEFT(F.Pyr1_Co_Plan_Cd, 1) = 'C'
		THEN 'Workers Comp'
	WHEN LEFT(F.Pyr1_Co_Plan_Cd, 1) = 'E'
		THEN 'Medicare HMO'
	WHEN LEFT(F.Pyr1_Co_Plan_Cd, 1) = 'I'
		THEN 'Medicaid HMO'
	WHEN LEFT(F.Pyr1_Co_Plan_Cd, 1) = 'K'
		THEN 'HMO'
	WHEN LEFT(F.Pyr1_Co_Plan_Cd, 1) = 'M'
		THEN 'Champus'
	WHEN LEFT(F.Pyr1_Co_Plan_Cd, 1) = 'N'
		THEN 'No Fault'
	WHEN LEFT(F.Pyr1_Co_Plan_Cd, 1) = '*'
		THEN 'Self Pay'
	WHEN LEFT(F.Pyr1_Co_Plan_Cd, 1) = 'W'
		THEN 'Medicaid'
	WHEN LEFT(F.Pyr1_Co_Plan_Cd, 1) IN ('X', 'J')
		THEN 'Commercial'
  END AS [Payor 1]
, F.Pyr1_Co_Plan_Cd
, CASE
	WHEN LEFT(F.Pyr2_Co_Plan_Cd, 1) IN ('A','Z')
		THEN 'Medicare'
	WHEN LEFT(F.Pyr2_Co_Plan_Cd, 1) = 'B'
		THEN 'Blue Cross'
	WHEN LEFT(F.Pyr2_Co_Plan_Cd, 1) = 'C'
		THEN 'Workers Comp'
	WHEN LEFT(F.Pyr2_Co_Plan_Cd, 1) = 'E'
		THEN 'Medicare HMO'
	WHEN LEFT(F.Pyr2_Co_Plan_Cd, 1) = 'I'
		THEN 'Medicaid HMO'
	WHEN LEFT(F.Pyr2_Co_Plan_Cd, 1) = 'K'
		THEN 'HMO'
	WHEN LEFT(F.Pyr2_Co_Plan_Cd, 1) = 'M'
		THEN 'Champus'
	WHEN LEFT(F.Pyr2_Co_Plan_Cd, 1) = 'N'
		THEN 'No Fault'
	WHEN LEFT(F.Pyr2_Co_Plan_Cd, 1) = '*'
		THEN 'Self Pay'
	WHEN LEFT(F.Pyr2_Co_Plan_Cd, 1) = 'W'
		THEN 'Medicaid'
	WHEN LEFT(F.Pyr2_Co_Plan_Cd, 1) IN ('X', 'J')
		THEN 'Commercial'
  END AS [Payor 2]
, F.Pyr2_Co_Plan_Cd
, G.UserDataText

FROM smsmir.hl7_vst                      AS A
LEFT OUTER JOIN smsmir.hl7_vst           AS B
ON A.pt_id = B.pt_id
	AND A.pt_class = B.pt_class
	AND A.pt_sts_cd = B.pt_sts_cd
LEFT OUTER JOIN smsdss.pract_dim_v       AS C
ON A.atn_pract_no = C.src_pract_no
	AND C.orgz_cd = 'S0X0'
LEFT OUTER JOIN smsmir.hl7_pt            AS D
ON a.pt_id = d.pt_id
LEFT OUTER JOIN @DX                      AS E
ON A.pt_id = E.Encounter
LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V  AS F
ON A.PT_ID = F.PtNo_Num
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V AS G
ON A.pt_id = G.PtNo_Num
	AND G.UserDataKey = 25

WHERE A.pt_sts_cd = 'IA'
AND A.dsch_dtime IS NULL