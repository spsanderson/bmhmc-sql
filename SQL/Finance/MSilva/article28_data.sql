/*
***********************************************************************
File: article28_data.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
    smsmir.actv
    smsmir.mir_actv_proc_seg_xreg
    smsdss.rev_cd_dim_v
    smsdss.actv_cd_dim_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get date for the Article28 Modeling file

Revision History:
Date		Version		Description
----		----		----
2019-07-10	v1			Initial Creation
***********************************************************************
*/

SELECT PLM.Med_Rec_No,
	PLM.hosp_svc,
	PLM.PtNo_Num,
	PLM.Pyr1_Co_Plan_Cd,
	PLM.User_Pyr1_Cat,
	PLM.Adm_Date,
	PLM.tot_chg_amt,
	PLM.tot_pay_amt,
	PLM.Tot_Amt_Due
FROM smsdss.BMH_PLM_PtAcct_V AS PLM
WHERE PLM.Pt_No IN (
		SELECT A.pt_id
		FROM SMSMIR.ACTV AS A
		LEFT OUTER JOIN SMSMIR.MIR_ACTV_PROC_SEG_XREF AS B ON A.actv_cd = B.ACTV_CD
			AND B.PROC_PYR_IND = 'A'
		LEFT OUTER JOIN SMSDSS.REV_CD_DIM_V AS C ON B.REV_CD = C.REV_CD
		LEFT OUTER JOIN smsdss.actv_cd_dim_v AS D ON A.actv_cd = D.actv_cd
		INNER JOIN smsdss.BMH_PLM_PtAcct_V AS PLM ON A.PT_ID = PLM.Pt_No
		WHERE a.chg_tot_amt != 0
			AND PLM.Adm_Date >= '2017-01-01'
			AND PLM.Plm_Pt_Acct_Type != 'I'
			AND PLM.hosp_svc IN ('BPC', 'WCC', 'WCH')
			AND PLM.User_Pyr1_Cat IN ('ZZZ', 'EEE')
			AND B.rev_cd = '510'
			AND PLM.tot_chg_amt > 0
		)
	AND PLM.Pt_No IN (
		SELECT DISTINCT (pt_id) AS PT_ID
		FROM SMSMIR.ACTV AS A
		INNER JOIN smsmir.mir_actv_proc_seg_xref AS B ON A.actv_cd = B.actv_cd
		WHERE B.CLASF_CD = 'G0463'
		);

