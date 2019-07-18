USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[ar_aged_fct_load_sp]    Script Date: 10/5/2018 3:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER procedure [smsdss].[ar_aged_fct_load_sp]
	@snapshot_run_type	char(1) = 'L',
	@snapshot_retention	tinyint = 12,
	@src_sys_id	char(8) = NULL,
	@orgz_cd	varchar(8) = NULL,
	@sms_msg_grp_id	int = NULL
as
/* This procedure loads a fact table by linking the fact table 
   to all corresponding dimension tables via an insert statement.
   Fact Procedure Name: 	smsdss.ar_aged_fct_load_sp

*/
declare 
@prcs_version	int,
@prcs_name	varchar(128),
@sav_error	int,
@sav_rowcount	int,
@tot_rowcount	int,
@del_rowcount	int,
@rtn_sts	int,
@log_msg	varchar(255),
@c_rowcount	varchar(9),
@lock_timeout	int,
@prcs_date	datetime,
@prcs_UTCdate	datetime,
@dropped_idxs_msg	varchar(8000),
@full_reload	tinyint,
@refresh_stat	varchar(255),
@parm_status      int,
@pf_varbinary1 varbinary(8), 
@obj_id	int 

set nocount on
set arithabort off
set arithignore on
set ansi_warnings off

create table #incrm_refresh (fact_key char(27))

create unique clustered index clidx on #incrm_refresh (fact_key) 

exec sp_autostats 'smsdss.ar_aged_fct', 'off'

select @prcs_name = 'ar_aged_fct_load_sp',
  @tot_rowcount = 0

select @obj_id = object_id('smsdss.ar_aged_fct'),
       @prcs_date = smsdss.get_prcs_date_fn(),
       @prcs_UTCdate = smsdss.get_prcs_date_fn()

select @full_reload = 1
exec @rtn_sts = smsdbr.prcs_start @prcs_name, @prcs_version output,
	@sms_msg_grp_id, 1, @snapshot_run_type, @snapshot_retention, @src_sys_id, @orgz_cd
if @rtn_sts !=0
	return 1

select @lock_timeout = (isnull(opt_val,300)*1000) from smsdbr.sms_opt
where sms_appl = 'sms_dmg' and sms_opt = 'sms_lock_timeout' and 
sms_uom = 'sms_seconds'

exec @rtn_sts = dbo.sp_getapplock @Resource = 'DMGEN:FactInProgress',
@LockMode = 'Shared',@LockOwner = 'Session', @LockTimeout = @lock_timeout
if @rtn_sts < 0 
begin
	exec smsdbr.prcs_error 'sms_err', 'sms_rpttpcerr', @sms_msg_grp_id, @prcs_name, @prcs_version, 
	@prcs_name, 'smsdss.ar_aged_fct', 'Cannot process fact table while UI save is in progress'
	return 1
end
exec @rtn_sts = dbo.sp_getapplock @Resource = 'DMGEN:smsdss.ar_aged_fct',
@LockMode = 'Exclusive',@LockOwner = 'Session', @LockTimeout = @lock_timeout
if @rtn_sts < 0 
begin
	exec smsdbr.prcs_error 'sms_err', 'sms_rpttpcerr', @sms_msg_grp_id, @prcs_name, @prcs_version, 
	@prcs_name, 'smsdss.ar_aged_fct', 'Cannot process fact table while UI save is in progress'
      exec dbo.sp_releaseapplock @Resource = 'DMGEN:FactInProgress',
      @LockOwner = 'Session'
	return 1
end
exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Calling pre-process routine...'
exec @rtn_sts = smsdss.ar_aged_fct_pre_sp @prcs_name, @prcs_version, @sms_msg_grp_id, @snapshot_run_type, @snapshot_retention, @src_sys_id, @orgz_cd
if @rtn_sts !=0
begin
	exec dbo.sp_releaseapplock @Resource = 'DMGEN:FactInProgress', @LockOwner = 'Session'
	exec dbo.sp_releaseapplock @Resource = 'DMGEN:smsdss.ar_aged_fct', @LockOwner = 'Session'
	return 1
end

exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'
exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Dropping alternate indexes...'
exec @rtn_sts = smsdbr.dmgen_fact_indexes_sp 'smsdss.ar_aged_fct', 'drop', 0, 0, null, @dropped_idxs_msg output
if @rtn_sts != 0
begin
	exec smsdbr.prcs_error 'sms_err', 'sms_rpttpcerr', @sms_msg_grp_id, @prcs_name, @prcs_version, 
	@prcs_name, 'smsdss.ar_aged_fct', 'Drop indexes failed'
	exec dbo.sp_releaseapplock @Resource = 'DMGEN:FactInProgress', @LockOwner = 'Session'
	exec dbo.sp_releaseapplock @Resource = 'DMGEN:smsdss.ar_aged_fct', @LockOwner = 'Session'
	return 1
