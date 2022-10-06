/* 
This query will get our initial population of interest wherin we would 
like to try and predict the length of stay of any given patient within 
a specified service line. 
*/ 
SET ANSI_NULLS OFF 
GO 
  
-- Variable declaration 
DECLARE @IP_START_DATE DATE; 
DECLARE @IP_END_DATE DATE; 
  
SET @IP_START_DATE = '2015-10-01'; 
SET @IP_END_DATE = '2017-07-01'; 
  
-----
 
SELECT A.PtNo_Num  
, A.Pt_Sex 
, A.Pt_Race 
, A.dsch_disp 
, CASE
	WHEN LEFT(A.DSCH_DISP, 1) IN ('C', 'D')
		THEN 1
		ELSE 0
	END AS mortality_flag
, A.hosp_svc 
, A.Pt_Age 
, A.Pt_Zip_Cd 
, A.drg_no 
, A.drg_cost_weight 
, A.vst_start_dtime               AS [Adm Date Time] 
, A.vst_end_dtime                 AS [Dsch Date Time] 
, ROUND(
	CONVERT(INT, A.Days_Stay)
	,1)						       AS [Days Stay] 
, CASE 
	WHEN B.[READMIT] IS NULL 
		THEN 0 
		ELSE 1 
	END AS [Readmitted in 30?] 
, DATEPART(MONTH, A.DSCH_DATE)    AS [Discharge Month] 
, DATEPART(YEAR, A.Dsch_Date)     AS [Discharge Year] 
, CASE 
	WHEN C.src_spclty_cd = 'HOSIM' 
		THEN 1 
		ELSE 0 
	END AS [Hospitalist Flag] 
	
INTO #INIT_POP  

FROM smsdss.BMH_PLM_PtAcct_V AS A 
LEFT JOIN smsdss.vReadmits AS B 
ON A.PtNo_Num = B.[INDEX] 
AND B.INTERIM < 31 -- This ensures that we only get 
-- the accounts that are 30 Day 
-- RA's 
LEFT JOIN smsdss.pract_dim_v AS C 
ON A.Atn_Dr_No = C.src_pract_no 
	AND A.Regn_Hosp = C.orgz_cd
	  
WHERE A.Dsch_Date >= @IP_START_DATE 
AND A.Dsch_Date < @IP_END_DATE 
AND A.Plm_Pt_Acct_Type = 'I' 
AND A.PtNo_Num < '20000000'
AND LEFT(A.PTNO_NUM, 4) != '1999'
AND A.Days_Stay > 1

OPTION(FORCE ORDER);

--SELECT * FROM #INIT_POP;

 /* 
 This is the end of the query that will get the initial population of  
 interest 
 */ 
  
 /*-------------------------------------------------------------------*/ 
  
 /* 
 This query will pull together if the patient is poly-pharmacy or not 
 */ 

SELECT B.rpt_name                 AS [Patient Name] 
, B.vst_start_dtime               AS [Admit Date Time] 
, A.med_lst_type                  AS [Med List Type] 
, B.last_cng_dtime                AS [Last Status Update] 
, C.Med_Rec_No
, B.episode_no                    AS [Visit ID] 
, CONVERT(INT, COUNT(A.med_name)) AS [Home Med Count] 
	
INTO #PLYPHARM

FROM smsdss.qoc_med AS A 
JOIN smsdss.QOC_vst_summ AS B 
ON A.pref_vst_pms_id_col = B.pref_vst_pms_id_col 
JOIN smsdss.BMH_PLM_PtAcct_V AS C 
ON C.PtNo_Num = B.episode_no 
	  
WHERE A.med_lst_type = 'HML' 
AND C.Plm_Pt_Acct_Type = 'I' 
AND C.PtNo_Num < '20000000' 
AND B.episode_no IN (
	SELECT A.PtNo_Num
	FROM #INIT_POP AS A
)
	  
GROUP BY B.rpt_name 
, B.vst_start_dtime 
, A.med_lst_type 
, B.last_cng_dtime 
, C.Med_Rec_No
, B.episode_no;

--SELECT * FROM #PLYPHARM ORDER BY Med_Rec_No, [Admit Date Time];

  
 /* 
 This is the end of the poly-pharma query, it will only list those 
 that meet the criterion of being poly-pharmacy 
 */ 
 ----------------------------------------------------------------------
 /* 
 Get the LIHN Service line data, we only want to columns from the data 
 */

SELECT RTRIM(LTRIM(SUBSTRING(pt_id, PATINDEX('%[^0]%', pt_id), 9))) AS pt_id 
, LIHN_Service_Line
, 9 AS [ICD_Scheme]

INTO #LIHNSVCLINE9

FROM smsdss.c_LIHN_Svc_Lines_Rpt2_v;
	 
----- 
	 
SELECT RTRIM(LTRIM(SUBSTRING(pt_id, PATINDEX('%[^0]%', pt_id), 9))) AS pt_id 
, LIHN_Service_Line
, 0 AS [ICD_Scheme]

INTO #LIHNSVCLINE10

FROM smsdss.c_LIHN_Svc_Lines_Rpt2_ICD10_v;

-----
SELECT *

INTO #SVCLINETEMP

FROM (
	SELECT * FROM #LIHNSVCLINE9
	UNION ALL
	SELECT * FROM #LIHNSVCLINE10
) A;

-----

SELECT *
, RN = ROW_NUMBER() OVER(
	PARTITION BY PT_ID
	ORDER BY PT_ID, ICD_Scheme
)

INTO #SVCLINETEMP2

FROM #SVCLINETEMP

ORDER BY pt_id
, ICD_Scheme;

-----

