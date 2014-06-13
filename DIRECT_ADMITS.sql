--#####################################################################

-- COLUMN SELECTION
SELECT PDV.pract_rpt_name AS 'MD NAME'
, PAV.drg_no AS 'DRG'
, PAV.prin_dx_cd AS 'PRINCIPAL DX'
, DDV.clasf_desc AS 'DX DESC'
, PAV.Pt_No AS 'VISIT ID'
, PAV.Pt_Name AS 'PT NAME'

-- DB(S) USED
FROM SMSDSS.BMH_PLM_PTACCT_V PAV
JOIN smsdss.pract_dim_v PDV
ON PAV.Adm_Dr_No = PDV.src_pract_no
JOIN smsdss.dx_cd_dim_v DDV
ON PAV.prin_dx_cd = DDV.dx_cd

-- FILTERS
WHERE PAV.Adm_Date BETWEEN '2012-01-01' AND '2012-12-31'
AND PAV.Adm_Source IN ('RA', 'RP')
AND PAV.Plm_Pt_Acct_Type = 'I'
AND PDV.pract_rpt_name != 'TEST DOCTOR X'
AND PDV.pract_rpt_name != 'TESTCPOE DOCTOR'
AND PDV.orgz_cd = 'S0X0'
ORDER BY PDV.pract_rpt_name

--#####################################################################
