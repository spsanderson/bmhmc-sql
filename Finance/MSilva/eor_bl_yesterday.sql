DECLARE @TODAY AS DATE;
DECLARE @YESTERDAY AS DATE;

SET @TODAY = GETDATE();
SET @YESTERDAY = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY) - 1, 0)

SELECT A.Med_Rec_No
, A.PtNo_Num
, A.Pt_Name
, CAST(A.Adm_Date AS date) AS [Adm_Date]
, CAST(A.Dsch_Date AS date) AS [Dsch_Date]
, A.Pyr1_Co_Plan_Cd

FROM smsdss.BMH_PLM_PtAcct_V AS A

WHERE A.hosp_svc = 'EOR'
AND A.Pt_No IN (
	SELECT ZZZ.pt_id
	FROM smsmir.pyr_plan AS ZZZ
	WHERE ZZZ.last_bl_date >= @YESTERDAY
)
AND A.fc IN (
	'I','K','X','B','M'
)

ORDER BY A.Pyr1_Co_Plan_Cd
;