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
'' as 'Dx1',
'' as 'Dx2',
'' as 'Dx3',
'' as 'Dx4',
'' as 'Dx5',
'' as 'Dx6',
'' as 'Dx7',
'' as 'Dx8',
'' as 'Dx9',
'' as 'Dx10',
(SELECT isnull(ClasfCd,'')
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('1','01')) as 'Dx11',
(SELECT isnull(ClasfCd,'')
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('2','02')) as 'Dx12',
(SELECT isnull(ClasfCd,'')
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('3','03')) as 'Dx13',
(SELECT isnull(ClasfCd,'')
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('4','04')) as 'Dx14',
(SELECT isnull(ClasfCd,'')
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('5','05')) as 'Dx15',
(SELECT isnull(ClasfCd,'')
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('6','06')) as 'Dx16',
(SELECT isnull(ClasfCd,'')
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('7','07')) as 'Dx17',
(SELECT isnull(ClasfCd,'')
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('8','08')) as 'Dx18',
(SELECT isnull(ClasfCd,'')
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('9','09')) as 'Dx19',
(SELECT isnull(ClasfCd,'')
FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V as d
WHERE a.episode_no =d.PtNo_Num
AND d.SortClasfType = 'DF'
AND d.ClasfSch = '0'
AND d.ClasfPrio IN ('10')) as 'Dx20',
----(SELECT dx_cd
--FROM smsmir.mir_dx_grp as d
--WHERE a.episode_no =d.episode_no
--AND d.dx_cd_type LIKE 'DF%'
--AND dx_cd_prio IN ('21')) as 'Dx21',
--(SELECT dx_cd
--FROM smsmir.mir_dx_grp as d
--WHERE a.episode_no =d.episode_no
--AND d.dx_cd_type LIKE 'DF%'
--AND dx_cd_prio IN ('22')) as 'Dx22',
--(SELECT dx_cd
--FROM smsmir.mir_dx_grp as d
--WHERE a.episode_no =d.episode_no
--AND d.dx_cd_type LIKE 'DF%'
--AND dx_cd_prio IN ('23')) as 'Dx23',
--(SELECT dx_cd
--FROM smsmir.mir_dx_grp as d
--WHERE a.episode_no =d.episode_no
--AND d.dx_cd_type LIKE 'DF%'
--AND dx_cd_prio IN ('24')) as 'Dx24',
--(SELECT dx_cd
--FROM smsmir.mir_dx_grp as d
--WHERE a.episode_no =d.episode_no
--AND d.dx_cd_type LIKE 'DF%'
--AND dx_cd_prio IN ('25')) as 'Dx25',
--(SELECT dx_cd
--FROM smsmir.mir_dx_grp as d
--WHERE a.episode_no =d.episode_no
--AND d.dx_cd_type LIKE 'DF%'
--AND dx_cd_prio IN ('26')) as 'Dx26',
--(SELECT dx_cd
--FROM smsmir.mir_dx_grp as d
--WHERE a.episode_no =d.episode_no
--AND d.dx_cd_type LIKE 'DF%'
--AND dx_cd_prio IN ('27')) as 'Dx27',
--(SELECT dx_cd
--FROM smsmir.mir_dx_grp as d
--WHERE a.episode_no =d.episode_no
--AND d.dx_cd_type LIKE 'DF%'
--AND dx_cd_prio IN ('28')) as 'Dx28',
--(SELECT dx_cd
--FROM smsmir.mir_dx_grp as d
--WHERE a.episode_no =d.episode_no
--AND d.dx_cd_type LIKE 'DF%'
--AND dx_cd_prio IN ('29')) as 'Dx29',
--(SELECT dx_cd
--FROM smsmir.mir_dx_grp as d
--WHERE a.episode_no =d.episode_no
--AND d.dx_cd_type LIKE 'DF%'
--AND dx_cd_prio IN ('30')) as 'Dx30',
'' as 'Dx21',
'' as 'Dx22',
'' as 'Dx23',
'' as 'Dx24',
'' as 'Dx25',
'' as 'Dx26',
'' as 'Dx27',
'' as 'Dx28',
'' as 'Dx29',
'' as 'Dx30'
--c.Date_Coded
FROM smsdss.c_sr_orders_finance_rpt_v as a LEFT JOIN smsmir.sr_vst_pms as b
ON a.episode_no=b.episode_no AND a.pt_id_start_dtime=b.pt_id_start_dtime
LEFT JOIN smsdss.c_bmh_coder_activity_v as c
ON a.episode_no=c.episode_no --AND a.pt_id_start_dtime=c.pt_id_start_Dtime

WHERE svc_cd = '04400016'
AND ord_sts IN ('27','28','31','37')
AND Order_Start_Date >'07/01/2015'
 AND Date_Coded between @SD and @ED 
 --AND Date_Coded is null


ORDER BY PatientNumber--, date_of_service