end
else
begin
	exec smsdbr.prcs_log @prcs_name, @prcs_version, @dropped_idxs_msg
end
exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'

exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Insert into fact table (1)...'

insert smsdss.ar_aged_fct (
acct_unit_key,
ar_aged_ctrl_key,
snapshot_date,
orgz_cd,
bl_unit_key,
pers_addr_key,
fnl_bl_date,
last_pay_date,
vst_date,
acct_prim_pyr_cd,
fc,
prim_pract_no,
drg_no,
prin_dx_cd,
prin_icd9_proc_cd,
hosp_svc,
vst_type_cd,
pt_type,
dsch_disp,
vst_postal_cd,
adm_date,
acct_pyr2_cd,
acct_pyr3_cd,
acct_pyr4_cd,
acct_sts,
vst_type_cd_2,
acct_close_unit_ind_cd,
vst_end_ind_cd,
fnl_bl_ind_cd,
cr_bal_ind_cd,
std_cntry_cd,
iss_cd,
reg_area_cd,
acct_age_day,
vst_end_acct_age_day,
last_pay_acct_age_day,
state_cd,
curr_pyr_cd,
src_sys_id,
pt_type_2,
drg_vers,
ip_fnl_bl_date,
op_fnl_bl_date,
prin_dx_icd9_cd,
prin_dx_icd10_cd,
prin_proc_icd_cd,
prin_proc_icd10_cd,
tot_chg_amt,
tot_adj_amt,
tot_bal_amt,
net_rev,
fnl_bl_cnt,
ended_vst_cnt,
closed_unit_cnt,
alt_net_rev,
nrm_net_rev,
plm_rev_ind,
pror_bd_wo_amt,
pt_city,
acct_no,
unit_seq_no,
pt_id,
rpt_name,
iss_orgz_cd,
prin_dx_schm,
prin_proc_schm)
select f.src_sys_id + convert(varchar(19), f.id_col),  --acct_unit_key
isnull(d1.snapshot_date, 0),  --ar_aged_ctrl_key
d1.snapshot_date,  --snapshot_date
 f.orgz_cd ,  --orgz_cd
isnull(d2.src_sys_id + convert(varchar(19), d2.id_col), 0),  --bl_unit_key
isnull(d3.src_sys_id + convert(varchar(19), d3.id_col), 0),  --pers_addr_key
isnull(f.op_first_bl_date,f.fnl_bl_date),  --fnl_bl_date
f.last_pay_date,  --last_pay_date
case when d2.vst_type_cd in ( 'O', 'E','?') then isnull(d2.vst_start_date,@prcs_date) when d2.pt_sts_cd in ('0','1','D', 'F', 'H', 'BL', 'IA', 'CL', 'AR', 'AZ', 'BD', 'BZ', 'PA', 'PB', 'PE', 'PI', 'PO', 'RS', 'ZA', 'ZB', 'ZR', 'ZZ') then d2.vst_end_date else d2.vst_start_date end,  --vst_date
f.prim_pyr_cd,  --acct_prim_pyr_cd
f.fc,  --fc
d2.prim_pract_no,  --prim_pract_no
d2.drg_no,  --drg_no
d2.prin_dx_cd,  --prin_dx_cd
d2.proc_icd9_cd,  --prin_icd9_proc_cd
d2.hosp_svc,  --hosp_svc
 d2.vst_type_cd ,  --vst_type_cd
d2.pt_type,  --pt_type
d2.dsch_disp,  --dsch_disp
 isnull(substring(d2.vst_postal_cd,1,5),'?') ,  --vst_postal_cd
f.adm_date,  --adm_date
f.pyr2_cd,  --acct_pyr2_cd
f.pyr3_cd,  --acct_pyr3_cd
f.pyr4_cd,  --acct_pyr4_cd
f.acct_sts,  --acct_sts
 d2.vst_type_cd ,  --vst_type_cd_2
