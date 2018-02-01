USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_dly_ed_tracking_sp]    Script Date: 1/29/2018 9:47:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO















/* =============================================
Author:		Scott Mathesie
Create date: 08132010
Description: Stored procedure to track ED records sent to AVIA code
to test exec smsdss.c_dly_ed_tracking_sp 

v1	-	08-13-2010	-	Initial creation by Scott
v2	-	01-29-2018	-	re-work entire sp.
						1. look to see if table exists
							a. if not create
							b. else populate new records only

=============================================== */
ALTER PROCEDURE  [smsdss].[c_dly_ed_tracking_sp]

as
	
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON; 


DROP TABLE smsdss.c_er_tracking

/*Create Temp Table With Chief Complaint*/

SELECT pt_id,
episode_no,
'Chief_Complaint'=user_data_text

INTO #ER_Chf_Complaint

FROM smsmir.pms_user_episo

WHERE user_data_cd LIKE '2CHFCOMP'

/*Create Temp Table With Date Sent To Avia. Convert Invision "2" Field to Date*/

SELECT pt_id,
episode_no,
'Sent_To_Avia_Date'=CAST((left(user_data_text,2)+'-'+substring(user_data_text,3,2)+'-'+right(user_data_text,2)) AS datetime)

INTO #ER_To_Avia

FROM smsmir.pms_user_episo

WHERE user_data_cd LIKE '2TOAVI%'

/*Create Temp Table With ER Walkout/Non-Billable Indicator*/

SELECT CAST(RIGHT(RTRIM(xx.pt_id),8) as varchar(20)) as pt_id,
CASE
WHEN xx.actv_cd IN  ('04600565','04600052') THEN 'WALKOUT'
WHEN xx.actv_cd ='04600094' THEN 'NON-BILLABLE AFTERCARE'
ELSE ''
END as 'Walkout_Ind',
SUM(xx.actv_tot_qty) as 'Wlkout_Qty'

INTO #ER_Wlk_Out_Ind

FROM smsmir.mir_actv as xx

WHERE xx.actv_cd IN ('04600565','04600052','04600094')
GROUP BY xx.pt_id, xx.actv_cd
HAVING SUM(xx.actv_tot_qty)<>0


/*Create Temp Table With ER Visit Charges & Service Levels*/

SELECT CAST(RIGHT(RTRIM(q.pt_id),8)as varchar(20)) as pt_id,
q.actv_cd,
r.actv_name,
CASE 
WHEN q.actv_cd IN ('04600409','04600458') THEN 'LEVEL 1'
WHEN q.actv_cd IN ('04600508','04600557') THEN 'LEVEL 2'
WHEN q.actv_cd IN ('04600607','04600656') THEN 'LEVEL 3'
WHEN q.actv_cd IN ('04600706','04600755') THEN 'LEVEL 4'
WHEN q.actv_cd IN ('04600805','04600854') THEN 'LEVEL 5'
WHEN q.actv_cd IN ('04600904','04600953') THEN 'CRITICAL CARE'
WHEN q.actv_cd IN ('04600011') THEN 'ER IP ADMIT FEE'
END as 'er_level',
SUM(q.actv_tot_Qty) as 'er_vst_qty',
SUM(q.chg_tot_amt) as 'er_vst_chgs'

INTO #ER_Vist_Chgs

FROM smsmir.mir_actv as q INNER JOIN smsmir.actv_mstr as r
ON q.actv_cd=r.actv_cd

WHERE q.actv_cd IN ('04600011','04600409','04600458','04600508','04600557','04600607','04600656','04600706','04600755','04600805','04600854','04600904','04600953')

GROUP BY q.pt_id, q.actv_cd, r.actv_name

HAVING SUM(q.actv_tot_qty)<>0

/*Create Temp Table With Attending Physician Info*/

SELECT aa.episode_no,
aa.pt_id,
ab.pt_id as 'Vst_Pt_Id',
aa.pt_id_start_dtime as 'Cen_Pt_ID_Start',
ab.pt_id_start_dtime as 'Vst_Pt_ID_Start',
ad.pt_id_start_dtime as 'PMS_Case_Pt_ID_Start',
ab.prim_pract_no,
ac.pract_rpt_name

INTO #ER_Attend_Phys_Name

FROM smsmir.mir_cen_hist as aa LEFT JOIN smsmir.mir_vst as ab
ON CAST(aa.episode_no as int)=CAST(ab.pt_id as int)
LEFT JOIN smsmir.mir_pract_mstr as ac
ON ab.prim_pract_no=ac.pract_no
LEFT JOIN smsmir.mir_pms_case as ad
ON aa.pt_id=ad.pt_id AND aa.episode_no=ad.episode_no

