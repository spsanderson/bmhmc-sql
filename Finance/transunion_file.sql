declare @adm_dx table (
	pk int identity(1, 1) PRIMARY KEY
	, Encounter           VARCHAR(12)
	, Dx_Cd               VARCHAR(12)
	, Dx_Cd_Schm          VARCHAR(MAX)
	, RN                  INT
);

with cte1 as (
	select a.PtNo_Num
	, b.ClasfCd
	, b.ClasfSch
	, ROW_NUMBER() over(
		PARTITION by a.ptno_num
		order by b.clasfcd
	) as rn
	
	from smsdss.BMH_PLM_PtAcct_V as a
	left join smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as b
	on a.PtNo_Num = b.PtNo_Num
		and a.Bl_Unit_Key = b.Bl_Unit_Key
		and a.Pt_Key = b.Pt_Key
	
	where b.ClasfType = 'da'
	and b.ClasfPrio = '01'
	and a.Dsch_Date >= '2015-01-01'
	and a.Dsch_Date <= '2016-01-01'
	--and b.User_Pyr1_Cat in ('www', 'iii')
	--and a.Plm_Pt_Acct_Type = 'i'
	--and a.PtNo_Num < '20000000'
	--and LEFT(a.ptno_num, 1) in ('7')
)

insert into @adm_dx
select * from cte1 where rn = 1

--select * from @adm_dx;

select a.Med_Rec_No
, a.PtNo_Num
, a.Regn_Hosp
, a.Pt_Name
, a.Pt_Birthdate
, a.Pt_SSA_No
, a.Pt_Sex
, a.Pt_Marital_Sts
, cast(a.Adm_Date as DATE) as adm_date
, cast(RIGHT(a.vst_start_dtime, 12) as time) as adm_time
, a.Dsch_Date
, a.tot_chg_amt
, a.Tot_Amt_Due
, a.fc
, '' as [blank]
, a.hosp_svc
, a.Adm_Source
, a.pt_type
, a.acc_type
, a.Pyr1_Co_Plan_Cd
, case
	when LEFT(c.pyr_cd, 1) in ('a','z')
		then c.pol_no + ISNULL(ltrim(rtrim(c.grp_no)),'')
	when c.pol_no is null
		then c.subscr_ins_grp_id
	else c.pol_no
  end as [ins1 plan no]
, a.Pyr2_Co_Plan_Cd
, case
	when LEFT(d.pyr_cd, 1) in ('a','z')
		then d.pol_no + ISNULL(ltrim(rtrim(d.grp_no)),'')
	when d.pol_no is null
		then d.subscr_ins_grp_id
	else d.pol_no
  end as [ins2 plan no]
, a.Pyr3_Co_Plan_Cd
, case
	when LEFT(e.pyr_cd, 1) in ('a','z')
		then e.pol_no + ISNULL(ltrim(rtrim(e.grp_no)),'')
	when e.pol_no is null
		then e.subscr_ins_grp_id
	else e.pol_no
  end as [ins3 plan no]
, f.resp_cd
, g.Dx_Cd as [adm_dx_cd]
, j.clasf_desc as [adm_dx_desc]
, a.prin_dx_cd
, h.clasf_desc as [prin_dx_desc]
, a.proc_cd
, i.clasf_desc
, k.pract_rpt_name as [attending_md]
, l.GuarantorLast
, l.GuarantorFirst
, l.GuarantorSocial
, l.GuarantorAddress
, l.GuarantoAddress2
, l.GurantorCity
, l.GuarantorState
, l.GuarantorZip
, l.GuarantorPhone
, m.Pt_Employer
, m.Pt_Emp_Addr1
, m.Pt_Emp_Addr2
, m.Pt_Emp_Addr_City
, m.Pt_Emp_Addr_State
, m.Pt_Emp_Addr_Zip
, n.addr_line1
, n.Pt_Addr_Line2
, n.Pt_Addr_City
, n.Pt_Addr_State
, n.Pt_Addr_Zip
, n.Pt_Phone_No
, ROW_NUMBER() over(
	partition by a.ptno_num
	order by a.ptno_num
) as rn

into #tmp_transunion

from smsdss.BMH_PLM_PtAcct_V as a
left merge join smsdss.c_guarantor_demos_v as b
on a.Pt_No = b.pt_id
left merge join smsmir.mir_pyr_plan as c
on a.Pt_No = c.pt_id
	and c.pyr_seq_no = '1'
	and a.Pyr1_Co_Plan_Cd = c.pyr_cd
left merge join smsmir.mir_pyr_plan as d
on a.Pt_No = d.pt_id
	and d.pyr_seq_no = '2'
	and a.Pyr2_Co_Plan_Cd = c.pyr_cd
left merge join smsmir.mir_pyr_plan as e
on a.Pt_No = e.pt_id
	and e.pyr_seq_no = '3'
	and a.Pyr3_Co_Plan_Cd = c.pyr_cd
left merge join smsmir.mir_acct as f
on a.Pt_No = f.pt_id
left merge join @adm_dx as g
on a.PtNo_Num = g.Encounter
left merge join smsdss.dx_cd_dim_v as h
on a.prin_dx_cd = h.dx_cd
	and a.prin_dx_cd_schm = h.dx_cd_schm
left merge join smsdss.proc_dim_v as i
on a.proc_cd = i.proc_cd
left merge join smsdss.dx_cd_dim_v as j
on g.Dx_Cd = j.dx_cd
	and g.Dx_Cd_Schm = j.dx_cd_schm
left merge join smsdss.pract_dim_v as k
on a.Atn_Dr_No = k.src_pract_no
	and k.orgz_cd = 's0x0'
left merge join smsdss.c_guarantor_demos_v as l
on a.Pt_No = l.pt_id
left merge join smsdss.c_patient_employer_demos_v as m
on a.Pt_No = m.pt_id
left merge join smsdss.c_patient_demos_v as n
on a.Pt_No = n.pt_id

where a.Dsch_Date >= '2015-01-01'
and a.Dsch_Date <= '2016-01-01'
--and a.User_Pyr1_Cat in ('www', 'iii')
--and a.Plm_Pt_Acct_Type = 'i'
--and a.PtNo_Num < '20000000'
--and LEFT(a.ptno_num, 1) in ('7')
and a.Pt_Name <> 'OUTPATIENT ,TEST'

select *
from #tmp_transunion as a
where a.rn = 1

drop table #tmp_transunion