case when d2.dsch_disp is null then '0' else '1' end,  --acct_close_unit_ind_cd
case when d2.vst_end_date is null and d2.vst_type_cd = 'I' then '0' else '1' end,  --vst_end_ind_cd
case when (case when d2.vst_type_cd = 'I' then f.fnl_bl_date else isnull(f.op_first_bl_date, d2.vst_start_date) end) is null then '0' else '1' end,  --fnl_bl_ind_cd
case when f.tot_bal_amt < 0 then '1' else '0' end,  --cr_bal_ind_cd
d3.std_cntry_cd,  --std_cntry_cd
f.iss_cd,  --iss_cd
f.reg_area_cd,  --reg_area_cd
 isnull(isnull (case when datediff(day,(case when d2.vst_type_cd = 'I' then f.fnl_bl_date else  isnull(f.op_first_bl_date, d2.vst_start_date) end),d1.snapshot_date) < 0 then -999 when datediff(day,(case when d2.vst_type_cd = 'I' then f.fnl_bl_date else  isnull(f.op_first_bl_date, d2.vst_start_date) end), d1.snapshot_date) > 999 then 999 else datediff(day,(case when d2.vst_type_cd = 'I' then f.fnl_bl_date else  isnull(f.op_first_bl_date, d2.vst_start_date) end), d1.snapshot_date) end, -999),-999) ,  --acct_age_day
 isnull(isnull (case when datediff(day,d2.vst_end_date, d1.snapshot_date) < 0 then -999 when datediff(day,d2.vst_end_date, d1.snapshot_date) > 999 then 999 else datediff(day,d2.vst_end_date, d1.snapshot_date) end, -999),-999) ,  --vst_end_acct_age_day
 isnull(isnull (case when datediff(day,f.last_pay_date, d1.snapshot_date) < 0 then -999 when datediff(day,f.last_pay_date, d1.snapshot_date) > 999 then 999 else datediff(day,f.last_pay_date, d1.snapshot_date) end, -999),-999) ,  --last_pay_acct_age_day
substring(d3.addr_line3,1,2),  --state_cd
isnull(isnull(f.curr_pyr_cd, (select top 1 isnull(c.pyr_cd, '?') from smsmir.pyr_plan c where f.pt_id = c.pt_id and f.src_sys_id = c.src_sys_id and f.from_file_ind = c.from_file_ind and f.pt_id_start_dtime = c.pt_id_start_dtime and f.orgz_cd = c.orgz_cd and c.tot_amt_due > 0 order by case when c.pyr_cd in (select pyr_cd from smsdss.self_pay_mstr s where c.src_sys_id = s.src_sys_id and c.orgz_cd = s.orgz_cd) then -999999999 else c.tot_amt_due end desc, c.tot_amt_due desc, c.pyr_seq_no asc)), '?'),  --curr_pyr_cd
 f.src_sys_id ,  --src_sys_id
d2.pt_type,  --pt_type_2
(select vers.drg_vers from smsmir.vst_ext vst_ext 
left join smsdss.drg_schm_vers_mstr vers
 on vers.drg_schm = vst_ext.drg_schm
where
d2.src_sys_id = vst_ext.src_sys_id and
d2.orgz_cd = vst_ext.orgz_cd and
d2.pt_id = vst_ext.pt_id and
d2.vst_id = vst_ext.vst_id and
d2.from_file_ind = vst_ext.from_file_ind and
d2.pt_id_start_dtime = vst_ext.pt_id_start_dtime and
d2.unit_seq_no = vst_ext.unit_seq_no and
d2.episode_no = vst_ext.episode_no),  --drg_vers
f.fnl_bl_date,  --ip_fnl_bl_date
f.op_first_bl_date,  --op_fnl_bl_date
d2.prin_dx_icd9_cd,  --prin_dx_icd9_cd
d2.prin_dx_icd10_cd,  --prin_dx_icd10_cd
d2.proc_cd,  --prin_proc_icd_cd
d2.proc_icd10_cd,  --prin_proc_icd10_cd
isnull(f.tot_chg_amt,0),  --tot_chg_amt
isnull(f.tot_adj_amt,0),  --tot_adj_amt
isnull(f.tot_bal_amt,0),  --tot_bal_amt
isnull(f.net_rev,0),  --net_rev
isnull(case when (case when d2.vst_type_cd = 'I' then f.fnl_bl_date else isnull(f.op_first_bl_date, d2.vst_start_date) end) is null then 0 else 1 end,0),  --fnl_bl_cnt
isnull(case when d2.pt_sts_cd in ('0','AC', 'A', 'AR','PA','PB','PE','PI','PO','ZR') and d2.vst_type_cd = 'I' then 0 else 1 end,0),  --ended_vst_cnt
isnull(case when d2.dsch_disp is null then 0 else 1 end,0),  --closed_unit_cnt
isnull(f.alt_net_rev,0),  --alt_net_rev
0,  --nrm_net_rev
isnull(case when f.net_rev is null then 0 else 1 end,0),  --plm_rev_ind
isnull(f.alt_bd_wo_amt,0),  --pror_bd_wo_amt
d3.addr_line2,  --pt_city
f.acct_no,  --acct_no
d2.unit_seq_no,  --unit_seq_no
d2.pt_id,  --pt_id
case when 1 = 1 then d3.last_name + ', ' + d3.first_name else '?' end,  --rpt_name
f.orgz_cd,  --iss_orgz_cd
d2.prin_dx_cd_schm,  --prin_dx_schm
d2.proc_cd_schm  --prin_proc_schm

