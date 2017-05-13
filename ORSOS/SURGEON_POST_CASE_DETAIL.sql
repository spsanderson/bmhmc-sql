-- USING ORSOS
SELECT CASE_NO
, VISIT_NO
, APPOINTMENT_NO
, MEDICAL_RECORD_NO
, ACCOUNT_NO
, PROVIDER_SHORT_NAME
, MAIN_PROCEDURE_ID
, DIAGNOSIS
, ROOM_ID
, (
  CAST(CONVERT(VARCHAR, ENTER_PROC_ROOM_DATE, 110) 
  AS VARCHAR(15))
  + ' ' +
  CAST(CONVERT(VARCHAR, ENTER_PROC_ROOM_TIME, 108) 
  AS VARCHAR(15))
  ) 
  AS ENT_DTIME

FROM ORSPROD.POST_CASE

WHERE provider_short_name IS NOT NULL
	AND enter_dept_date >= '2012-01-01' 
	AND enter_dept_date < '2014-01-01'
	AND PROVIDER_SHORT_NAME LIKE '%%'
	
------------------------------------------------------------------------

-- USING DSS
SELECT D.PtNo_Num                [VISIT ID]
, E.READMIT                      [READMIT ID]
, E.INTERIM                      [DAYS TO READMIT]
, CAST(D.Adm_Date AS DATE)       [ADMIT DATE]
, CAST(D.Dsch_Date AS DATE)      [DISC DATE]
, CAST(D.Days_Stay AS INT)       [LOS]
, A.ClasfCd                      [PROC CODE]
, C.alt_clasf_desc               [PROC DESC]
, UPPER(B.pract_rpt_name)        [DOCTOR]

FROM smsdss.BMH_PLM_PtAcct_Clasf_Proc_V_New       A
INNER MERGE JOIN smsdss.pract_dim_v               B
ON A.RespParty = B.src_pract_no
INNER MERGE JOIN smsdss.proc_dim_v                C
ON A.ClasfCd = C.proc_cd
INNER MERGE JOIN smsdss.BMH_PLM_PtAcct_V          D
ON A.Pt_No = D.Pt_No
LEFT MERGE JOIN smsdss.vReadmits                  E
ON D.PtNo_Num = E.[INDEX]

WHERE A.ClasfPrio = '01'
	AND D.Dsch_Date >= '2012-01-01'
	AND D.Dsch_Date < '2014-01-01'
	AND A.ClasfCd != 'CONSULT'
	-- B TABLE FILTERS
	AND B.orgz_cd = 'S0X0'
	AND B.pract_rpt_name LIKE '%%'
	
ORDER BY D.Dsch_Date