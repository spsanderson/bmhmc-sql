select a.Pyr1_Co_Plan_Cd as [Payor Code]
, b.pyr_group2
, count(a.PtNo_Num) as [# Admits]

from smsdss.BMH_PLM_PtAcct_V as a
left join smsdss.pyr_dim_v as b
on a.Pyr1_Co_Plan_Cd = b.src_pyr_cd
	and b.orgz_cd = a.Regn_Hosp

where a.tot_chg_amt > 0
and a.Dsch_Date >= '2016-01-01'
and a.Dsch_Date < '2016-11-01'
and left(a.PtNo_Num, 4) != '1999'
and a.Plm_Pt_Acct_Type = 'I'
and a.PtNo_Num < '20000000'
and a.Pyr1_Co_Plan_Cd not in (
	'*', 'c05', 'n09', 'n10'
)
and left(a.Pyr1_Co_Plan_Cd, 1) not in ('a', 'w')

group by b.pyr_group2, a.Pyr1_Co_Plan_Cd