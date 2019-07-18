SET ANSI_NULLS OFF
GO
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @D DATETIME;
DECLARE @SD DATE;
DECLARE @ED DATE;

SET @D = GETDATE()
SET @SD = GETDATE()-2
SET @ED = GETDATE()-2

SELECT [Account_Num] = A.PtNo_Num
, [MRN] = A.Med_Rec_No
, [LastName] = PERS.last_name
, [FirstName] = PERS.first_name
, CODER.Coder
, [PrimaryI10DRG] = CASE WHEN A.Pyr1_Co_Plan_Cd = 'Z28' THEN B2.bl_drg_no ELSE B.bl_drg_no END
, [PrimaryDRGDescription] = CASE
       WHEN A.Pyr1_Co_Plan_Cd != 'Z28'
              THEN REPLACE(RIGHT(BILLED_DRG.drg_name, LEN(billed_drg.drg_name) - CHARINDEX(',', billed_drg.drg_name)),',',' ')
              ELSE REPLACE(RIGHT(BILLED_DRG2.drg_name, LEN(BILLED_DRG2.drg_name) - CHARINDEX(',', BILLED_DRG2.drg_name)),',',' ')
       END
--, [Grouper_Type] = LEFT(B.bl_drg_schm, 4)
, [PrimaryGrouperType] = CASE 
       WHEN A.Pyr1_Co_Plan_Cd != 'Z28' 
       AND LEFT(B.bl_drg_schm, 1) = 'M'
              THEN 'MS_DRG'
       WHEN A.Pyr1_Co_Plan_Cd = 'Z28'
       AND LEFT(B2.BL_DRG_SCHM, 1) = 'M'
              THEN 'MS_DRG'
              ELSE 'APR_DRG' 
       END
--, [ICD_Version_Primary] =  A.prin_dx_cd_schm
, [PrimaryICDVersion] = 'ICD-10'
, [PrimaryGrouperVersion] = CASE 
       WHEN A.Pyr1_Co_Plan_Cd != 'Z28'
       AND (
              LEFT(B.bl_drg_schm, 1) = 'M' 
              AND A.Dsch_Date < '2017-10-01'
       )  
              THEN '34'  
    WHEN A.Pyr1_Co_Plan_Cd != 'Z28' 
       AND (
              LEFT(B.bl_drg_schm, 1) = 'M' 
              AND A.Dsch_Date >= '2017-10-01'
       ) 
              THEN '35'
       WHEN A.Pyr1_Co_Plan_Cd = 'Z28'
       AND (
              LEFT(B2.BL_DRG_SCHM, 1) = 'M'
              AND A.Dsch_Date < '2017-10-01'
       ) 
              THEN '34'
       WHEN A.Pyr1_Co_Plan_Cd = 'Z28'
       AND (
              LEFT(B2.BL_DRG_SCHM, 1) = 'M'
              AND A.Dsch_Date >= '2017-10-01'
       ) 
              THEN '35'
              ELSE '33' 
       END
, [PrimaryDRGWeight] = CASE WHEN A.Pyr1_Co_Plan_Cd != 'Z28' THEN B.bl_drg_cost_weight ELSE B2.bl_drg_cost_weight END
, [PrimaryGM_Loss] = ''
, [SecondaryI10DRG] = CASE WHEN A.Pyr1_Co_Plan_Cd = 'Z28' THEN C2.drg_no ELSE C.drg_no END
, [SecondaryDRGDescription] = CASE
       WHEN A.Pyr1_Co_Plan_Cd != 'Z28'
              THEN REPLACE(RIGHT(NOTBILLED_DRG.drg_name, LEN(NOTBILLED_DRG.drg_name) - CHARINDEX(',', NOTBILLED_DRG.drg_name)),',',' ')
              ELSE REPLACE(RIGHT(NOTBILLED_DRG2.DRG_NAME, LEN(NOTBILLED_DRG2.DRG_nAME) - CHARINDEX(',', NOTBILLED_DRG2.DRG_NAME)),',',' ')
       END
--, [Grouper_Type] = C.drg_schm
, [SecondaryGrouperType] = CASE 
       WHEN A.Pyr1_Co_Plan_Cd != 'Z28'
       AND C.drg_type = 1 
              THEN 'MS_DRG' 
       WHEN A.Pyr1_Co_Plan_Cd = 'Z28'
       AND C2.drg_type = 1
              THEN 'MS_DRG'
              ELSE 'APR_DRG' 
       END
