USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[ar_aged_fct_pre_sp]    Script Date: 10/5/2018 3:29:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER procedure [smsdss].[ar_aged_fct_pre_sp]
	@prcs_name	varchar(30),
	@prcs_version	int,
	@sms_msg_grp_id	int,
	@snapshot_run_type	char(1),
	@snapshot_retention	tinyint,
	@src_sys_id	char(8),
	@orgz_cd	varchar(8)
as
declare
	@rtn_sts	int,
	@log_msg	varchar(255),
	@tot_rowcount	int,
	@datediff	int,
	@getdate	datetime,
	@purgedate	datetime,
	@snapshot_date	datetime,
	@i_src_sys_id	char(8),
	@i_orgz_cd	varchar(8),
	@prcs_start_dtime datetime


set nocount on
set ansi_defaults off

exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Starting procedure smsdss.ar_aged_fct_pre_sp...'

/* Verify the src_sys_id parameter	*/	
exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Verify parm consistency...'

if (((@src_sys_id like '#PAS%' or @src_sys_id like '#EPA%' or @src_sys_id like '#4PA%' or @src_sys_id like '#MF%') 
	and @orgz_cd is not null) or (@src_sys_id is null and @orgz_cd is null))
		   	
begin
exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Parameters values consistent'
end
else 
if (@src_sys_id is null and @orgz_cd is not null) or 
	(@src_sys_id is not null and @orgz_cd is null)
begin
exec smsdbr.prcs_error 'sms_err','sms_invalidargs', @sms_msg_grp_id, @prcs_name,
	@prcs_version, @prcs_name
return 1
end
else
begin
exec smsdbr.prcs_error 'sms_err','sms_rpttpcerr', @sms_msg_grp_id, @prcs_name,
	@prcs_version, @prcs_name, 'smsdss.ar_aged_fct','src_sys_id parameter not valid value for procedure'
return 1
end

exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'

/* Truncate smsdss.ar_aged_ctrl table */
exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Truncate smsdss.ar_aged_ctrl table...'

truncate table smsdss.ar_aged_ctrl

exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'

exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Calculate @snapshot_date...'

select @prcs_start_dtime = smsdss.get_prcs_date_fn()

select @snapshot_date =
   case when @snapshot_run_type = 'L'
          then (select dateadd(day,-1,x.fisc_start_date)
	   from smsdss.fisc_xref x
	    where dateadd(day,1,@prcs_start_dtime) 
                     between x.fisc_start_date and x.fisc_end_date)
        else @prcs_start_dtime end

exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'

/* Declare snapshot_data cursor	*/
exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Declare snapshot_data cursor...'
if @src_sys_id is null and @orgz_cd is null
	begin
	declare snapshot_data cursor
	for
	select o.src_sys_id, o.orgz_cd
	from smsmir.orgz o
	where (o.src_sys_id like '#PAS%' or o.src_sys_id like '#EPA%' 
		or o.src_sys_id like '#4PA%' or o.src_sys_id like '#MF%')
	end
if (@src_sys_id like '#PAS%' or @src_sys_id like '#EPA%' 
	or @src_sys_id like '#4PA%' or @src_sys_id like '#MF%') 
	and @orgz_cd is not null
	begin
	declare snapshot_data cursor
	for
	select @src_sys_id, @orgz_cd
	end

if @@error !=0
	begin
	exec smsdbr.prcs_error 'sms_err','sms_rpttpcerr',@sms_msg_grp_id, @prcs_name,
	@prcs_version, @prcs_name, 'smsdss.ar_aged_fct','Error declaring snapshot_data cursor'
	return 1
	end
exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'
exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Opening snapshot_data cursor...'
open snapshot_data 

if @@error !=0
	begin
	exec smsdbr.prcs_error 'sms_err','sms_rpttpcerr',@sms_msg_grp_id, @prcs_name,
	@prcs_version, @prcs_name, 'smsdss.ar_aged_fct','Error opening snapshot_data cursor'
	return 1
	end
exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'
exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Fetching first record...'
fetch snapshot_data into
	@i_src_sys_id,
	@i_orgz_cd

if @@fetch_status != 0
	begin
	if @@fetch_status = -1
	begin
	exec smsdbr.prcs_log @prcs_name, @prcs_version, 'No rows qualified for cursor.'
	exec smsdbr.prcs_update @prcs_name, @prcs_version, 1, null, @tot_rowcount
	close snapshot_data
	deallocate snapshot_data
	return 0
	end
	else
	exec smsdbr.prcs_error 'sms_err','sms_rpttpcerr',@sms_msg_grp_id, @prcs_name,
	@prcs_version, @prcs_name, 'smsdss.ar_aged_fct','Error fetching snapshot_data cursor'
	return 1
	end
	
exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'
exec smsdbr.prcs_log @prcs_name, @prcs_version, ' Begin while loop...'

while @@fetch_status = 0
	begin

	insert smsdss.ar_aged_ctrl (src_sys_id, orgz_cd, snapshot_date)
	values(@i_src_sys_id, @i_orgz_cd, @snapshot_date)
	
	if @@error != 0
	begin
		exec smsdbr.prcs_error 'sms_err','sms_rpttpcerr',@sms_msg_grp_id, @prcs_name,
		@prcs_version, @prcs_name, 'smsdss.ar_aged_fct_pre_sp',
		'Error inserting rows into smsdss.ar_aged_ctrl'
		close snapshot_data
		deallocate snapshot_data
		return 1
	end

	fetch snapshot_data into
		@i_src_sys_id,
		@i_orgz_cd
	
	end
close snapshot_data
deallocate snapshot_data

exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'
exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Deleting current snapshots, if exists...'

delete from smsdss.ar_aged_fct
	from smsdss.ar_aged_fct f 
		join smsdss.date_dim x							-- Changed JOIN to go against date_dim table instead of view. (TGross - 6/6/07)
			on f.snapshot_date = x.full_date			-- Changed to match on natural date instead of date_key.
		
			where (x.fscl_yr*100) + x.fscl_pd = 
				(	select (d2.fscl_yr*100) + d2.fscl_pd 
					from smsdss.date_dim d2 
						join smsdss.ar_aged_ctrl c
							on d2.full_date = c.snapshot_date and 
								f.src_sys_id = c.src_sys_id and	--removed reference to orgz_dim 1/2/08
								f.orgz_cd = c.orgz_cd		--removed reference to orgz_dim 1/2/08
				)

if @@error != 0
	begin
		exec smsdbr.prcs_error 'sms_err','sms_rpttpcerr',@sms_msg_grp_id, @prcs_name,
		@prcs_version, @prcs_name, 'smsdss.ar_aged_fct_pre_sp',
		'Error deleting current snapshots'
		return 1
	end

exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'
exec smsdbr.prcs_log @prcs_name, @prcs_version, 'Deleting snapshots earlier than retention time...'

if @snapshot_run_type = 'L' 
	delete from smsdss.ar_aged_fct
		from smsdss.ar_aged_fct f								-- Removed join to date_dim, will use natural key instead.  (TGross - 6/11/07)
          	where f.snapshot_date <= dateadd(mm,-1 * @snapshot_retention, 
				(select c.snapshot_date from smsdss.ar_aged_ctrl c
				 where f.src_sys_id = c.src_sys_id and f.orgz_cd = c.orgz_cd)) --removed reference to orgz_dim 1/2/08

if @@error != 0
	begin
		exec smsdbr.prcs_error 'sms_err','sms_rpttpcerr',@sms_msg_grp_id, @prcs_name,
		@prcs_version, @prcs_name, 'smsdss.ar_aged_fct_pre_sp',
		'Error deleting snapshots outside of retention time'
		close snapshot_data
		deallocate snapshot_data
		return 1
	end

exec smsdbr.prcs_log @prcs_name, @prcs_version, '...complete'

exec smsdbr.prcs_log @prcs_name, @prcs_version, '...completed ar_aged_fct_pre_sp'
return 0
