SELECT A.Svc_Cd
, A.Svc_Date
, A.PostDate
, B.Pt_No
, B.Pt_Name
, B.Adm_Date
, ACCT.last_ins_bl_dtime
, A.Tot_Chg_Amt
, ACCT.unit_seq_no
, B.hosp_svc
, ACCT.fnl_bl_dtime
, ACCT.last_actl_pt_bl_dtime
, B.fc
, [Indicator] = (
	CASE
		WHEN (
			A.Tot_Chg_Amt > 0
			AND (
				DATEDIFF(d, a.svc_date, b.adm_date) > 1
				OR 
				DATEDIFF(d, a.svc_date, b.adm_date) < -1
				)
		)
			THEN 1
			ELSE 0
	END
)
, [Indicator_Credit] = (
	CASE
		WHEN (
			A.Tot_Chg_Amt < 0
			AND (
				DATEDIFF(d, a.svc_date, b.adm_date) > 1
				OR
				DATEDIFF(d, a.svc_date, b.adm_date) < -1
				)
		)
			THEN -1
			ELSE 0
	END 
)

INTO #tempa

FROM  smsdss.BMH_PLM_PtAcct_Svc_V_Hold as A
INNER JOIN smsdss.BMH_PLM_PtAcct_V as B
ON A.Pt_Key = B.Pt_Key
	AND A.Bl_Unit_key = B.Bl_Unit_Key
LEFT OUTER JOIN smsmir.mir_acct as acct 
ON B.Pt_No = acct.pt_id      

WHERE  b.Plm_Pt_Acct_Type = 'O' 
AND a.Tot_Chg_Amt <> 0 
AND datepart(year, B.Adm_Date) = datepart(year, GETDATE())
AND B.hosp_svc != 'OBV'
AND acct.unit_seq_no = 0
AND acct.last_actl_pt_bl_dtime IS NULL
AND acct.last_ins_bl_dtime IS NULL
AND a.svc_cd between '00300000' AND '00399999'
AND B.fc NOT IN (
	'1','2','3','4','5','6','7','8','9','j'
)

OPTION(FORCE ORDER)
;

-----

SELECT A.*
, [unaddressed] = (a.indicator + a.indicator_credit)

FROM #tempa as a

WHERE (a.indicator + a.indicator_credit) != 0

ORDER BY a.hosp_svc
, a.Pt_No
, a.Pt_Name
, a.Svc_Cd
;
-----

DROP TABLE #tempa
;