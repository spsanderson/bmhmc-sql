select med_rec_no
, PtNo_Num
, unit_seq_no
, Adm_Date
, Dsch_Date
, hosp_svc
, Plm_Pt_Acct_Type
, pt_type

from smsdss.BMH_PLM_PtAcct_V

where DATEPART(year, adm_date) = '2016'
and (
	(
		hosp_svc = 'amb'
		and
		pt_type in ('g', 'd')
	)
	or (
		hosp_svc = 'sur'
		and
		Plm_Pt_Acct_Type = 'o'
	)
	or (
		hosp_svc = 'd23'
		and
		pt_type = 'd'
	)
	or (
		hosp_svc = 'eor'
	)
)
and tot_chg_amt > 0
order by Adm_Date
;

-----

select a.*
, b.Pt_Age
, clinical.facility_account_no
, case
	when LEFT(b.dsch_disp, 1) in ('c', 'd')
		then '1'
		else '0'
  end as mortality_flag

from smsdss.BMH_PLM_PtAcct_Clasf_Proc_V_New as a
left join smsdss.BMH_PLM_PtAcct_V as b
on a.pt_no  = b.Pt_No
	and a.Pt_Key = b.Pt_Key
	and a.Bl_Unit_Key = b.Bl_Unit_Key
inner join [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS CLINICAL
on SUBSTRING(a.Pt_No, 5, 8) = clinical.facility_account_no COLLATE SQL_Latin1_General_CP1_CI_AS

where (
	(a.ClasfCd between '10021' and '10022')
	or
	(a.ClasfCd between '10030' and '19499')
	or
	(a.ClasfCd between '20000' and '29999')
	or
	(a.ClasfCd between '30000' and '32999')
	or
	(a.ClasfCd between '33010' and '37799')
	or
	(a.ClasfCd between '38100' and '38999')
	or
	(a.ClasfCd between '39000' and '39599')
	or
	(a.ClasfCd between '40490' and '49999')
	or
	(a.ClasfCd between '50010' and '53899')
	or
	(a.ClasfCd between '54000' and '55899')
	or
	(a.ClasfCd between '55920' and '55980')
	or
	(a.ClasfCd between '56405' and '58999')
	or
	(a.ClasfCd between '59000' and '59899')
	or
	(a.ClasfCd between '60000' and '60699')
	or
	(a.ClasfCd between '61000' and '64999')
	or
	(a.ClasfCd between '65091' and '68899')
	or
	(a.ClasfCd between '69000' and '69979')
	or
	(a.ClasfCd = '69990')
)
and a.Clasf_Eff_Date >= '2016-01-01'
and a.Clasf_Eff_Date < '2017-01-01'
and a.ClasfPrio = '01'
--and a.ClasfType = 'pch'
and b.Plm_Pt_Acct_Type = 'o'
and a.ClasfCd not in (
	'16020', '16025', '16030', '29581', '36600', '36416','36415'
)
and b.Pt_Age >= 18

option(force order)