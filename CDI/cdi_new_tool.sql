SELECT [Account_Num] = A.PtNo_Num
, [MRN] = A.Med_Rec_No
, [LastName] = PERS.last_name
, [FirstName] = PERS.first_name
, CODER.Coder
, [I10_DRG_Billed] = B.bl_drg_no
, [DRG_Description] = DRG_MSTR.drg_name
, [Grouper_Type] = LEFT(B.bl_drg_schm, 4)
, [ICD_Version_Primary] =  A.prin_dx_cd_schm
, [Primary_Grouper_Version] = ''
, [DRG_Weight] = B.bl_drg_cost_weight
, [GM_Loss] = ''
, [I10_DRG_NotBilled] = C.drg_no
, [Drg_Description] = DRG_MSTR_NOTBILLED.drg_name
, [Grouper_Type] = C.drg_schm
, [ICD_Version_Primary] = A.prin_dx_cd_schm
, [Primary_Grouper_Version] = ''
, [DRG_Weight] = C.drg_cost_weight
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
	AND left(B.bl_drg_schm, 4) != C.drg_schm
LEFT OUTER JOIN smsmir.pers_addr AS PERS
ON A.Pt_No = PERS.pt_id
	AND A.from_file_ind = PERS.from_file_ind
	AND PERS.pers_type = 'PT'
LEFT OUTER JOIN smsdss.c_bmh_coder_activity_v AS CODER
ON A.PtNo_Num = CODER.episode_no
LEFT OUTER JOIN smsmir.drg_mstr AS DRG_MSTR
ON B.bl_drg_no = DRG_MSTR.drg_no
	AND B.bl_drg_no = A.drg_no
	AND LEFT(B.bl_drg_schm, 4) = DRG_MSTR.drg_schm
LEFT OUTER JOIN Customer.Custom_DRG AS APR_DRG
ON A.PtNo_Num = APR_DRG.PATIENT#
LEFT OUTER JOIN smsmir.drg_mstr AS DRG_MSTR_NOTBILLED
ON C.drg_no = DRG_MSTR_NOTBILLED.drg_no
	AND C.drg_schm = DRG_MSTR_NOTBILLED.drg_schm

WHERE (
	A.Dsch_Date = '2017-01-01'
	OR
	A.Dsch_Date = '2017-10-05'
)

OPTION(FORCE ORDER);