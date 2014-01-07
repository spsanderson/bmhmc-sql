-- VARIABLE INITIALIZATION AND DECLARATION
DECLARE @SD AS DATE;
DECLARE @ED AS DATE;
SET @SD = '2013-01-01';
SET @ED = '2013-12-31';

SELECT B_Pt_No AS 'READMIT ENCOUNTER'
, B_Med_Rec_No AS 'MRN'
, B_Adm_Src_Desc AS 'READMIT SOURCE'
, B_Adm_Date AS 'READMIT DATE'
, B_Dsch_Date AS 'READMIT DISC DATE'
, DATEPART(MONTH, B_Dsch_Date) AS 'READMIT MONTH'
, DATEPART(YEAR, B_Dsch_Date) AS 'READMIT YEAR'
, B_Days_Stay AS 'LOS'
, B_Days_To_Readmit AS 'INTERIM'
, CASE 
	WHEN B_Pyr1_Co_Plan_Cd = '*' 
	THEN 'SELF PAY' 
	ELSE B_Pyr1_Co_Plan_Cd 
	END AS 'READMIT INSURANCE'
, B_Mdc_Name AS 'READMIT MDC'
, B_Drg_No AS 'READMIT DRG'
, B_Clasf_Desc AS 'READMIT DX CLASF'
, B_Readm_Adm_Dr_Name AS 'READMIT ADMITTING DR'
, B_Readm_Atn_Dr_Name AS 'READMIT ATTENDING DR'
, B_Hosp_Svc AS 'READMIT HOSP SVC'

-- DB USED
FROM smsdss.c_readmissions_v

WHERE B_Med_Rec_No IN (
	SELECT DISTINCT MED_REC_NO

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Plm_Pt_Acct_Type = 'I'
	AND PtNo_Num < '20000000'
	AND Dsch_Date BETWEEN @SD AND @ED
	AND drg_no IN (        -- DRG'S OF INTEREST
		'190','191','192'  -- COPD
		,'291','292','293' -- CHF
		,'193','194','195' -- PN
	)
)
AND B_Dsch_Date BETWEEN @SD AND @ED
AND B_Adm_Src_Desc != 'Scheduled Admission'