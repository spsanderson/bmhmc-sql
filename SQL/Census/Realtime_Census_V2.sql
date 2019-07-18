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

-- GET THE REAL TIME INSURANCE IN CASE WE GET A NULL for position 1
DECLARE @RealTimeIns TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY NOT NULL
	, Encounter INT
	, Ins_Plan_No CHAR(3)
	, RN INT
);

WITH RTINSTBL AS (
	SELECT A.PT_ID
	--, A.TIMESTAMP
	--, A.LAST_MSG_CNTRL_ID
	, A.INS_PLAN_NO
	--, B.msg_dtime
	, ROW_NUMBER() OVER(
		PARTITION BY a.pt_id
		ORDER BY b.msg_dtime DESC
	) AS RN

	FROM SMSMIR.HL7_INS           AS A
	INNER JOIN SMSMIR.HL7_MSG_HDR AS B
	ON A.LAST_MSG_CNTRL_ID = B.MSG_CNTRL_ID
		AND a.pt_id = b.pt_id

	WHERE INS_PLAN_PRIO_NO = 1
)

INSERT INTO @RealTimeIns
SELECT *
FROM RTINSTBL
WHERE RTINSTBL.RN = 1

--SELECT * 
--FROM @RealTimeIns R
--WHERE R.RN = 1

-- get real time insurance if regular is null for position 2
DECLARE @RealTimeIns2 TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY NOT NULL
	, Encounter INT
	, Ins_Plan_No CHAR(3)
	, RN INT
);

WITH RTINSTBL2 AS (
	SELECT A.PT_ID
	--, A.TIMESTAMP
	--, A.LAST_MSG_CNTRL_ID
	, A.INS_PLAN_NO
	--, B.msg_dtime
	, ROW_NUMBER() OVER(
		PARTITION BY a.pt_id
		ORDER BY b.msg_dtime DESC
	) AS RN

	FROM SMSMIR.HL7_INS           AS A
	INNER JOIN SMSMIR.HL7_MSG_HDR AS B
	ON A.LAST_MSG_CNTRL_ID = B.MSG_CNTRL_ID
		AND a.pt_id = b.pt_id

	WHERE INS_PLAN_PRIO_NO = 2
)

INSERT INTO @RealTimeIns2
SELECT *
FROM RTINSTBL2
WHERE RTINSTBL2.RN = 1

--SELECT * 
--FROM @RealTimeIns2 R2
--WHERE R2.RN = 1

-- PULL IT TOGETHER ---------------------------------------------------
SELECT A.pt_id
, (D.pt_last_name + ', ' + D.pt_first_name) as Pt_Name_B
, B.nurse_sta
, B.bed
, CASE
	WHEN F.DAYS_STAY IS NOT NULL
		THEN CAST(F.Days_Stay AS INT)
	WHEN F.Days_Stay IS NULL
		THEN DATEDIFF(DAY,B.adm_date, GETDATE())
  END                      AS LOS
, CASE 
	WHEN F.Pt_Age IS NULL
		THEN DATEDIFF(YEAR, D.pt_birth_date, B.adm_date)
	ELSE
		F.Pt_Age
  END                     AS Age_At_Admit
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
	WHEN LEFT(H.Ins_Plan_No, 1) IN ('A','Z')
		THEN 'Medicare'
	WHEN LEFT(H.Ins_Plan_No, 1) = 'B'
		THEN 'Blue Cross'
	WHEN LEFT(H.Ins_Plan_No, 1) = 'C'
		THEN 'Workers Comp'
	WHEN LEFT(H.Ins_Plan_No, 1) = 'E'
		THEN 'Medicare HMO'
	WHEN LEFT(H.Ins_Plan_No, 1) = 'I'
		THEN 'Medicaid HMO'
	WHEN LEFT(H.Ins_Plan_No, 1) = 'K'
		THEN 'HMO'
	WHEN LEFT(H.Ins_Plan_No, 1) = 'M'
		THEN 'Champus'
	WHEN LEFT(H.Ins_Plan_No, 1) = 'N'
		THEN 'No Fault'
	WHEN LEFT(H.Ins_Plan_No, 1) = '*'
		THEN 'Self Pay'
	WHEN LEFT(H.Ins_Plan_No, 1) = 'W'
		THEN 'Medicaid'
	WHEN LEFT(H.Ins_Plan_No, 1) IN ('X', 'J')
		THEN 'Commercial'
  END AS [Payor 1 RealTime]
, H.Ins_Plan_No AS [RealTime Ins Plan Cd]
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
, CASE
	WHEN LEFT(I.Ins_Plan_No, 1) IN ('A','Z')
		THEN 'Medicare'
	WHEN LEFT(I.Ins_Plan_No, 1) = 'B'
		THEN 'Blue Cross'
	WHEN LEFT(I.Ins_Plan_No, 1) = 'C'
		THEN 'Workers Comp'
	WHEN LEFT(I.Ins_Plan_No, 1) = 'E'
		THEN 'Medicare HMO'
	WHEN LEFT(I.Ins_Plan_No, 1) = 'I'
		THEN 'Medicaid HMO'
	WHEN LEFT(I.Ins_Plan_No, 1) = 'K'
		THEN 'HMO'
	WHEN LEFT(I.Ins_Plan_No, 1) = 'M'
		THEN 'Champus'
	WHEN LEFT(I.Ins_Plan_No, 1) = 'N'
		THEN 'No Fault'
	WHEN LEFT(I.Ins_Plan_No, 1) = '*'
		THEN 'Self Pay'
	WHEN LEFT(I.Ins_Plan_No, 1) = 'W'
		THEN 'Medicaid'
	WHEN LEFT(I.Ins_Plan_No, 1) IN ('X', 'J')
		THEN 'Commercial'
  END AS [Payor 2 RealTime]
, I.Ins_Plan_No AS [RealTime Ins Plan Cd 2]
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
LEFT OUTER JOIN @RealTimeIns             AS H
ON A.pt_id = H.Encounter
LEFT OUTER JOIN @RealTimeIns2            AS I
ON A.pt_id = I.Encounter

WHERE A.pt_sts_cd = 'IA'
AND A.dsch_dtime IS NULL

OPTION(FORCE ORDER);