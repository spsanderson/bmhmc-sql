DECLARE @INS_CD_NAME TABLE (
	PYR_CD           CHAR(3)
	, PYR_NAME       VARCHAR(100)
);

WITH CTE1 AS (
	SELECT pyr_cd
	, pyr_name

	FROM SMSMIR.pyr_mstr
)

INSERT INTO @INS_CD_NAME
SELECT * FROM CTE1
-----------------------------------------------------------------------

SELECT A.PtNo_Num
, A.Med_Rec_No
, A.Pt_SSA_No
, '' AS HIC
, CASE 
	WHEN LEFT(a.Pyr1_Co_Plan_Cd, 1) = 'W'
		THEN RTRIM(ISNULL(D.POL_NO, '')) + RTRIM(LTRIM(ISNULL(D.GRP_NO, '')))
		ELSE ''
  END AS MEDICAID_ID_Number
, B.pt_first
, B.pt_last
, B.pt_middle
, A.Pt_Birthdate
, A.Pt_Sex
, B.addr_line1
, B.Pt_Addr_Line2
, B.Pt_Addr_City
, B.Pt_Addr_State
, B.Pt_Phone_No
, A.Adm_Date
, C.Arrival         AS [ED ARRIVAL]
, A.Dsch_Date
, A.hosp_svc        AS [PT TYPE]
, ''                AS [Discharge Floor]
, ''                AS [UB Type of Bill Number]
, a.drg_no          AS [DRG Number]
, a.Days_Stay       AS [Length of Stay]
, a.Pyr1_Co_Plan_Cd AS [Primary Ins Code]
, INS1.PYR_NAME     AS [Primary Insurance Name]
, E.pol_no          AS [Primary Insurance Policy Number]
, a.Pyr2_Co_Plan_Cd AS [Secondary Ins Code]
, INS2.PYR_NAME     AS [Secondary Insurance Name]
, F.pol_no          AS [Secondary Insurance Policy Number]
, a.Pyr3_Co_Plan_Cd AS [Third Ins Code]
, INS3.PYR_NAME     AS [Third Insurance Name]
, G.pol_no          AS [Third Insurance Policy Number]
, a.Pyr4_Co_Plan_Cd AS [Fourth Ins Code]
, INS4.PYR_NAME     AS [Fourth Insurance Name]
, H.pol_no          AS [Fourth Insurance Policy Number]
, a.tot_chg_amt     AS [Total Charges]
, ISNULL(-(E.tot_pay_amt), 0)  AS [Primary Ins Payment Amount]
, ISNULL(-(F.tot_pay_amt), 0)  AS [Secondary Ins Payment Amount]
, ISNULL(-(G.tot_pay_amt), 0)  AS [Third Ins Payment Amount]
, ISNULL(-(H.tot_pay_amt), 0)  AS [Fourth Ins Payment Amount]
, ''                AS [Monther's Patient ID Number]
, ''                AS [Mother's Name]
, DDD.DISPO         AS [NUBC Standard Patient Discharge Status]


FROM smsdss.BMH_PLM_PtAcct_V        AS A
LEFT JOIN smsdss.c_patient_demos_v  AS B
ON A.Pt_No = B.pt_id
LEFT JOIN smsdss.c_Wellsoft_Rpt_tbl AS C
ON A.PtNo_Num = C.Account
LEFT JOIN smsmir.mir_pyr_plan       AS D
ON A.Pt_No = D.pt_id
	AND A.Pyr1_Co_Plan_Cd = D.pyr_cd
LEFT JOIN @INS_CD_NAME              AS INS1
ON A.Pyr1_Co_Plan_Cd = INS1.PYR_CD
LEFT JOIN SMSMIR.pyr_plan           AS E
ON A.Pyr1_Co_Plan_Cd = E.pyr_cd
	AND E.pyr_seq_no = 1
	AND E.pt_id = A.Pt_No
LEFT JOIN @INS_CD_NAME              AS INS2
ON A.Pyr2_Co_Plan_Cd = INS2.PYR_CD
LEFT JOIN SMSMIR.pyr_plan           AS F
ON A.Pyr2_Co_Plan_Cd = F.pyr_cd
	AND F.pyr_seq_no = 2
	AND F.pt_id = A.Pt_No
LEFT JOIN @INS_CD_NAME              AS INS3
ON A.Pyr3_Co_Plan_Cd = INS3.PYR_CD
LEFT JOIN SMSMIR.pyr_plan           AS G
ON A.Pyr3_Co_Plan_Cd = G.pyr_cd
	AND G.pyr_seq_no = 3
	AND G.pt_id = A.Pt_No
LEFT JOIN @INS_CD_NAME              AS INS4
ON A.Pyr4_Co_Plan_Cd = INS4.PYR_CD
LEFT JOIN SMSMIR.pyr_plan           AS H
ON A.Pyr4_Co_Plan_Cd = H.pyr_cd
	AND H.pyr_seq_no = 4
	AND H.pt_id = A.Pt_No

CROSS APPLY (
	SELECT
		CASE
			WHEN A.dsch_disp = 'ATW' THEN '06'
			WHEN A.dsch_disp = 'AHI' THEN '51'
			WHEN A.dsch_disp = 'AHR' THEN '01'
			WHEN A.dsch_disp = 'ATE' THEN '03'
			WHEN A.dsch_disp = 'ATL' THEN '03'
			WHEN A.dsch_disp = 'ATH' THEN '02'
			WHEN A.dsch_disp = 'ATP' THEN '65'
			WHEN A.dsch_disp = 'D7N' THEN '20'
			WHEN A.dsch_disp = 'D8N' THEN '20'
			WHEN A.dsch_disp = 'AMA' THEN '07'
			WHEN A.dsch_disp = 'ATF' THEN '43'
			WHEN A.dsch_disp = 'ATN' THEN '43'
			WHEN A.dsch_disp = 'ATB' THEN '21'
		END AS DISPO
) DDD

WHERE A.Dsch_Date >= '2015-01-01'
AND A.Dsch_Date < '2016-01-01'
AND A.Plm_Pt_Acct_Type = 'I'
AND A.PtNo_Num < '20000000'
AND LEFT(A.PTNO_NUM, 4) != '1999'
AND A.User_Pyr1_Cat IN ('AAA', 'ZZZ', 'WWW')
OPTION(FORCE ORDER)