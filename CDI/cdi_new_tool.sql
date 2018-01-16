SELECT [Account_Num] = A.PtNo_Num
, [MRN] = A.Med_Rec_No
, [LastName] = PERS.last_name
, [FirstName] = PERS.first_name
, CODER.Coder
, [PrimaryI10DRG] = B.bl_drg_no
, [PrimaryDRGDescription] = replace(right(BILLED_DRG.drg_name, len(billed_drg.drg_name) - charindex(',', billed_drg.drg_name)),',',' ')
--, [Grouper_Type] = LEFT(B.bl_drg_schm, 4)
, [PrimaryGrouperType] = CASE WHEN left(B.bl_drg_schm, 1) = 'M' then 'MS_DRG' else 'APR_DRG' END
--, [ICD_Version_Primary] =  A.prin_dx_cd_schm
, [PrimaryICDVersion] = 'ICD-10'
, [PrimaryGrouperVersion] = CASE WHEN (left(B.bl_drg_schm, 1) = 'M' and A.Dsch_Date < '2017-10-01') then '34'  
                                 WHEN (left(B.bl_drg_schm, 1) = 'M' and A.Dsch_Date >= '2017-10-01') then '35'
                                                       else '33' END
, [PrimaryDRGWeight] = B.bl_drg_cost_weight
, [PrimaryGM_Loss] = ''
, [SecondaryI10DRG] = C.drg_no
, [SecondaryDRGDescription] = replace(right(NOTBILLED_DRG.drg_name, len(NOTBILLED_DRG.drg_name) - charindex(',', NOTBILLED_DRG.drg_name)),',',' ')
--, [Grouper_Type] = C.drg_schm
, [SecondaryGrouperType] = CASE WHEN C.drg_type = 1 then 'MS_DRG' else 'APR_DRG' END
, [SecondaryICDVersion] = 'ICD-10'
, [SecondaryGrouperVersion] =CASE WHEN (c.drg_type = 1 and A.Dsch_Date < '2017-10-01') then '34'  
                                 WHEN (c.drg_type = 1 and A.Dsch_Date >= '2017-10-01') then '35'
                                                       else '33' END
, [SecondaryDRGWeight] = C.drg_cost_weight
, [GM_Loss] = ''
, APR_DRG.APRDRGNO
, APR_DRG.RISK_OF_MORTALITY
, APR_DRG.SEVERITY_OF_ILLNESS

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsmir.pyr_plan AS B
ON A.PT_NO = B.PT_ID
       AND A.unit_seq_no = B.unit_seq_no
       AND A.from_file_ind = B.from_file_ind
       AND A.Pyr1_Co_Plan_Cd = B.pyr_cd
LEFT OUTER JOIN smsmir.drg AS C
ON A.Pt_No = C.pt_id
       AND A.unit_seq_no = C.unit_seq_no
       AND A.from_file_ind = C.from_file_ind
       AND left(B.bl_drg_schm, 2) != left(C.drg_schm, 2)
LEFT OUTER JOIN smsmir.pers_addr AS PERS
ON A.Pt_No = PERS.pt_id
       AND A.from_file_ind = PERS.from_file_ind
       AND PERS.pers_type = 'PT'
LEFT OUTER JOIN smsdss.c_bmh_coder_activity_v AS CODER
ON A.PtNo_Num = CODER.episode_no
LEFT OUTER JOIN smsmir.drg_mstr AS BILLED_DRG
ON B.bl_drg_no = BILLED_DRG.drg_no
       AND LEFT(B.BL_DRG_SCHM, 4) = BILLED_DRG.drg_schm
LEFT OUTER JOIN smsmir.drg_mstr AS NOTBILLED_DRG
ON C.drg_no = NOTBILLED_DRG.drg_no
       AND C.drg_schm = NOTBILLED_DRG.drg_schm
LEFT OUTER JOIN Customer.Custom_DRG AS APR_DRG
ON A.PtNo_Num = APR_DRG.PATIENT#

WHERE (
	apr_drg.FinalBl BETWEEN '2018-01-01' and '2018-01-01'
)
AND LEFT(A.PTNO_NUM, 1) = '1'
AND A.tot_chg_amt > 0
AND A.Pyr1_Co_Plan_Cd <> '*'
and coder.Date_Coded is not null
AND B.bl_drg_no IS NOT NULL

OPTION(FORCE ORDER);