WHERE aa.xfer_eff_dtime >= '2014-01-01 00:00:00.000' --AND '2010-05-12 23:59:59.999'
AND aa.cng_type='N'
AND aa.pt_type='E'
AND ad.case_sts NOT IN ('15','25','35')
AND ac.src_sys_id='#PMSNTX0'

GROUP BY aa.episode_no,
aa.pt_id,
ab.pt_id ,
aa.pt_id_start_dtime ,
ab.pt_id_start_dtime,
ad.pt_id_start_dtime ,
ab.prim_pract_no,
ac.pract_rpt_name

/*Create Temp Table With Admitting ER Physician Name*/

SELECT ax.episode_no,
ax.pt_id,
ax.pt_id_start_dtime,
av.user_data_text

INTO #ER_Admit_Phys_Name

FROM smsmir.mir_cen_hist as ax LEFT JOIN smsmir.mir_pms_user_episo as av
ON ax.episode_no=av.episode_no
LEFT JOIN smsmir.mir_pms_case as ay
ON ax.pt_id=ay.pt_id AND ax.episode_no=ay.episode_no

WHERE ax.xfer_eff_dtime >= '2015-01-01 00:00:00.000' 
AND ax.cng_type='N'
AND ax.pt_type='E'
AND ay.case_sts NOT IN ('15','25','35')
AND av.src_sys_id='#PMSNTX0'
AND av.user_data_cd='2ADMDRNA'

GROUP BY ax.episode_no,
ax.pt_id,
ax.pt_id_start_dtime,
av.user_data_text


/*Brings Together All Data From Temp and MIR Tables*/

SELECT b.rpt_name,
a.pt_id,
a.episode_no,
a.vst_id,
b.med_rec_no,
b.preadm_pt_id,
v.from_file_ind,
b.hosp_svc,
a.hosp_svc as 'Census_Svc',
a.hosp_svc_from,
a.pt_type,
a.pt_type_from,
a.xfer_eff_dtime as 'Reg_Dtime',
a.pt_id_start_dtime as 'Adm_Dtime',
a.resp_pty,
a.cng_type,
b.case_sts,
a.vst_type_cd,
e.ca_sts_desc,
b.no_1t_cngs,
b.pt_sts_xfer_ind,
isnull(f.prin_dx_cd,f.prin_dx_icd10_cd) as 'prin_dx_cd',
b.clin_acct_type,
b.adm_pract_no,
b.dsch_disp,
av.user_data_text as 'Adm_Dr_Name',
v.tot_bal_amt,
v.tot_adj_amt,
f.tot_chg_amt,
f.prim_pract_no,
ag.pract_rpt_name as 'Attend_Dr_Name',
t.er_level,
t.er_vst_qty,
t.er_vst_chgs,
o.sent_to_avia_date,
x.Chief_Complaint,
axx.Wlkout_Qty,
axx.Walkout_Ind



INTO smsdss.c_er_tracking



FROM smsmir.mir_cen_hist as a LEFT JOIN smsmir.mir_pms_case as b
ON a.pt_id=b.pt_id AND a.episode_no=b.episode_no 
LEFT JOIN smsdss.ca_sts_mstr as e
ON b.case_sts=e.ca_sts
LEFT JOIN smsmir.mir_vst as f
ON CAST(a.episode_no as int)=CAST(f.pt_id as int)
LEFT JOIN #ER_Vist_Chgs as t
ON a.episode_no=t.pt_id
LEFT JOIN #ER_To_Avia as o
ON a.episode_no=o.episode_no
LEFT JOIN #ER_Chf_Complaint as x
ON a.episode_no=x.episode_no
LEFT JOIN smsmir.mir_acct as v
ON CAST(a.episode_no as int)=CAST(v.pt_id as int)
LEFT JOIN #ER_Admit_Phys_Name as av
ON a.pt_id=av.pt_id AND a.episode_no=av.episode_no
LEFT JOIN #ER_Attend_Phys_Name as ag
ON a.pt_id=ag.pt_id AND a.episode_no=ag.episode_no
LEFT JOIN #ER_Wlk_Out_Ind as axx
ON a.episode_no=axx.pt_id

WHERE a.xfer_eff_dtime >= '2016-01-01 00:00:00.000' 
AND a.cng_type='N'
AND a.pt_type='E'
AND b.case_sts NOT IN ('15','25','35')
AND a.episode_no NOT IN
(

SELECT DISTINCT (preadm_pt_id)

FROM smsmir.mir_pms_case
WHERE NOT preadm_pt_id IS NULL

)




END

















