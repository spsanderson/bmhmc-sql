DECLARE @TODAY AS DATE;
DECLARE @YESTERDAY AS DATE;

SET @TODAY = GETDATE();
SET @YESTERDAY = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY) - 2, 0)

SELECT A.Med_Rec_No
, A.PtNo_Num
, A.Pt_Name
, CAST(A.Adm_Date AS date) AS [Adm_Date]
, CAST(A.Dsch_Date AS date) AS [Dsch_Date]
, A.Pyr1_Co_Plan_Cd
, B.last_bl_date
, B.pyr_cd
--, C.last_bl_date
--, C.pyr_cd
--, D.last_bl_date
--, D.pyr_cd
--, E.last_bl_date
--, E.pyr_cd

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsmir.pyr_plan as B
on A.Pt_No = B.pt_id
	AND A.Pyr1_Co_Plan_Cd = B.pyr_cd
	AND B.pyr_seq_no = 1
--LEFT OUTER JOIN smsmir.pyr_plan AS C
--ON A.Pt_No = C.pt_id
--	AND A.Pyr2_Co_Plan_Cd = C.pyr_cd
--	AND C.pyr_seq_no = 2
--LEFT OUTER JOIN smsmir.pyr_plan AS D
--ON A.Pt_No = D.pt_id
--	AND A.Pyr3_Co_Plan_Cd = D.pyr_cd
--	AND D.pyr_seq_no = 3
--LEFT OUTER JOIN smsmir.pyr_plan AS E
--ON A.Pt_No = E.pt_id
--	AND A.Pyr4_Co_Plan_Cd = E.pyr_cd
--	AND E.pyr_seq_no = 4

WHERE A.hosp_svc = 'EOR'
AND A.Pt_No IN (
	SELECT ZZZ.pt_id
	FROM smsmir.pyr_plan AS ZZZ
	WHERE ZZZ.last_bl_date >= @YESTERDAY
)
AND A.fc IN (
	'I','K','X','B','M'
)

ORDER BY A.Adm_Date
;