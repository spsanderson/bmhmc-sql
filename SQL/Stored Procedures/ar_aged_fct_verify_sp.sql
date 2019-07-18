USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[ar_aged_fct_verify_sp]    Script Date: 10/5/2018 3:30:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* This procedure verifies row counts and measures
   in the smsdss.ar_aged_fct fact table to the
   values in the source smsmir views.
   Fact Verification Name: 	smsdss.ar_aged_fct_verify_sp
*/

ALTER procedure [smsdss].[ar_aged_fct_verify_sp]
	@abend_ind	char(1) = '1',
	@sms_msg_grp_id	int = NULL
as
declare 
 @prcs_version	   int
,@prcs_name	   varchar(128)
,@rtn_sts	   int
,@log_msg	   varchar(255)
,@msg_text         varchar(255)
,@audit_dtime      datetime
,@lock_timeout	smallint
,@prcs_date	datetime
,@ddm_rowcount     int
,@mir_rowcount     int
,@snapshot_run_type          char(1)
,@snapshot_retention          tinyint
,@src_sys_id          char(8)
,@orgz_cd          varchar(8)
,@ddm_tot_chg_amt decimal(38,15)
,@mir_tot_chg_amt decimal(38,15)
,@ddm_tot_adj_amt decimal(38,15)
,@mir_tot_adj_amt decimal(38,15)
,@ddm_tot_bal_amt decimal(38,15)
,@mir_tot_bal_amt decimal(38,15)
,@ddm_net_rev decimal(38,15)
,@mir_net_rev decimal(38,15)
,@ddm_fnl_bl_cnt bigint
,@mir_fnl_bl_cnt bigint
,@ddm_ended_vst_cnt bigint
,@mir_ended_vst_cnt bigint
,@ddm_closed_unit_cnt bigint
,@mir_closed_unit_cnt bigint
,@ddm_alt_net_rev decimal(38,15)
,@mir_alt_net_rev decimal(38,15)
,@ddm_nrm_net_rev decimal(38,15)
,@mir_nrm_net_rev decimal(38,15)
,@ddm_plm_rev_ind bigint
,@mir_plm_rev_ind bigint
,@ddm_pror_bd_wo_amt decimal(38,15)
,@mir_pror_bd_wo_amt decimal(38,15)

set nocount on
set arithabort off
set arithignore on
set ansi_warnings off

select @prcs_name = 'ar_aged_fct_verify_sp',
       @audit_dtime = getdate(),
       @prcs_date = smsdss.get_prcs_date_fn()

exec @rtn_sts = smsdbr.prcs_start @prcs_name, @prcs_version output,
	@sms_msg_grp_id, 1

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
select @snapshot_run_type = convert(char(1),prcs_param_1)
	,@snapshot_retention = convert(tinyint,prcs_param_2)
	,@src_sys_id = convert(char(8),prcs_param_3)
	,@orgz_cd = convert(varchar(8),prcs_param_4)
	from smsdbr.prcs_ctrl_v
	where prcs_name = 'ar_aged_fct_load_sp'
	and prcs_version = convert(varchar(7),
		(select max(convert(int,prcs_version))
		from smsdbr.prcs_ctrl_v
		where prcs_name = 'ar_aged_fct_load_sp'))

if @@error != 0
  begin
   exec smsdbr.prcs_error 'sms_err', 'sms_applinfo2',
        @sms_msg_grp_id, @prcs_name, @prcs_version, 
        'Selecting run parm @orgz_cd' 
   exec dbo.sp_releaseapplock @Resource = 'DMGEN:FactInProgress', @LockOwner = 'Session'
   exec dbo.sp_releaseapplock @Resource = 'DMGEN:smsdss.ar_aged_fct', @LockOwner = 'Session'
   return 1
  end

exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Selecting row count & amounts from the smsmir view (1)...'

select @mir_rowcount = count(*),
       @mir_tot_chg_amt = isnull(sum(convert(decimal(38,15),f.tot_chg_amt)),0),
       @mir_tot_adj_amt = isnull(sum(convert(decimal(38,15),f.tot_adj_amt)),0),
       @mir_tot_bal_amt = isnull(sum(convert(decimal(38,15),f.tot_bal_amt)),0),
       @mir_net_rev = isnull(sum(convert(decimal(38,15),f.net_rev)),0),
       @mir_fnl_bl_cnt = isnull(sum(convert(bigint,case when (case when d1.vst_type_cd = 'I' then f.fnl_bl_date else isnull(f.op_first_bl_date, d1.vst_start_date) end) is null then 0 else 1 end)),0),
       @mir_ended_vst_cnt = isnull(sum(convert(bigint,case when d1.pt_sts_cd in ('0','AC', 'A', 'AR','PA','PB','PE','PI','PO','ZR') and d1.vst_type_cd = 'I' then 0 else 1 end)),0),
       @mir_closed_unit_cnt = isnull(sum(convert(bigint,case when d1.dsch_disp is null then 0 else 1 end)),0),
       @mir_alt_net_rev = isnull(sum(convert(decimal(38,15),f.alt_net_rev)),0),
       @mir_nrm_net_rev = isnull(sum(convert(decimal(38,15),0)),0),
       @mir_plm_rev_ind = isnull(sum(convert(bigint,case when f.net_rev is null then 0 else 1 end)),0),
       @mir_pror_bd_wo_amt = isnull(sum(convert(decimal(38,15),f.alt_bd_wo_amt)),0)
