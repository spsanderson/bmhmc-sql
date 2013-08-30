SELECT
hpv.vst_start_dtime AS 'Admission_Date'
, hpv.vst_end_dtime AS 'Disch_Date'
, hp.rpt_name AS 'Patient_Name'    
, ISNULL(CAST(FLOOR(DATEDIFF(DAY, hp.birth_dtime, getDate()) / 365.25) AS VARCHAR),'')AS 'Age'
, hpv.med_rec_no AS 'MRN'
, hpv.episode_no AS 'Patient_Account_ID'
, ho.pty_name AS 'Ordering_Physician'
, ho.ord_no AS 'Order_ID'
, ho.svc_desc AS 'Order_Name'
--ho.qty_unit as 'Units',--Doesnt appear to be avaialble in DSS
--hosi.ReasonForRequest as 'Indication',-- NOT AVAILABLE IN DSS 
, hcm.clasf_desc AS 'Admitting_Diag'
, hpv.adm_dx_cd AS 'Admitting_Diag_Code' --I left it here ..not sure if they want the code
, ho.ent_dtime AS 'Order_Entered_Date'
, ho.str_dtime AS 'Order_Start_Date'
, ho.stp_dtime AS 'Order_Stop_Date'

--------------------------------------------------------

, hirz.result_value AS 'Result_Value_Before'
, hirz.coll_dtime AS 'Result_Date_Before'
, CASE WHEN hir2.def_type_ind = 'AN'
       THEN
         CAST(hir2.dsply_val AS VARCHAR)
       WHEN hir2.def_type_ind = 'NM'
       THEN 
         CAST(hir2.val_no AS VARCHAR)
  END AS 'Result_Value_After'
, hir2.coll_dtime as 'Result_Date_After'

--------------------------------------------------------------------------------------------------------------

FROM smsmir.trn_sr_vst_pms hpv WITH (nolock)
JOIN smsmir.trn_sr_pt hp WITH (nolock)
ON hpv.pt_id = hp.pt_id
JOIN smsmir.trn_sr_ord ho WITH (nolock)
ON hpv.vst_no = ho.vst_no
AND ho.svc_cd  = 'XFusePlatelets'  --For Platelets
--and ho.svc_cd in ('XfuseBldPrd', 'XFusePlatelets')
--Used line above if you would like to see service(s) prior to Blood Transfusion changes in Dec 2012
AND ho.ord_sts = 27 --Completed
JOIN smsmir.clasf_mstr hcm
ON hpv.adm_dx_cd = hcm.clasf_cd

------------------------------------------
--JOIN TO GET THE RESULT BEFORE TRANSFUSION
JOIN (
SELECT
CASE WHEN hir.def_type_ind = 'AN'
     THEN
       CAST(hir.dsply_val AS VARCHAR)
     WHEN hir.def_type_ind = 'NM'
     THEN
	   CAST(hir.val_no AS VARCHAR)
END AS 'Result_Value'
, hir.coll_dtime as 'Result_Date'
, hir.vst_no
, hir.coll_dtime
, hir.rslt_obj_id

FROM smsmir.trn_sr_obsv hir

WHERE hir.obsv_cd = '00402958'
AND hir.obsv_std_unit = 'kul') hirz

ON ho.vst_no = hirz.vst_no
AND ho.ent_dtime > hirz.coll_dtime
--and cast(substring(hirz.result_value,1, cast(len(rtrim(ltrim(hirz.result_value)))-1 as int)) as decimal(5,1)) > 20000
AND hirz.rslt_obj_id = (SELECT top 1 hirx.rslt_obj_id 
                       FROM smsmir.trn_sr_obsv hirx WITH (nolock)
                       WHERE hirz.vst_no = hirx.vst_no
                       AND ho.ent_dtime > hirx.coll_dtime
                       AND hirx.obsv_cd = '00402958'
                       AND hirx.obsv_std_unit = 'kul'
                       ORDER BY hirx.coll_dtime DESC)

------------------------------------------
--JOIN TO GET THE RESULT AFTER TRANSFUSION
LEFT OUTER JOIN smsmir.trn_sr_obsv hir2 WITH (nolock)
ON hirz.vst_no = hir2.vst_no
AND hirz.rslt_obj_id <> hir2.rslt_obj_id
AND hirz.coll_dtime < hir2.coll_dtime
AND hir2.obsv_cd = '00402958'
AND hir2.obsv_std_unit = 'kul'
AND hir2.rslt_obj_id = (SELECT top 1 hir2x.rslt_obj_id 
                       FROM smsmir.trn_sr_obsv hir2x WITH (nolock)
                       WHERE hir2.vst_no = hir2x.vst_no 
                       AND hirz.rslt_obj_id <> hir2x.rslt_obj_id
                       AND hirz.coll_dtime < hir2x.coll_dtime
                       AND hir2x.obsv_cd = '00402958'
                       AND hir2x.obsv_std_unit = 'kul'
                       ORDER BY hir2x.coll_dtime ASC)

--------------------------------------------------------------------------------------------------------------

WHERE hpv.vst_end_dtime IS NOT NULL
AND hpv.vst_end_dtime BETWEEN '2013-07-28' AND  '2013-08-10'
ORDER BY Patient_Name, Order_Start_Date
