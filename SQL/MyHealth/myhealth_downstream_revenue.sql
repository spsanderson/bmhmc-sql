/*
***********************************************************************
File: myhealth_downstream_revenue.sql

Input Parameters:
	DECLARE @ACTV_CD_START VARCHAR(10);
    DECLARE @ACTV_CD_END   VARCHAR(10);

Tables/Views:
	smsdss.c_ecw_2019_pt_list_june AS ECW
    smsdss.BMH_PLM_PtAcct_V AS PAV
    smsdss.pt_type_dim AS PTYPE
    smsdss.hosp_svc_dim_v AS HSVC
    smsdss.pract_dim_v AS ATTENDING
    smsdss.pract_dim_v AS ADMITTING
    smsdss.c_tot_pymts_w_pip_v AS PIP
    smsdss.pyr_dim_v AS PDV

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	MyHealth downstream revenue report

Revision History:
Date		Version		Description
----		----		----
2019-10-23	v1			Initial Creation
***********************************************************************
*/

DECLARE @ACTV_CD_START VARCHAR(10);
DECLARE @ACTV_CD_END VARCHAR(10);
DECLARE @START_DATE DATE;
DECLARE @END_DATE DATE;

SET @ACTV_CD_START = '07200000';
SET @ACTV_CD_END = '07299999';
SET @START_DATE = '';
SET @END_DATE = '';

SELECT ECW.FULL_NAME,
	ECW.SEX,
	ECW.DOB,
	PAV.Med_Rec_No,
	PAV.PtNo_Num,
	PAV.Pt_No,
	PAV.Plm_Pt_Acct_Type,
	PAV.pt_type,
	PTYPE.pt_type_desc,
	PAV.hosp_svc,
	HSVC.hosp_svc_name,
	CASE 
		WHEN COALESCE(PAV.Prin_Hcpc_Proc_Cd, PAV.Prin_Icd10_Proc_Cd, PAV.Prin_Icd9_Proc_Cd) IS NULL
			THEN 'NON-SURGICAL'
		ELSE 'SURGICAL'
		END AS [Surg_Case_Type],
	COALESCE(PAV.Prin_Hcpc_Proc_Cd, PAV.Prin_Icd9_Proc_Cd, PAV.Prin_Icd10_Proc_Cd) AS [Prin_Proc_Cd],
	PAV.Atn_Dr_No AS [Attending_Provider_ID],
	ATTENDING.pract_rpt_name AS [Attending_Provider_Name],
	PAV.Adm_Dr_No AS [Admitting_Provider_ID],
	ADMITTING.pract_rpt_name AS [Admitting_Provider_Name],
	CASE 
		WHEN ATTENDING.src_spclty_cd = 'HOSIM'
			THEN 'HOSPITALIST'
		ELSE 'PRIVATE'
		END AS [Hospitalist_Private],
	PAV.tot_chg_amt,
	ISNULL((
			SELECT SUM(p.chg_tot_amt)
			FROM smsmir.mir_actv AS p
			WHERE p.actv_cd BETWEEN @ACTV_CD_START
					AND @ACTV_CD_END
				AND PAV.PT_NO = p.pt_id
				AND PAV.pt_id_start_dtime = p.pt_id_start_dtime
				AND PAV.unit_seq_no = p.unit_seq_no
			HAVING SUM(p.chg_tot_amt) > 0
			), 0) AS [Implant_Chgs],
	PAV.tot_adj_amt,
	CASE 
		WHEN PAV.Plm_Pt_Acct_Type = 'I'
			THEN ISNULL(tot_pymts_w_pip, 0)
		ELSE PAV.tot_pay_amt
		END AS [TOT_PMTS],
	PAV.Tot_Amt_Due,
	PAV.User_Pyr1_Cat,
	PDV.pyr_group2,
	PAV.Pyr1_Co_Plan_Cd,
	PDV.pyr_name,
	YEAR(PAV.ADM_DATE) AS [ADM_YR],
	YEAR(PAV.DSCH_DATE) AS [DSCH_YR]
FROM smsdss.c_ecw_2019_pt_list_june AS ECW
INNER JOIN smsdss.BMH_PLM_PtAcct_V AS PAV ON ECW.FULL_NAME = PAV.Pt_Name
	AND ECW.SEX = PAV.Pt_Sex
	AND ECW.DOB = PAV.Pt_Birthdate
LEFT OUTER JOIN smsdss.pt_type_dim AS PTYPE ON PAV.pt_type = PTYPE.pt_type
	AND PAV.Regn_Hosp = PTYPE.orgz_cd
LEFT OUTER JOIN smsdss.hosp_svc_dim_v AS HSVC ON PAV.hosp_svc = HSVC.hosp_svc
	AND PAV.Regn_Hosp = HSVC.orgz_cd
LEFT OUTER JOIN smsdss.pract_dim_v AS ATTENDING ON PAV.Atn_Dr_No = ATTENDING.src_pract_no
	AND PAV.Regn_Hosp = ATTENDING.orgz_cd
LEFT OUTER JOIN smsdss.pract_dim_v AS ADMITTING ON PAV.Adm_Dr_No = ADMITTING.src_pract_no
	AND PAV.Regn_Hosp = ADMITTING.orgz_cd
LEFT OUTER JOIN smsdss.c_tot_pymts_w_pip_v AS PIP ON PAV.Pt_No = PIP.pt_id
	AND PAV.unit_seq_no = PIP.unit_seq_no
LEFT OUTER JOIN smsdss.pyr_dim_v AS PDV ON PAV.Pyr1_Co_Plan_Cd = PDV.pyr_cd
	AND PAV.Regn_Hosp = PDV.orgz_cd
WHERE PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Adm_Date IS NOT NULL
	AND PAV.Dsch_Date >= @START_DATE
	AND PAV.Dsch_Date < @END_DATE
ORDER BY PAV.Adm_Date