from smsmir.acct f
join smsmir.vst d1 on
f.acct_no = d1.acct_no and f.from_file_ind = d1.from_file_ind and f.orgz_cd = d1.orgz_cd and f.pt_id = d1.pt_id and f.pt_id_start_dtime = d1.pt_id_start_dtime and f.src_sys_id = d1.src_sys_id and f.unit_seq_no = d1.unit_seq_no
join smsdss.ar_aged_ctrl d2 on
f.src_sys_id = d2.src_sys_id and f.orgz_cd = d2.orgz_cd
where (((f.src_sys_id not like '#ALG%' and f.unit_seq_no <> -1) or(f.src_sys_id like '#ALG%'))) and
(f.tot_bal_amt <> 0) and
(f.src_sys_id like '#PAS%' or f.src_sys_id like '#EPA%' or f.src_sys_id like '#4PA%' or f.src_sys_id like '#MF%')


if @@error != 0
   exec smsdbr.prcs_error 'sms_err', 'sms_applinfo2',
        @sms_msg_grp_id, @prcs_name, @prcs_version, 
        'Selecting from smsmir view'
else
   exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'

exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Selecting row count & amounts from the fact table...'

select @ddm_rowcount = count(*),
       @ddm_tot_chg_amt = sum(convert(decimal(38,15),f.tot_chg_amt)),
       @ddm_tot_adj_amt = sum(convert(decimal(38,15),f.tot_adj_amt)),
       @ddm_tot_bal_amt = sum(convert(decimal(38,15),f.tot_bal_amt)),
       @ddm_net_rev = sum(convert(decimal(38,15),f.net_rev)),
       @ddm_fnl_bl_cnt = sum(convert(bigint,f.fnl_bl_cnt)),
       @ddm_ended_vst_cnt = sum(convert(bigint,f.ended_vst_cnt)),
       @ddm_closed_unit_cnt = sum(convert(bigint,f.closed_unit_cnt)),
       @ddm_alt_net_rev = sum(convert(decimal(38,15),f.alt_net_rev)),
       @ddm_nrm_net_rev = sum(convert(decimal(38,15),f.nrm_net_rev)),
       @ddm_plm_rev_ind = sum(convert(bigint,f.plm_rev_ind)),
       @ddm_pror_bd_wo_amt = sum(convert(decimal(38,15),f.pror_bd_wo_amt))from smsdss.ar_aged_fct f
join smsdss.orgz_dim y on f.orgz_cd = y.orgz_cd and f.src_sys_id = y.src_sys_id
join smsdss.ar_aged_ctrl c on f.snapshot_date = c.snapshot_date and y.src_sys_id = c.src_sys_id and y.orgz_cd = c.orgz_cd

if @@error != 0
   exec smsdbr.prcs_error 'sms_err', 'sms_applinfo2',
        @sms_msg_grp_id, @prcs_name, @prcs_version, 
        'Selecting from fact table' 
else
   exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'RowCount', '',
        @audit_dtime, @ddm_rowcount, @mir_rowcount)

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'tot_chg_amt', 'smsmir.acct',
        @audit_dtime, @ddm_tot_chg_amt, @mir_tot_chg_amt)

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'tot_adj_amt', 'smsmir.acct',
        @audit_dtime, @ddm_tot_adj_amt, @mir_tot_adj_amt)

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'tot_bal_amt', 'smsmir.acct',
        @audit_dtime, @ddm_tot_bal_amt, @mir_tot_bal_amt)

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'net_rev', 'smsmir.acct',
        @audit_dtime, @ddm_net_rev, @mir_net_rev)

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'fnl_bl_cnt', 'smsmir.acct',
        @audit_dtime, @ddm_fnl_bl_cnt, @mir_fnl_bl_cnt)

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'ended_vst_cnt', 'smsmir.vst',
        @audit_dtime, @ddm_ended_vst_cnt, @mir_ended_vst_cnt)

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'closed_unit_cnt', 'smsmir.vst',
        @audit_dtime, @ddm_closed_unit_cnt, @mir_closed_unit_cnt)

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'alt_net_rev', 'smsmir.acct',
        @audit_dtime, @ddm_alt_net_rev, @mir_alt_net_rev)

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'nrm_net_rev', 'smsmir.acct',
        @audit_dtime, @ddm_nrm_net_rev, @mir_nrm_net_rev)

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'plm_rev_ind', 'smsmir.acct',
        @audit_dtime, @ddm_plm_rev_ind, @mir_plm_rev_ind)

insert smsdss.summ_audit
       (src_sys_id, summ_tbl_name, summ_col_name, dtl_tbl_name, 
        audit_dtime, summ_data_val, dtl_data_val)
values ('N/A', 'smsdss.ar_aged_fct', 'pror_bd_wo_amt', 'smsmir.acct',
        @audit_dtime, @ddm_pror_bd_wo_amt, @mir_pror_bd_wo_amt)

exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Calling summ_audit_check...'

exec @rtn_sts = smsdss.summ_audit_check @prcs_name, @prcs_version,
			@audit_dtime, @abend_ind, @sms_msg_grp_id,
			@msg_text output

if @rtn_sts = -1 and @abend_ind = '1'
	begin
   	   exec smsdbr.prcs_error 'sms_err', 'sms_applinfo2',
        	@sms_msg_grp_id, @prcs_name, @prcs_version, 
		'smsdss.ar_aged_fct is out of balance'
   	   exec dbo.sp_releaseapplock @Resource = 'DMGEN:FactInProgress', @LockOwner = 'Session'
   	   exec dbo.sp_releaseapplock @Resource = 'DMGEN:smsdss.ar_aged_fct', @LockOwner = 'Session'
	   return 1
	end

exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'

exec dbo.sp_releaseapplock @Resource = 'DMGEN:FactInProgress', @LockOwner = 'Session'
exec dbo.sp_releaseapplock @Resource = 'DMGEN:smsdss.ar_aged_fct', @LockOwner = 'Session'

exec smsdbr.prcs_update @prcs_name, @prcs_version, @rtn_sts, NULL, 0
return 0