SELECT PAV.PtNo_Num
, PAV.Pt_Name
, PDV.pract_rpt_name

FROM smsdss.BMH_PLM_PtAcct_V PAV
JOIN smsdss.pract_dim_v PDV
ON PAV.Atn_Dr_No = PDV.src_pract_no

WHERE PDV.orgz_cd = 'S0X0'
AND PAV.Adm_Date >= '2013-05-01'
AND PAV.Adm_Date < '2014-04-30'
AND PDV.pract_rpt_name LIKE '%%'
AND PAV.Plm_Pt_Acct_Type = 'I'
AND PAV.PtNo_Num < '20000000'