, [SecondaryICDVersion] = 'ICD-10'
, [SecondaryGrouperVersion] = CASE 
       WHEN A.Pyr1_Co_Plan_Cd != 'Z28'
       AND (
              c.drg_type = 1 
              AND A.Dsch_Date < '2017-10-01'
       )
              THEN '34'
       WHEN A.Pyr1_Co_Plan_Cd != 'Z28' 
       AND (
              c.drg_type = 1 
              AND A.Dsch_Date >= '2017-10-01'
       )
              THEN '35'
       WHEN A.Pyr1_Co_Plan_Cd = 'Z28'
       AND (
              C2.drg_type = 1
              AND A.Dsch_Date < '2017-10-01'
       )
              THEN '34'
       WHEN A.Pyr1_Co_Plan_Cd = 'Z28'
       AND (
              C2.drg_type = 1
              AND A.Dsch_Date >= '2017-10-01'
       )
              THEN '35'
        ELSE '33' 
       END
, [SecondaryDRGWeight] = CASE WHEN A.Pyr1_Co_Plan_Cd != 'Z28' THEN C.drg_cost_weight ELSE C2.drg_cost_weight END
, [GM_Loss] = ''
, APR_DRG.APRDRGNO
, APR_DRG.RISK_OF_MORTALITY
, APR_DRG.SEVERITY_OF_ILLNESS


FROM smsdss.BMH_PLM_PtAcct_V                  AS A
LEFT OUTER JOIN smsmir.pyr_plan               AS B
ON A.PT_NO = B.PT_ID
    AND A.unit_seq_no = B.unit_seq_no
    AND A.from_file_ind = B.from_file_ind
    AND A.Pyr1_Co_Plan_Cd = B.pyr_cd
LEFT OUTER JOIN smsmir.pyr_plan               AS B2
ON A.Pt_No = B2.pt_id
    AND A.unit_seq_no = B2.unit_seq_no
    AND A.from_file_ind = B2.from_file_ind
    AND A.Pyr2_Co_Plan_Cd = B2.pyr_cd
LEFT OUTER JOIN smsmir.drg                    AS C
ON A.Pt_No = C.pt_id
    AND A.unit_seq_no = C.unit_seq_no
    AND A.from_file_ind = C.from_file_ind
    AND LEFT(B.bl_drg_schm, 2) != LEFT(C.drg_schm, 2)
LEFT OUTER JOIN smsmir.drg                    AS C2
ON A.Pt_No = C2.pt_id
    AND A.unit_seq_no = C2.unit_seq_no
    AND A.from_file_ind = C2.from_file_ind
    AND LEFT(B2.bl_drg_schm, 2) != LEFT(C2.drg_schm, 2)
LEFT OUTER JOIN smsmir.pers_addr              AS PERS
ON A.Pt_No = PERS.pt_id
    AND A.from_file_ind = PERS.from_file_ind
    AND PERS.pers_type = 'PT'
LEFT OUTER JOIN smsdss.c_bmh_coder_activity_v AS CODER
ON A.PtNo_Num = CODER.episode_no
LEFT OUTER JOIN smsmir.drg_mstr               AS BILLED_DRG
ON B.bl_drg_no = BILLED_DRG.drg_no
    AND LEFT(B.BL_DRG_SCHM, 4) = BILLED_DRG.drg_schm
LEFT OUTER JOIN smsmir.drg_mstr               AS BILLED_DRG2
ON B2.bl_drg_no = BILLED_DRG2.drg_no
    AND LEFT(B2.BL_DRG_SCHM, 4) = BILLED_DRG2.drg_schm
LEFT OUTER JOIN smsmir.drg_mstr               AS NOTBILLED_DRG
ON C.drg_no = NOTBILLED_DRG.drg_no
    AND C.drg_schm = NOTBILLED_DRG.drg_schm
LEFT OUTER JOIN smsmir.drg_mstr               AS NOTBILLED_DRG2
ON C2.drg_no = NOTBILLED_DRG2.drg_no
    AND C2.drg_schm = NOTBILLED_DRG2.drg_schm
LEFT OUTER JOIN Customer.Custom_DRG           AS APR_DRG
ON A.PtNo_Num = APR_DRG.PATIENT#


WHERE (
--apr_drg.FinalBl BETWEEN @SD and @ED
	(B.last_bl_date between @SD and @ED) 
	OR
	(C.last_data_cngdate between @SD and @ED)
	OR
	(B2.last_bl_date between @SD and @ED) 
	OR
	(C2.last_data_cngdate between @SD and @ED)
)
AND LEFT(A.PTNO_NUM, 1) = '1'
AND A.tot_chg_amt > 0
AND A.Pyr1_Co_Plan_Cd <> '*'
and coder.Date_Coded is not null
--AND B.bl_drg_no IS NOT NULL

OPTION(FORCE ORDER);