SELECT *
INTO #LIHNSVCLINE
FROM #SVCLINETEMP2
WHERE RN = 1
AND pt_id IN (
	SELECT PtNo_Num
	FROM #INIT_POP
)

/*
End of getting LIHN Service Line information
*/
 ----------------------------------------------------------------------
  /* 
 Does the patient have some sort of ICU stay during their visit? 
 */ 
SELECT DISTINCT PVFV.pt_no AS [Visit_ID]
, MAX(CASE 
		 WHEN TXFR.NURS_STA IN ('SICU', 'MICU', 'CCU') 
			 THEN 1 
			 ELSE 0 
	 END) 
  OVER (PARTITION BY PVFV.PT_NO) AS [Has ICU Visit] 

INTO #ICUVISIT
  
FROM smsdss.pms_vst_fct_v PVFV 
JOIN smsdss.pms_xfer_actv_fct_v TXFR 
ON PVFV.pms_vst_key = TXFR.pms_vst_key 

WHERE PVFV.pt_no IN (
	SELECT PTNO_NUM
	FROM #INIT_POP
);
---------------------------------------------------------------------------------------------------
-- PULL IT ALL TOGETHER
SELECT IP.[PtNo_Num]
, IP.Pt_Sex
, IP.Pt_Race
, IP.Pt_Age
, IP.Pt_Zip_Cd
, IP.dsch_disp
, IP.hosp_svc
, IP.[Adm Date Time]
, DATEPART(WEEKDAY, IP.[ADM DATE TIME]) AS [Adm DOW] 
, DATEPART(MONTH, IP.[ADM DATE TIME])   AS [Adm Month] 
, DATEPART(YEAR, IP.[ADM DATE TIME])    AS [Adm Year] 
, DATEPART(HOUR, IP.[ADM DATE TIME])    AS [Adm Hour] 
, IP.[Dsch Date Time]
, DATEPART(WEEKDAY, IP.[Dsch Date Time])AS [Dsch DOW] 
, IP.[Discharge Month]
, IP.[Discharge Year]
, DATEPART(HOUR, IP.[DSCH DATE TIME])   AS [Dsch Hour] 
, IP.drg_no
, IP.drg_cost_weight
, CASE 
	WHEN IP.drg_cost_weight < 1 THEN 0 
	WHEN IP.drg_cost_weight >= 1 
	 AND IP.drg_cost_weight < 2 THEN 1 
	WHEN IP.drg_cost_weight >= 2 
	 AND IP.drg_cost_weight < 3 THEN 2 
	WHEN IP.drg_cost_weight >= 3 
	 AND IP.drg_cost_weight < 4 THEN 3 
	WHEN IP.drg_cost_weight >= 4 THEN 4 
  END                                   AS [DRG Weight Bin]
, ISNULL(PP.[Med List Type], 'No HML')  AS [Home Med List] 
, CASE 
	WHEN PP.[Home Med Count] IS NULL 
	THEN 0 
	ELSE PP.[Home Med Count]
   END                                   AS [Home Med Count] 
, CASE
	WHEN PP.[Home Med Count] >= 6
	THEN 1
	ELSE 0
  END                                    AS [Poly Pharmacy Flag]
, IP.[Days Stay]
, ROUND( 
	CONVERT(FLOAT,VR.drg_std_days_stay) 
, 1)                                    AS [DRG Std Days Stay] 
, ROUND( 
	CONVERT( 
		FLOAT,DATEDIFF( 
		HOUR,  
		IP.[Adm Date Time],  
		IP.[Dsch Date Time] 
		)/24.0 
	 ) 
, 1)                                    AS [True Days Stay] 
, ROUND( 
	( 
	ROUND( 
		CONVERT( 
			FLOAT,DATEDIFF( 
						HOUR 
						, IP.[Adm Date Time] 
						, IP.[Dsch Date Time] 
						)/24.0 
				) 
		, 1) 
	)  
	- 
	VR.drg_std_days_stay  
,1)                                     AS [DRG Opportunity] 
, CASE 
	   WHEN IP.Pt_Age >= 65 THEN 1 
	   ELSE 0 
   END                                   AS [Senior Citizen Flag] 
, IP.[Hospitalist Flag]
, IP.[Readmitted in 30?]
, LIHN.[LIHN_Service_Line] 
, ICUV.[Has ICU Visit]
, LACE.ModfLACEVal
, CASE
	WHEN LACE.ModfLACEVal >= 9 THEN 1
	ELSE 0
  END AS [High Risk Readmit]

FROM #INIT_POP AS IP
LEFT MERGE JOIN #PLYPHARM AS PP 
ON IP.PTNO_NUM = PP.[Visit ID] 
LEFT MERGE JOIN smsmir.vst_rpt AS VR 
ON IP.PTNO_NUM = SUBSTRING(VR.PT_ID , 5, 8)
LEFT MERGE JOIN #LIHNSVCLINE AS LIHN 
ON IP.PTNO_NUM = LIHN.PT_ID
LEFT MERGE JOIN #ICUVISIT AS ICUV
ON IP.PTNO_NUM = ICUV.VISIT_ID
-- GET LACE SCORE
LEFT MERGE JOIN smsdss.ModfLACEFctV AS LACE
ON IP.PTNO_NUM = RIGHT(LACE.PtId,8)

---------------------------------------------------------------------------------------------------
--DROP TABLE STATEMENTS
--DROP TABLE #INIT_POP;
--DROP TABLE #PLYPHARM;
--DROP TABLE #LIHNSVCLINE9;
--DROP TABLE #LIHNSVCLINE10
--DROP TABLE #SVCLINETEMP;
--DROP TABLE #SVCLINETEMP2;
--DROP TABLE #LIHNSVCLINE;
--DROP TABLE #ICUVISIT;