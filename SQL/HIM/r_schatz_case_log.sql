select c.Med_Rec_No
, c.PtNo_Num
, a.Clasf_Eff_Date
, a.ClasfCd
, b.alt_clasf_desc
, a.RespParty

from smsdss.BMH_PLM_PtAcct_Clasf_Proc_V_New as a
left join smsdss.proc_dim_v as b
on a.ClasfCd = b.proc_cd
and a.Proc_Cd_Schm = b.proc_cd_schm
left join smsdss.BMH_PLM_PtAcct_V as c
on a.pt_no = c.Pt_No
and a.Bl_Unit_Key = c.Bl_Unit_Key

where RespParty IN (
	'009720'
)
and Clasf_Eff_Date >= '2015-01-01'
and Clasf_Eff_Date < '2017-09-27'
and ClasfType != 'c'
and ClasfPrio = '01'

order by a.RespParty, c.Med_Rec_No, c.PtNo_Num

option(force order);