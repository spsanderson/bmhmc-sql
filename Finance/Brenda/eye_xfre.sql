declare @xfer_pts table (
	pk int not null identity(1, 1) primary key
	, MRN CHAR(6)
	, Encounter CHAR(8)
	, pt_no varchar(12)
	, Admt datetime
	, disch datetime
	, hsp_svc varchar(10)
	, atn_dr_cd char(6)
	, atn_dr varchar(100)
	, atn_spclty varchar(100)
	, dsch_cd varchar(300)
);

with cte as (
select a.Med_Rec_No
, a.episode_no
, a.Pt_No
, a.vst_start_dtime
, a.vst_end_dtime
, a.hosp_svc
, b.Atn_Dr_No
, c.pract_rpt_name
, c.spclty_desc
, a.dsch_disp

from smsmir.sr_vst_pms as a
left join smsdss.BMH_PLM_PtAcct_V as b
on a.episode_no = b.PtNo_Num
left join smsdss.pract_dim_v as c
on b.Atn_Dr_No = c.src_pract_no
	and c.orgz_cd = b.Regn_Hosp

where (
	a.dsch_disp like '%stony%'
	or
	b.dsch_disp = 'ath'	
)
and b.Dsch_Date >= '2016-01-01'
and b.Dsch_Date < '2016-11-01'
)

insert into @xfer_pts
select * from cte;

--select * from @xfer_pts;
-----------------------------------------------------------------------
-- get all patients who had a consult by a ophlamologist
declare @consults table (
	pk int not null identity(1, 1) primary key
	, pt_no varchar(12)
	, provider_cd varchar(6)
	, provider varchar(75)
	, provider_specialty varchar(100)
);

with cte as (
select a.pt_no
, b.RespParty
, c.pract_rpt_name
, c.spclty_desc

from @xfer_pts as a
inner join smsdss.BMH_PLM_PtAcct_Clasf_Proc_V_New as b
on a.pt_no = b.Pt_No
	and b.ClasfType = 'c'
left join smsdss.pract_dim_v as c
on b.RespParty = c.src_pract_no
	and c.orgz_cd = 's0x0'
) 

insert into @consults
select * from cte

--select * from @consults;
-----------------------------------------------------------------------
declare @eye_dx table (
	pk int not null identity(1, 1) primary key
	, pt_no varchar(12)
);

with cte as (
	select pt_id
	from smsmir.dx_grp
	where (
		dx_cd between 'h00' and 'h05'
		or
		dx_cd between 'h10' and 'h11'
		or
		dx_cd between 'h15' and 'h22'
		or
		dx_cd between 'h25' and 'h28'
		or
		dx_cd between 'h30' and 'h36'
		or
		dx_cd between 'h40' and 'h42'
		or
		dx_cd between 'h43' and 'h44'
		or
		dx_cd between 'h46' and 'h47'
		or
		dx_cd between 'h49' and 'h52'
		or
		dx_cd between 'h53' and 'h54'
		or
		dx_cd between 'h55' and 'h57'
		or
		dx_cd between 'h59' and 'h59.89'
	)
	and dx_cd_type = 'df'
	and pt_id in (
		select zzz.pt_no
		from @xfer_pts as zzz
	)
)

insert into @eye_dx
select * from cte;

--select * from @eye_dx;
-----------------------------------------------------------------------
-- bring it all together
select *

from @xfer_pts as a
left join @consults as b
on a.pt_no = b.pt_no
left join @eye_dx as c
on a.pt_no = c.pt_no

where (
	a.atn_spclty like '%oph%'
	or
	b.provider_specialty like '%oph%'
	or
	c.pt_no is not null
)