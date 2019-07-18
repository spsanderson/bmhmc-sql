/*
*****************************************************************************  
File: CDI_Admits_Discharges.sql      

Input  Parameters:
	None

Tables:   
	smsdss.BMH_PLM_PtAcct_V
  
Functions:   
	None

Author: Steve P Sanderson II, MPH

Department: Finance, Revenue Cycle
      
Revision History: 
Date		Version		Description
----		----		----
2018-09-25	v1			Initial Creation
-------------------------------------------------------------------------------- 
*/
DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2018-06-01';
SET @END   = '2018-07-01';

-- Total Admits All Payers Including PSY
SELECT 'Total Admits All Payers Including PSY' AS [Category]
, DATEPART(MONTH, ADM_DATE) AS [Month]
, COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Adm_Date >= @START
AND Adm_Date < @END
AND tot_chg_amt > 0
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'
AND Plm_Pt_Acct_Type = 'I'

GROUP BY DATEPART(MONTH, Adm_Date)

UNION

-- Total Admits All Payers Excluding PSY
SELECT 'Total Admits All Payers Excluding PSY' AS [Category]
, DATEPART(MONTH, ADM_DATE) AS [Month]
, COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Adm_Date >= @START
AND Adm_Date < @END
AND tot_chg_amt > 0
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'
AND Plm_Pt_Acct_Type = 'I'
AND hosp_svc != 'PSY'

GROUP BY DATEPART(MONTH, Adm_Date)

UNION

-- Total Admits Medicare Including PSY
SELECT 'Total Admits Medicare Including PSY' AS [Category]
, DATEPART(MONTH, ADM_DATE) AS [Month]
, COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Adm_Date >= @START
AND Adm_Date < @END
AND tot_chg_amt > 0
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'
AND Plm_Pt_Acct_Type = 'I'
AND User_Pyr1_Cat IN ('AAA', 'ZZZ')

GROUP BY DATEPART(MONTH, Adm_Date)

UNION

-- Total Admits Medicare Excluding PSY
SELECT 'Total Admits Medicare Excluding PSY' AS [Category]
, DATEPART(MONTH, ADM_DATE) AS [Month]
, COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Adm_Date >= @START
AND Adm_Date < @END
AND tot_chg_amt > 0
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'
AND Plm_Pt_Acct_Type = 'I'
AND User_Pyr1_Cat IN ('AAA', 'ZZZ')
AND hosp_svc != 'PSY'

GROUP BY DATEPART(MONTH, Adm_Date)

UNION

-- Total Discharges All Payers Including PSY
SELECT 'Total Discharges All Payers Including PSY' AS [Category]
, DATEPART(MONTH, Dsch_Date) AS [Month]
, COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Dsch_Date >= @START
AND Dsch_Date < @END
AND tot_chg_amt > 0
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'
AND Plm_Pt_Acct_Type = 'I'

GROUP BY DATEPART(MONTH, Dsch_Date)

UNION

-- Total Discharges All Payers Excluding PSY
SELECT 'Total Discharges All Payers Excluding PSY' AS [Category]
, DATEPART(MONTH, Dsch_Date) AS [Month]
, COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Dsch_Date >= @START
AND Dsch_Date < @END
AND tot_chg_amt > 0
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'
AND Plm_Pt_Acct_Type = 'I'
AND hosp_svc != 'PSY'

GROUP BY DATEPART(MONTH, Dsch_Date)

UNION

-- Total Discharges Medicare Including PSY
SELECT 'Total Discharges Medicare Including PSY' AS [Category]
, DATEPART(MONTH, Dsch_Date) AS [Month]
, COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Dsch_Date >= @START
AND Dsch_Date < @END
AND tot_chg_amt > 0
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'
AND Plm_Pt_Acct_Type = 'I'
AND User_Pyr1_Cat IN ('AAA', 'ZZZ')

GROUP BY DATEPART(MONTH, Dsch_Date)

UNION

-- Total Discharges Medicare Excluding PSY
SELECT 'Total Discharges Medicare Excluding PSY' AS [Category]
, DATEPART(MONTH, Dsch_Date) AS [Month]
, COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Dsch_Date >= @START
AND Dsch_Date < @END
AND tot_chg_amt > 0
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'
AND Plm_Pt_Acct_Type = 'I'
AND User_Pyr1_Cat IN ('AAA', 'ZZZ')
AND hosp_svc != 'PSY'

GROUP BY DATEPART(MONTH, Dsch_Date)
;