SELECT  
DISTINCT SUBSTRING(A1.pt_id, PATINDEX('%[^0]%', A1.PT_ID), 9)
                               AS [VISIT ID]
, CAST(A4.Days_Stay AS INT)    AS [LOS]
, A4.drg_no                    AS [DRG]
, A1.nurs_sta                  AS [NURS STATION]
, A3.pt_st_addr                AS [STREET ADDRESS]
, A4.Dsch_Date                 AS [DISCH DATE]
, CASE
	WHEN SUBSTRING(A5.pract_rpt_name, 1, 
					CHARINDEX(' X', A5.PRACT_RPT_NAME,1)) = ''
	THEN UPPER(A5.PRACT_RPT_NAME)
	ELSE SUBSTRING(A5.pract_rpt_name, 1, 
					CHARINDEX(' X', A5.PRACT_RPT_NAME,1))
  END AS DOCTOR
, (
   CAST(DATEPART(YEAR, A4.Dsch_Date) 
   AS VARCHAR(5)) 
   + '-' 
   + CAST(DATEPART(QUARTER, A4.Dsch_Date)
   AS VARCHAR(5))
   )                           AS [YYYYqN]

FROM smsdss.dly_cen_occ_fct_v     A1
	JOIN smsdss.vst_fct_v         A2
	ON a1.pt_id = a2.pt_id
	JOIN smsdss.pt_fct_v          A3
	ON a2.pt_key = a3.pt_key
	JOIN smsdss.BMH_PLM_PtAcct_V  A4
	ON A1.pt_id = A4.PtNo_Num
	JOIN smsdss.pract_dim_v       A5
	ON A4.Atn_Dr_No = A5.src_pract_no

WHERE A4.Dsch_Date >= '2010-01-01'        -- ENTER START DATE
AND A4.Dsch_Date < '2014-07-01'           -- ENTER END DATE
AND A3.pt_st_addr LIKE '%%'               -- ENTER STREET ADDRESS
AND A5.orgz_cd = 'S0X0'
AND A5.spclty_cd = 'HOSIM'                -- SET SPECIALTY