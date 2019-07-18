SELECT a.PtNo_Num
, a.Med_Rec_No
, a.User_Pyr1_Cat
, a.Pyr1_Co_Plan_Cd
, a.Pyr2_Co_Plan_Cd
, a.Pyr3_Co_Plan_Cd
, a.Pyr4_Co_Plan_Cd
, a.dsch_disp
, so.ORd_no
, a.Dsch_DTime
, so.DATE
, so.TIME

FROM smsdss.bmh_plm_ptacct_v AS a
LEFT OUTER JOIN (
	SELECT B.episode_no
	, B.ORd_no
	, B.DATE
	, B.TIME

	FROM (
		SELECT EPISODE_NO
		, ORD_NO
		, CAST(ENT_DTIME AS DATE) AS [DATE]
		, CAST(ENT_DTIME AS TIME) AS [TIME]
		, ROW_NUMBER() OVER(
			PARTITION BY EPISODE_NO 
			ORDER BY ORD_NO DESC
		) AS ROWNUM
		
		FROM smsmir.sr_ORd
		
		WHERE svc_desc = 'DISCHARGE TO'
		AND episode_no < '20000000'
	) B

	WHERE B.ROWNUM = 1
) SO
ON a.ptno_num = so.episode_no

WHERE Plm_Pt_Acct_Type = 'I'
AND Dsch_Date >= '2016-01-011'
AND Dsch_Date < '2016-02-01'
AND (
	LEFT(a.Pyr1_Co_Plan_Cd, 1) IN ('a', 'e')
	OR
	LEFT(a.Pyr2_Co_Plan_Cd, 1) IN ('a', 'e')
)
