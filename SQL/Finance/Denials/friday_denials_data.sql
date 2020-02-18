/*
***********************************************************************
File: friday_denials_data.sql

Input Parameters:
	DECLARE @TODAY DATE;
    DECLARE @START DATE;
    DECLARE @END   DATE;

    SET @TODAY = GETDATE();
    SET @START = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY) -10, 0)
    SET @END   = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY), -3);

Tables/Views:
	smsdss.bmh_plm_ptacct_v
    smsmir.pay
    smsdss.pay_cd_dim_v
    smsdss.pract_dim_v
    smsdss.drg_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Gather all accounts with denial code 10501104 put on them from previous
    Friday through currently past Thursday

Revision History:
Date		Version		Description
----		----		----
2020-02-03	v1			Initial Creation
***********************************************************************
*/

DECLARE @TODAY DATE;
DECLARE @START DATE;
DECLARE @END   DATE;

SET @TODAY = GETDATE();
SET @START = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY) -10, 0)
SET @END   = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY), -3);

SELECT PAV.Med_Rec_No
, PAV.PtNo_Num
, PAV.Atn_Dr_No 
, UPPER(PDV.PRACT_rpt_name) AS [Attending_Provider]
, CASE
	WHEN PDV.src_spclty_cd = 'HOSIM'
		THEN 'HOSPITALIST'
		ELSE 'PRIVATE'
  END AS [Hospitalist_Private]
, PAV.hosp_svc
, CAST(PAV.ADM_DATE AS DATE) AS [ADM_DATE]
, CAST(PAV.DSCH_DATE AS DATE) AS [DSCH_DATE]
, PAY.pay_cd
, PAYCD.pay_cd_name
, CAST(PAY.pay_entry_date AS DATE) AS [POST_DATE]
, CAST(PAY.pay_date AS DATE) AS [DENIAL_DATE]
, DATEDIFF(DAY, PAY.pay_date, PAY.pay_entry_date) AS [DENIAL_TO_ENTRY_LAG]
, DATEDIFF(DAY, PAV.DSCH_DATE, PAY_ENTRY_DATE) AS [DSCH_TO_DENIAL_LAG]
, PAV.tot_chg_amt
, PAV.drg_no
, PAV.drg_cost_weight
, DRG.drg_med_surg_group
, DRG.drg_complic_group
, DRG.drg_name
, DRG.drg_rate

FROM SMSDSS.BMH_PLM_pTACCT_V AS PAV
INNER JOIN SMSMIR.PAY AS PAY
ON PAV.PT_NO = PAY.pt_id
	AND PAV.unit_seq_no = PAY.unit_seq_no
	AND PAV.from_file_ind = PAY.from_file_ind
	AND PAY.pay_cd = '10501104'
INNER JOIN SMSDSS.PAY_CD_DIM_V AS PAYCD
ON PAY.pay_cd = PAYCD.pay_cd
	AND PAY.orgz_cd = PAYCD.orgz_cd
INNER JOIN SMSDSS.PRACT_DIM_V AS PDV
ON PAV.Adm_Dr_No = PDV.src_pract_no
	AND PAV.Regn_Hosp = PDV.orgz_cd
LEFT OUTER JOIN SMSDSS.drg_v AS DRG
ON CAST(PAV.Bl_Unit_Key AS VARCHAR) = CAST(SUBSTRING(DRG.bl_unit_key, 9, 20) AS varchar)
	AND CAST(PAV.Pt_Key AS VARCHAR) = CAST(SUBSTRING(DRG.pt_key, 9, 20) AS VARCHAR)
	AND CAST(PAV.drg_no AS VARCHAR) = CAST(DRG.drg_no AS VARCHAR)

WHERE PAY.pay_entry_date >= @START
AND PAY.pay_entry_date < @END
