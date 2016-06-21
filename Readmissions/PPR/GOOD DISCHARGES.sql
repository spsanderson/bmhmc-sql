/*
#######################################################################

DISCHARGES THAT ARE OK

#######################################################################
*/
DECLARE @PT_ACCT_TYPE     VARCHAR;
DECLARE @VISIT_ID         VARCHAR(8);

SET @PT_ACCT_TYPE     = 'I';
SET @VISIT_ID         = '20000000';

SELECT *

FROM smsdss.BMH_PLM_PtAcct_V

WHERE dsch_disp IN ('AHR', 'ATW')
AND Plm_Pt_Acct_Type = @PT_ACCT_TYPE
AND PtNo_Num < @VISIT_ID