from smsmir.acct f
join smsdss.ar_aged_ctrl d1 on
f.src_sys_id = d1.src_sys_id and f.orgz_cd = d1.orgz_cd
join smsmir.vst d2 on
f.acct_no = d2.acct_no and f.from_file_ind = d2.from_file_ind and f.orgz_cd = d2.orgz_cd and f.pt_id = d2.pt_id and f.pt_id_start_dtime = d2.pt_id_start_dtime and f.src_sys_id = d2.src_sys_id and f.unit_seq_no = d2.unit_seq_no
left join smsmir.pers_addr d3 on
f.src_sys_id = d3.src_sys_id and f.pt_id = d3.pt_id and f.from_file_ind = d3.from_file_ind and f.pt_id_start_dtime = d3.pt_id_start_dtime and ((d3.pers_type = case when d3.src_sys_id like '#EPA%'  then 'SLF' else 'PT' end and d3.seq_no = (select min(e.seq_no) from smsmir.pers_addr e where d3.src_sys_id = e.src_sys_id and d3.pt_id = e.pt_id and d3.from_file_ind = e.from_file_ind and d3.pt_id_start_dtime = e.pt_id_start_dtime and d3.pers_type = e.pers_type)))

where (((f.src_sys_id not like '#ALG%' and f.unit_seq_no <> -1) or(f.src_sys_id like '#ALG%'))) and
(f.tot_bal_amt <> 0) and
(f.src_sys_id like '#PAS%' or f.src_sys_id like '#EPA%' or f.src_sys_id like '#4PA%' or f.src_sys_id like '#MF%')

option (MAXDOP 1)










select @sav_error = @@error, @sav_rowcount = @@rowcount
if @sav_error != 0
begin
	exec smsdbr.prcs_error 'sms_err', 'sms_rpttpcerr', @sms_msg_grp_id, @prcs_name, @prcs_version, 
	@prcs_name, 'smsdss.ar_aged_fct', 'Insert failed'
	exec dbo.sp_releaseapplock @Resource = 'DMGEN:FactInProgress', @LockOwner = 'Session'
	exec dbo.sp_releaseapplock @Resource = 'DMGEN:smsdss.ar_aged_fct', @LockOwner = 'Session'
	return 1
end
select @c_rowcount = convert(varchar(9), @sav_rowcount)
select @log_msg = '>>Rows inserted = ' + @c_rowcount
exec smsdbr.prcs_log @prcs_name, @prcs_version, @log_msg
select @tot_rowcount = @tot_rowcount + isnull(@sav_rowcount,0)
exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'

exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Updating statistics...'
update statistics smsdss.ar_aged_fct
exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'

exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Re-creating alternate indexes...'
exec @rtn_sts = smsdbr.dmgen_fact_indexes_sp 'smsdss.ar_aged_fct', 'create', 0, 0
if @rtn_sts != 0
begin
	exec smsdbr.prcs_error 'sms_err', 'sms_rpttpcerr', @sms_msg_grp_id, @prcs_name, @prcs_version, 
	@prcs_name, 'smsdss.ar_aged_fct', 'Create indexes failed'
	exec dbo.sp_releaseapplock @Resource = 'DMGEN:FactInProgress', @LockOwner = 'Session'
	exec dbo.sp_releaseapplock @Resource = 'DMGEN:smsdss.ar_aged_fct', @LockOwner = 'Session'
	return 1
end
exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'

exec sp_autostats 'smsdss.ar_aged_fct', 'on'

exec dbo.sp_releaseapplock @Resource = 'DMGEN:FactInProgress', @LockOwner = 'Session'
exec dbo.sp_releaseapplock @Resource = 'DMGEN:smsdss.ar_aged_fct', @LockOwner = 'Session'

select @refresh_stat = case when @full_reload = 1 then 'Full' else 'Incremental' end
exec smsdbr.prcs_update @prcs_name, @prcs_version, 1, @refresh_stat, @tot_rowcount

return 0
