SELECT A.User_Pyr1_Cat
, A.PtNo_Num
, A.unit_seq_no
, A.Pyr1_Co_Plan_Cd
, A.Adm_Date
, A.pt_type
, A.hosp_svc
, b.Chg_Qty
, b.Tot_Chg_Amt
, A.tot_pay_amt
, A.tot_adj_amt
, A.Tot_Amt_Due

FROM smsdss.bmh_plm_ptacct_v as a 
inner join smsdss.BMH_PLM_PtAcct_Svc_V_Hold as b
ON a.Pt_Key = b.Pt_Key
	and a.Bl_Unit_Key = b.bl_unit_key

WHERE b.svc_date BETWEEN '01/01/17' and '12/31/17'
AND a.pt_type IN ('C')
AND b.svc_cd BETWEEN '05200001' and '05300025'

OPTION(FORCE ORDER)

GO
;