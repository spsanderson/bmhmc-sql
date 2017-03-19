SELECT a.Pt_no
, a.Pt_name
, a.DRG_no
, a.Days_Stay
, d.svc_cd
, d1.Pract_Rpt_Name AS DoctorName
, a.dsch_date
, d.svc_date
, d.PostDate
, x.Trans_Name
, a.pyr1_co_plan_cd
, d.tot_chg_amt
, a.tot_chg_amt
, a.tot_pay_amt
, a.tot_amt_due

FROM smsdss.BMH_plm_ptacct_V AS a 
INNER JOIN smsdss.BMH_plm_ptacct_svc_V_Hold AS d
ON a.pt_key = d.pt_key 
	AND a.bl_unit_key = d.bl_unit_key
INNER JOIN smsdss.trans_cd_dim_v as x
ON d.svc_cd = x.trans_cd 
INNER JOIN SMSDSS.PRACT_DIM_V as d1
ON A.Atn_DR_No = d1.PRACT_NO
	and a.Regn_Hosp = d1.orgz_cd    
	  
WHERE plm_pt_acct_type in ('I','O')
AND x.orgz_cd = 'S0X0'
AND d.PostDate >= '2017-02-01' 
AND d.PostDate < '2017-03-01'  -- always include first day of the next month    
AND d.svc_cd IN (
	'07260524','05700000','07260532','05700018','07241201','07241003',
	'07241300','07260573','07241151','07242001','07241102','07241409'
)
