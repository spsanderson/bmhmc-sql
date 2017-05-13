SELECT PtNo_Num
, Dsch_Date
, DATEPART(MONTH, Dsch_Date) AS [DSCH MONTH]
, DATEPART(YEAR, DSCH_DATE) AS [DSCH YEAR]

from smsdss.BMH_PLM_PtAcct_V

where Dsch_DTime >= '2014-07-01' 
AND DSCH_DTIME < '2014-08-01'
AND Plm_Pt_Acct_Type = 'I'
AND Plm_Pt_Acct_Type != 'P'
AND PtNo_Num < '20000000'
AND Pyr1_Co_Plan_Cd in (
'A00','A01','A02','A03','A04','A05','A06','A07','A08','A09',
'A10','A11','A12','A13','A50','A51','A52','A53','A59','A65',
'A70','A76','A77','A78','A79','A90','A91','A92','A93','A94',
'A95','A96','A97','A98','A99','E01','E02','E03','E04','E06',
'E07','E08','E10','E11','E12','E13','E16','E17','E18','E19',
'E21','E27','E28','E36','I01','I02','I03','I04','I05','I06',
'I07','I08','I09','I10','Z28','Z29','Z79','Z80','Z91','Z92',
'Z95','Z98','Z99','A14'
) -- <-- medicare