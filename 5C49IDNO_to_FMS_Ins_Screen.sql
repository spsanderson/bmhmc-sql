/*
***********************************************************************
File: 5C49IDNO_to_FMS_Ins_Screen.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
	smsmir.pyr_plan
	smsdss.c_ins_user_fields_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Creates file for the emue script 5C49IDNO_to_FMS_Ins_Screen.emue

Revision History:
Date		Version		Description
----		----		----
2018-11-23	v1			Initial Creation
2018-11-27	v2			Add date filter for previous day only
2018-11-28	v3			Update primary payer to exclusions
***********************************************************************
*/
DECLARE @START DATE;

SET @START = CAST(GETDATE() - 7 AS date);

SELECT ptno_num
, Pyr1_Co_Plan_Cd
--, Pt_SSA_No
--, b.pol_no
--, b.grp_no
, C.INS_POL_NO

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsmir.pyr_plan AS B
ON a.pt_no = b.pt_id
	AND a.unit_seq_no = b.unit_seq_no
	AND a.Pyr1_Co_Plan_Cd = b.pyr_cd
LEFT OUTER JOIN smsdss.c_ins_user_fields_v AS C
ON a.Pt_No = C.pt_id
	AND a.Pyr1_Co_Plan_Cd = C.pyr_cd
	AND a.from_file_ind = C.from_file_ind

--WHERE Pyr1_Co_Plan_Cd IN (
--	'I01','I04','E26'
--	)
WHERE Pyr1_Co_Plan_Cd NOT IN (
	'E18','E28'
)
AND LEFT(Pyr1_Co_Plan_Cd, 1) NOT IN (
	'A','B','Z'
)
AND LEFT(A.PtNo_Num, 1) != '7'
AND Adm_Date = @START
--AND Adm_Date >= '2018-01-01'
AND b.pol_no IS NULL
AND c.ins_pol_no IS NOT NULL