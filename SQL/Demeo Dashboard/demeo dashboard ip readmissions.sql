select a.Med_Rec_No
, a.PtNo_Num
, cast(a.Adm_Date as DATE) as adm_date
, CAST(a.dsch_date as DATE) as dsch_date
, a.prin_dx_cd
, a.prin_dx_cd_schm
, b.[READMIT]
, b.[INTERIM]
--, c.LIHN_Service_Line
--, d.LIHN_Service_Line as v10
, coalesce(c.lihn_service_line, d.lihn_service_line) as LIHN_Service_Line

from smsdss.BMH_PLM_PtAcct_V as a
left join smsdss.vReadmits as b
on a.PtNo_Num = b.[INDEX]
    and b.[READMIT SOURCE DESC] != 'Scheduled Admission'
    and b.[INTERIM] < 31
left join smsdss.c_LIHN_Svc_Lines_Rpt2_v as c
on a.Pt_No = c.pt_id
    and a.prin_dx_cd_schm = c.icd_cd_schm
    and a.prin_dx_cd_schm = '9'
left join smsdss.c_LIHN_Svc_Lines_Rpt2_ICD10_v as d
on a.pt_no = d.pt_id
    and a.prin_dx_cd_schm = d.icd_cd_schm
    and a.prin_dx_cd_schm = '0'

where a.Dsch_Date >= '2015-11-01'
and a.Dsch_Date < '2016-01-01'
and a.Plm_Pt_Acct_Type = 'i'
and a.Atn_Dr_No != '000059'
and a.PtNo_Num < '20000000'
and LEFT(a.ptno_num, 4) != '1999'
and a.hosp_svc != 'psy'
