/**
THIS CODE IS CHECKING FOR PATIENTS WHO HAVE BEEN GIVEN A DIAGNOSIS OF
EITHER:
CALCIPHYLAXIS 275.49 OR
RHABDOMYOLYSIS 728.88
**/

-- COLUMN SELECTION
SELECT PAV.PtNo_Num AS [VISIT ID]
, PAV.Med_Rec_No AS MRN
, PAV.Pt_Sex AS SEX
, PAV.Pt_Age AS AGE
, PAV.Pt_Zip_Cd AS [ZIP CODE]
, PAV.Plm_Pt_Acct_Type AS [PT ACCT TYPE]
, DV.ClasfCd AS [DX CODE]
, DV.ClasfPrio AS [PRIORITY CODE]
, CASE
	WHEN DV.ClasfCd = '728.88' THEN 'RHABDOMYOLYSIS'
	WHEN DV.ClasfCd = '275.49' THEN 'CALCIPHYLAXIS'
	ELSE DV.ClasfCd
  END AS [DIAGNOSIS]
, CASE
	WHEN DV.ClasfType = 'DF' THEN 'FINAL DX'
	WHEN DV.CLASFTYPE = 'DFY' THEN 'PRESENT ON ADMISSION' 
	ELSE DV.CLASFTYPE
  END AS [FINAL OR PRESENT]
, PAV.ED_Adm AS [ED ADMIT]
, PAV.Adm_Date AS [ADMIT DATE]
, DATEPART(MONTH,PAV.Adm_Date) AS [ADMIT MONTH]
, DATEPART(YEAR, PAV.Adm_Date) AS [ADMIT YEAR]
, PAV.Dsch_Date AS [DISC DATE]
, DATEPART(MONTH, PAV.Dsch_Date) AS [DISC MONTH]
, DATEPART(YEAR, PAV.Dsch_Date) AS [DISC YEAR]
, PAV.Days_Stay AS LOS
, PAV.Pt_Race AS RACE
, PAV.Pt_Religion AS RELIGION

-- DB(S) USED
FROM smsdss.BMH_PLM_PtAcct_V PAV
JOIN smsdss.BMH_PLM_PtAcct_Clasf_Dx_V DV
ON PAV.PtNo_Num = DV.PtNo_Num

-- FILTER(S) USED
-- WE ONLY WANT PEOPLE THAT HAVE THE FOLLOWING DX CODES ASSOCIATED WITH
-- THEIR STAY AT THE FACILITY
WHERE DV.ClasfCd IN (
'275.49'
, '728.88'
)
-- THE DF WILL GIVE US A CODE OF WHETHER OR NOT THE DX WAS PRESENT ON
-- ADMISSION OR WHETHER THE PATIENT LEFT WITH THAT DX
AND ClasfType LIKE 'DF%'
AND PAV.Dsch_DTime >= '2009-01-01'
ORDER BY PAV.Dsch_Date