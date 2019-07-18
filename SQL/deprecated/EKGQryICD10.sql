SET ANSI_NULLS OFF
GO
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @D DATETIME;
DECLARE @SD DATE;
DECLARE @ED DATE;

SET @D = GETDATE()
SET @SD = GETDATE()-7
SET @ED = GETDATE()-1

SELECT a.episode_no as PatientNumber,
LTRIM(RTRIM(a.med_rec_no)) as Med_Rec_No,
LEFT(a.rpt_name,(charindex(',',a.rpt_name,1)-1)) as 'Pt_Last_Name',
SUBSTRING(a.rpt_name,(charindex(',',a.rpt_name,1)+1),(LEN(a.rpt_name)-charindex(',',a.rpt_name,1))) as 'Pt_First_Name',
'' as 'CPT' ,
'' as 'Mod1',
'' as 'Mod2',
CONVERT(varchar(8),a.Order_Stop_Date,112) as 'Date_Of_Service',
b.prim_pract_no as 'Attend_Dr_No',
(
SELECT LEFT(f.pract_rpt_name,(charindex(' ',LTRIM(f.pract_rpt_name))-1))
FROM smsmir.mir_pract_mstr as f
WHERE f.src_sys_id='#PMSNTX0'
AND b.prim_pract_no=f.pract_no
) as 'Attend_Dr_Last_Name',
(
SELECT substring(f.pract_rpt_name,(charindex(' ',LTRIM(f.pract_rpt_name))+1),LEN(f.pract_rpt_name)-(charindex(' ',LTRIM(f.pract_rpt_name))-1))
FROM smsmir.mir_pract_mstr as f
WHERE f.src_sys_id='#PMSNTX0'
AND b.prim_pract_no=f.pract_no
) as 'Attend_Dr_First_Name',
a.fc,
LEFT(b.vst_type_cd,1) as 'Accomodation',
'' as 'Co-payment_Amount',
'' as 'Co-payment Paid',
a.pty_cd as 'Referring_Dr_No',
CASE
WHEN charindex(' ',a.pty_name)<>0 AND charindex(',',a.pty_name)<>0 THEN UPPER(SUBSTRING(a.pty_name,charindex(' ',a.pty_name)+1,(charindex(',',a.pty_name)-charindex(' ',a.pty_name)-1)))
WHEN CHARINDEX(' ',a.pty_name)>0 AND CHARINDEX(',',a.pty_name)=0 THEN UPPER(SUBSTRING(a.pty_name,charindex(' ',a.pty_name)+1,(len(rtrim(a.pty_name))-charindex(' ',a.pty_name))))
ELSE ''
END
AS 'Ref_Dr_Last_Name',
CASE
WHEN charindex(' ',a.pty_name)<>0 THEN UPPER(LEFT(a.pty_name,(charindex(' ',a.pty_name)-1)))
ELSE ''
END as 'Ref_Dr_First_Name',

'' as 'Second_FC',
a.ord_no as 'Client_Trans_Ref_No',
(SELECT ClasfCd
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_v as d
WHERE a.episode_no=d.PtNo_Num
AND d.SortClasfType = 'DA'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('1','01')) as 'Admit_Dx',
CASE
WHEN charindex(' ',f.readingdr)<>0 AND charindex(',',f.readingdr)<>0 THEN UPPER(SUBSTRING(f.readingdr,charindex(' ',f.readingdr)+1,(charindex(',',f.readingdr)-charindex(' ',f.readingdr)-1)))
WHEN CHARINDEX(' ',f.readingdr)>0 AND CHARINDEX(',',f.readingdr)=0 THEN UPPER(SUBSTRING(f.readingdr,charindex(' ',f.readingdr)+1,(len(rtrim(f.readingdr))-charindex(' ',f.readingdr))))
ELSE ''
END
AS 'Reading_Dr_Last_Name',
CASE
WHEN charindex(' ',f.readingdr)<>0 THEN UPPER(LEFT(f.readingdr,(charindex(' ',f.readingdr)-1)))
ELSE ''
END as 'Reading_Dr_First_Name',

--'' as 'Dx1',
--'' as 'Dx2',
'' as 'Dx3',
'' as 'Dx4',
'' as 'Dx5',
'' as 'Dx6',
'' as 'Dx7',
'' as 'Dx8',
'' as 'Dx9',
'' as 'Dx10',
(SELECT ClasfCd
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('1','01')) as 'Dx11',
(SELECT ClasfCd
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('2','02')) as 'Dx12',
(SELECT ClasfCd
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('3','03')) as 'Dx13',
(SELECT ClasfCd
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('4','04')) as 'Dx14',
(SELECT ClasfCd
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('5','05')) as 'Dx15',
(SELECT ClasfCd
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('6','06')) as 'Dx16',
(SELECT ClasfCd
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('7','07')) as 'Dx17',
(SELECT ClasfCd
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('8','08')) as 'Dx18',
(SELECT ClasfCd
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('9','09')) as 'Dx19',
(SELECT ClasfCd
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('10')) as 'Dx20',
'' as 'Dx21',
'' as 'Dx22',
'' as 'Dx23',
'' as 'Dx24',
'' as 'Dx25',
'' as 'Dx26',
'' as 'Dx27',
'' as 'Dx28',
'' as 'Dx29',
'' as 'Dx30',
c.Date_Coded,
a.ord_sts,
a.ord_no,
f.readingdr
FROM smsdss.c_sr_orders_finance_rpt_v as a LEFT JOIN smsmir.sr_vst_pms as b
ON a.episode_no=b.episode_no AND a.pt_id_start_dtime=b.pt_id_start_dtime
left join smsmir.obsv as e on a.episode_no = e.episode_no and 
a.ord_occr_no = e.ord_occr_no
left join smsmir.mir_sc_InvestigationResultSuppInfo f
on e.rslt_supl_info_obj_id = f.ObjectID
LEFT JOIN smsdss.c_bmh_coder_activity_v as c
ON a.episode_no=c.episode_no --AND a.pt_id_start_dtime=c.pt_id_start_Dtime

WHERE svc_cd IN ('00424994','00600015')
--AND ord_sts IN ('27','28','31','37')
--and ord_sts not in ('27','28','31', '37')
AND Order_Start_Date >'01/01/2017' 
and e.obsv_cd_name like 'EKG%'
and e.val_sts_cd = 'F'
AND Date_Coded between @SD and @ED --AND Date_Coded is null

ORDER BY PatientNumber--, date_of_service
