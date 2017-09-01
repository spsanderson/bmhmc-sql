SELECT COUNT(a.pt_no) AS [Cases]
, MONTH(a.adm_Date)   AS [Svc_Month]
, YEAR(a.adm_Date)    AS [Svc_Year]
, a.Pt_No
, a.pt_type
, a.hosp_svc
,
--b.spclty_cd1,
c.spclty_cd_desc
, 
--a.hosp_svc,
a.atn_dr_no
, b.pract_rpt_name
, d.proc_Cd           AS [Prin_Proc_Cd]
, e.clasf_desc        AS [Prin_Proc_Cd_Desc]
, a.tot_Chg_Amt
, G.UserDataCd

FROM smsdss.bmh_plm_ptacct_v             AS a 
LEFT JOIN smsmir.mir_pract_mstr          AS b
ON a.atn_dr_no = b.pract_no 
	AND b.src_sys_id='#PASS0X0'
LEFT OUTER JOIN smsdss.pract_spclty_mstr AS c
ON b.spclty_cd1 = c.spclty_cd 
	AND c.src_sys_id = '#PMSNTX0'
LEFT OUTER JOIN smsmir.mir_sproc         AS d
ON a.Pt_No = d.pt_id 
	AND d.proc_cd_prio IN ('1','01') 
	AND proc_cd_type = 'PC'
LEFT OUTER JOIN smsmir.mir_clasf_mstr    AS e
ON d.proc_cd=e.clasf_cd
-- add in user two field of 571 for orsos case
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V AS F
ON A.PtNo_Num = F.PtNo_Num
	AND F.UserDataKey = '571'
LEFT OUTER JOIN smsdss.BMH_UserTwoField_Dim_V AS G
ON F.UserDataKey = G.UserTwoKey

WHERE (
	a.pt_type NOT IN ('D','G')
	AND hosp_svc NOT IN ('INF','CTH')
	--AND Atn_Dr_No = ''
	AND (
		Adm_Date >= '2015-01-01' 
		AND Adm_Date < '2016-01-01' 
		OR 
		Adm_Date >= '2016-01-01' 
		AND Adm_Date < '2016-06-01'
	)
	AND a.tot_chg_amt > '0'
	AND LEFT(a.pt_no,5) = '00001'
)
AND F.UserDataKey = '571'

GROUP BY MONTH(a.adm_Date)
, YEAR(a.adm_Date) 
, a.Pt_No
, a.pt_type
, a.hosp_svc
,
--b.spclty_cd1,
c.spclty_cd_desc
, 
--a.hosp_svc,
a.atn_dr_no
, b.pract_rpt_name
, d.proc_Cd 
, e.clasf_desc
, a.tot_Chg_Amt
, G.UserDataCd