SELECT COUNT(DISTINCT(pt_no))
--Pt_No
, CASE
    WHEN User_Pyr1_Cat IN ('AAA','ZZZ') Then 'Medicare'
    WHEN User_Pyr1_Cat = 'WWW' Then 'Medicaid'
    ELSE 'Other'
  END as 'Payer Category'
, Atn_Dr_No
, b.pract_rpt_name
, MONTH(adm_date) as 'Adm_Mo'
, YEAR(adm_date) as 'Adm_Yr'

FROM smsdss.BMH_PLM_PtAcct_V a 
LEFT OUTER JOIN smsmir.mir_pract_mstr b
ON a.Atn_Dr_No = b.pract_no 
	AND b.src_sys_id='#PMSNTX0'

WHERE (
	Adm_Date >= '11/01/2015' AND Adm_Date < '12/01/2015' 
	OR 
	Adm_Date >= '11/01/2014' AND Adm_Date < '12/01/2014'
	)
AND tot_chg_amt > '0'
AND Plm_Pt_Acct_Type='I'
AND hosp_svc <> 'PSY'
AND a.PtNo_Num < '20000000'

GROUP BY user_pyr1_cat, Atn_Dr_No
, pract_rpt_name
, MONTH(Adm_Date)
, YEAR(adm_date)