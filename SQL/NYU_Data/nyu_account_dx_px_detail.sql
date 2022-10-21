/*
***********************************************************************
File: nyu_account_dx_px_detail.sql

Input Parameters:
	None

Tables/Views:
	smsmir.dx_grp
    smsmir.sproc
    smsdss.bmh_plm_ptacct_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get diagnosis and procedure detail for nyulmc.

Revision History:
Date		Version		Description
----		----		----
2022-07-21	v1			Initial Creation
***********************************************************************
*/

DECLARE @START DATE;
DECLARE @END DATE;

SET @START = '2021-08-01';
SET @END = '2022-07-01';

-- Procedure Data
SELECT A.pt_id,
    A.unit_seq_no,
	CAST(ZZZ.Adm_Date AS DATE) AS [adm_date],
	CAST(ZZZ.Dsch_Date AS DATE) AS [dsch_date],
    A.proc_cd,
    A.proc_cd_prio,
    [procedure_consult_group] = CASE
        WHEN A.proc_cd_type = 'C' THEN 'CONSULT'
        ELSE 'PROCEDURE'
    END
FROM smsmir.sproc AS A
INNER JOIN smsdss.BMH_PLM_PtAcct_V AS ZZZ ON A.pt_id = ZZZ.PT_NO
	AND A.unit_seq_no = ZZZ.unit_seq_no
WHERE ZZZ.tot_chg_amt > 0
	AND ZZZ.prin_dx_cd IS NOT NULL
	AND LEFT(ZZZ.PTNO_NUM, 1) != '2'
	AND LEFT(ZZZ.PTNO_NUM, 4) != '1999'
	AND A.pt_id = ZZZ.PT_NO
	AND A.unit_seq_no = ZZZ.unit_seq_no
	AND ZZZ.Dsch_Date >= @START
	AND ZZZ.Dsch_Date < @END
ORDER BY A.pt_id,
    procedure_consult_group,
    A.proc_cd_prio;
    
-- Diagnosis Data
SELECT A.pt_id,
    A.unit_seq_no,
	CAST(ZZZ.Adm_Date AS DATE) AS [adm_date],
	CAST(ZZZ.Dsch_Date AS DATE) AS [dsch_date],
    A.dx_cd,
    A.dx_cd_prio
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.BMH_PLM_PtAcct_V AS ZZZ ON A.pt_id = ZZZ.PT_NO
	AND A.unit_seq_no = ZZZ.unit_seq_no
WHERE ZZZ.tot_chg_amt > 0
	AND ZZZ.prin_dx_cd IS NOT NULL
	AND LEFT(ZZZ.PTNO_NUM, 1) != '2'
	AND LEFT(ZZZ.PTNO_NUM, 4) != '1999'
	AND A.pt_id = ZZZ.PT_NO
	AND A.unit_seq_no = ZZZ.unit_seq_no
	AND ZZZ.Dsch_Date >= @START
	AND ZZZ.Dsch_Date < @END
ORDER BY A.pt_id,
    A.dx_cd_prio;