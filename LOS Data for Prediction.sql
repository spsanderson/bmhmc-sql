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
  
 SET @IP_START_DATE = '2013-10-01'; 
 SET @IP_END_DATE = '2015-10-01'; 
  
 DECLARE @INIT_POP TABLE ( 
 ID INT IDENTITY(1, 1) PRIMARY KEY 
 , [Vist ID]           VARCHAR(MAX) 
 , Pt_Sex              VARCHAR(MAX) 
 , Pt_Race             VARCHAR(MAX) 
 , dsch_disp           VARCHAR(MAX) 
 , hosp_svc            VARCHAR(MAX) 
 , Pt_Age              INT 
 , Pt_Zip_Cd           VARCHAR(MAX) 
 , drg_no              VARCHAR(MAX) 
 , drg_cost_weight     FLOAT 
 , [Adm Date Time]     DATETIME 
 , [Dsch Date Time]    DATETIME 
 , [Days Stay]         VARCHAR(MAX) 
 , [Readmitted in 30?] VARCHAR(MAX) 
 , [Discharge Month]   VARCHAR(MAX) 
 , [Discharge Year]    VARCHAR(MAX) 
 , [Hospitalist Flag]  VARCHAR(MAX) 
 ); 
  
 WITH CTE1 AS ( 
	 SELECT 
	 A.PtNo_Num  
	 , A.Pt_Sex 
	 , A.Pt_Race 
	 , A.dsch_disp 
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
	  
	 FROM smsdss.BMH_PLM_PtAcct_V     A 
		 LEFT JOIN smsdss.vReadmits   B 
		 ON A.PtNo_Num = B.[INDEX] 
		 AND B.INTERIM <= 30 -- This ensures that we only get 
		 -- the accounts that are 30 Day 
		 -- RA's 
		 LEFT JOIN smsdss.pract_dim_v C 
		 ON A.Atn_Dr_No = C.src_pract_no 
	  
	 WHERE Dsch_Date >= @IP_START_DATE 
		 AND Dsch_Date < @IP_END_DATE 
		 AND Plm_Pt_Acct_Type = 'I' 
		 AND PtNo_Num < '20000000' 
		 AND Days_Stay > 1 
		 AND C.orgz_cd = 'S0X0' 
 ) 
  
 INSERT INTO @INIT_POP 
 SELECT *
  
 FROM CTE1 C1 
  
 /* 
 This is the end of the query that will get the initial population of  
 interest 
 */ 
  
 /*-------------------------------------------------------------------*/ 
  
 /* 
 This query will pull together if the patient is poly-pharmacy or not 
 */ 
 DECLARE @PLYPHARM TABLE( 
 ID INT IDENTITY(1, 1) PRIMARY KEY 
 , [Patient Name]       VARCHAR(MAX) 
 , [Admit Date Time]    DATETIME 
 , [Med List Type]      VARCHAR(MAX) 
 , [Last Status Update] DATETIME 
 , [Visit ID]           VARCHAR(MAX) 
 , [Home Med Count]     INT 
 ); 
  
 WITH CTE2 AS ( 
	 SELECT  
	 B.rpt_name                        AS [Patient Name] 
	 , B.vst_start_dtime               AS [Admit Date Time] 
	 , A.med_lst_type                  AS [Med List Type] 
	 , B.last_cng_dtime                AS [Last Status Update] 
	 , B.episode_no                    AS [Visit ID] 
	 , CONVERT(INT, COUNT(A.med_name)) AS [Home Med Count] 
	  
	 FROM smsdss.qoc_med A 
		 JOIN smsdss.QOC_vst_summ B 
		 ON A.pref_vst_pms_id_col = B.pref_vst_pms_id_col 
		 JOIN smsdss.BMH_PLM_PtAcct_V C 
		 ON C.PtNo_Num = B.episode_no 
	  
	 WHERE A.med_lst_type = 'HML' 
		 AND C.Plm_Pt_Acct_Type = 'I' 
		 AND C.PtNo_Num < '20000000' 
		 AND C.Dsch_Date >= @IP_START_DATE 
		 AND C.Dsch_Date < @IP_END_DATE 
	  
	 GROUP BY  
		 B.rpt_name 
		 , B.vst_start_dtime 
		 , A.med_lst_type 
		 , B.last_cng_dtime 
		 , B.episode_no 
 ) 
  
 INSERT INTO @PLYPHARM 
 SELECT *
  
 FROM CTE2 C2 
  
 /* 
 This is the end of the poly-pharma query, it will only list those 
 that meet the criterion of being poly-pharmacy 
 */ 
 ----------------------------------------------------------------------
 /* 
 Get the LIHN Service line data, we only want to columns from the data 
 */ 
 DECLARE @LIHNSVCLINE TABLE ( 
ID INT IDENTITY(1, 1)  PRIMARY KEY
 , [Visit ID]          VARCHAR(MAX) 
 , [LIHN Service Line] VARCHAR(MAX) 
 ); 
  
 WITH CTE3 AS ( 
	 SELECT  
	 SUBSTRING(pt_id, PATINDEX('%[^0]%', pt_id), 9) AS pt_id 
	 , LIHN_Svc_Line 
	  
	 FROM  
	 smsdss.c_LIHN_Svc_Lines_Rpt_v 
 ) 
  
 INSERT INTO @LIHNSVCLINE 
 SELECT *
  
 FROM CTE3 C3 
 
 /*
 End of getting LIHN Service Line information
 */
 ----------------------------------------------------------------------
 /* 
 Does the patient have some sort of ICU stay during their visit? 
 */ 
 DECLARE @ICUVISIT TABLE( 
 ID INT IDENTITY(1, 1) PRIMARY KEY
,  [Visit ID] VARCHAR(MAX) 
 , [ICU Flag] VARCHAR(MAX) 
 ); 
  
 WITH CTE4 AS ( 
	 SELECT DISTINCT PVFV.pt_no 
	 , MAX(CASE 
			 WHEN TXFR.NURS_STA IN ('SICU', 'MICU', 'CCU') 
				 THEN 1 
				 ELSE 0 
			 END) 
	 OVER (PARTITION BY PVFV.PT_NO) AS [Has ICU Visit] 
	  
	 FROM smsdss.pms_vst_fct_v PVFV 
		 JOIN smsdss.pms_xfer_actv_fct_v TXFR 
		 ON PVFV.pms_vst_key = TXFR.pms_vst_key 
 ) 
  
 INSERT INTO @ICUVISIT 
 SELECT *
  
 FROM CTE4 
  
 /* 
 ####################################################################### 
 PULL IT ALL TOGETHER HERE 
 ####################################################################### 
 */ 
SELECT  
IP.ID
, IP.[Vist ID]
, IP.Pt_Sex
, IP.Pt_Race
, IP.Pt_Age
, IP.Pt_Zip_Cd
, IP.dsch_disp
, DSCH_DESC_LONG.[Long Discharge Description]
, DSCH_DESC_SHORT.[Short Discharge Description]
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
, LIHN.[LIHN Service Line] 
, ICUV.[ICU Flag]
, LACE.ModfLACEVal
, CASE
	WHEN LACE.ModfLACEVal >= 9 THEN 1
	ELSE 0
  END AS [High Risk Readmit]

FROM @INIT_POP IP 
	LEFT MERGE JOIN @PLYPHARM PP 
	ON IP.[Vist ID] = PP.[Visit ID] 
	LEFT MERGE JOIN smsmir.vst_rpt VR 
	ON IP.[Vist ID] = SUBSTRING(PT_ID, PATINDEX('%[^0]%', pt_id), 9) 
	LEFT MERGE JOIN @LIHNSVCLINE LIHN 
	ON IP.[Vist ID] = LIHN.[Visit ID] 
	LEFT MERGE JOIN @ICUVISIT ICUV 
	ON IP.[Vist ID] = ICUV.[Visit ID]
	-- GET LACE SCORE
	LEFT MERGE JOIN smsdss.ModfLACEFctV AS LACE
	ON IP.[Vist ID] = RIGHT(LACE.PtId,8)

CROSS APPLY (
	SELECT 
		CASE
			WHEN IP.[dsch_disp] = 'AHB' THEN 'Drug/Alcohol Rehab Non-Hospital Facility'
			WHEN IP.[dsch_disp] = 'AHI' THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
			WHEN IP.[dsch_disp] = 'AHR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
			WHEN IP.[dsch_disp] = 'AMA' THEN 'Left Against Medical Advice, Elopement'
			WHEN IP.[dsch_disp] = 'ATB' THEN 'Correctional Institution'
			WHEN IP.[dsch_disp] = 'ATE' THEN 'SNF -Sub Acute'
			WHEN IP.[dsch_disp] = 'ATF' THEN 'Specialty Hospital ( i.e Sloan, Schneiders)'
			WHEN IP.[dsch_disp] = 'ATH' THEN 'Hospital - Med/Surg (i.e Stony Brook)'
			WHEN IP.[dsch_disp] = 'ATL' THEN 'SNF - Long Term'
			WHEN IP.[dsch_disp] = 'ATN' THEN 'Hospital - VA'
			WHEN IP.[dsch_disp] = 'ATP' THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
			WHEN IP.[dsch_disp] = 'ATT' THEN 'Hospice at Home, Adult Home, Assisted Living'
			WHEN IP.[dsch_disp] = 'ATW' THEN 'Home, Adult Home, Assisted Living with Homecare'
			WHEN IP.[dsch_disp] = 'ATX' THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
			WHEN IP.[dsch_disp] = 'C1A' THEN 'Postoperative Death, Autopsy'
			WHEN IP.[dsch_disp] = 'C1N' THEN 'Postoperative Death, No Autopsy'
			WHEN IP.[dsch_disp] = 'C1Z' THEN 'Postoperative Death, Autopsy Unknown'
			WHEN IP.[dsch_disp] = 'C2A' THEN 'Surgical Death within 48hrs Post Surgery, Autopsy'
			WHEN IP.[dsch_disp] = 'C2N' THEN 'Surgical Death within 48hrs Post Surgery, No Autopsy'
			WHEN IP.[dsch_disp] = 'C2Z' THEN 'Surgical Death within 48hrs Post Surgery, Autopsy Unknown'
			WHEN IP.[dsch_disp] = 'C3A' THEN 'Surgical Death within 3-10 days Post Surgery, Autopsy'
			WHEN IP.[dsch_disp] = 'C3N' THEN 'Surgical Death within 3-10 days Post Surgery, No Autopsy'
			WHEN IP.[dsch_disp] = 'C3Z' THEN 'Surgical Death within 3-10 days Post Surgery, Autopsy Unknown'
			WHEN IP.[dsch_disp] = 'C4A' THEN 'Died in O.R, Autopsy'
			WHEN IP.[dsch_disp] = 'C4N' THEN 'Died in O.R, No Autopsy'
			WHEN IP.[dsch_disp] = 'C4Z' THEN 'Died in O.R., Autopsy Unknown'
			WHEN IP.[dsch_disp] = 'C7A' THEN 'Other Death, Autopsy'
			WHEN IP.[dsch_disp] = 'C7N' THEN 'Other Death, No Autopsy'
			WHEN IP.[dsch_disp] = 'C7Z' THEN 'Other Death, Autopsy Unknown'
			WHEN IP.[dsch_disp] = 'C8A' THEN 'Nonsurgical Death within 48hrs of Admission, Autopsy'
			WHEN IP.[dsch_disp] = 'C8N' THEN 'Nonsurgical Death within 48hrs of Admission, No Autopsy'
			WHEN IP.[dsch_disp] = 'C8Z' THEN 'Nonsurgical Death within 48hrs of Admission, Autopsy Unknown'
			WHEN IP.[dsch_disp] = 'D1A' THEN 'Postoperative Death, Autopsy'
			WHEN IP.[dsch_disp] = 'D1N' THEN 'Postoperative Death, No Autopsy'
			WHEN IP.[dsch_disp] = 'D1Z' THEN 'Postoperative Death, Autopsy Unknown'
			WHEN IP.[dsch_disp] = 'D2A' THEN 'Surgical Death within 48hrs Post Surgery, Autopsy'
			WHEN IP.[dsch_disp] = 'D2N' THEN 'Surgical Death within 48hrs Post Surgery, No Autopsy'
			WHEN IP.[dsch_disp] = 'D2Z' THEN 'Surgical Death within 48hrs Post Surgery, Autopsy Unknown'
			WHEN IP.[dsch_disp] = 'D3A' THEN 'Surgical Death within 3-10 days Post Surgery, Autopsy'
			WHEN IP.[dsch_disp] = 'D3N' THEN 'Surgical Death within 3-10 days Post Surgery, No Autopsy'
			WHEN IP.[dsch_disp] = 'D3Z' THEN 'Surgical Death within 3-10 days Post Surgery, Autopsy Unknown'
			WHEN IP.[dsch_disp] = 'D4A' THEN 'Died in O.R, Autopsy'
			WHEN IP.[dsch_disp] = 'D4N' THEN 'Died in O.R, No Autopsy'
			WHEN IP.[dsch_disp] = 'D4Z' THEN 'Died in O.R., Autopsy Unknown'
			WHEN IP.[dsch_disp] = 'D7A' THEN 'Other Death, Autopsy'
			WHEN IP.[dsch_disp] = 'D7N' THEN 'Other Death, No Autopsy'
			WHEN IP.[dsch_disp] = 'D7Z' THEN 'Other Death, Autopsy Unknown'
			WHEN IP.[dsch_disp] = 'D8A' THEN 'Nonsurgical Death within 48hrs of Admission, Autopsy'
			WHEN IP.[dsch_disp] = 'D8N' THEN 'Nonsurgical Death within 48hrs of Admission, No Autopsy'
			WHEN IP.[dsch_disp] = 'D8Z' THEN 'Nonsurgical Death within 48hrs of Admission, Autopsy Unknown'
		END AS 'Long Discharge Description'
) DSCH_DESC_LONG

CROSS APPLY(
	SELECT
		CASE
			WHEN IP.[dsch_disp] = 'AHB' THEN 'Drug/Alcohol Rehab Non-Hospital Facility'
			WHEN IP.[dsch_disp] = 'AHI' THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
			WHEN IP.[dsch_disp] = 'AHR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
			WHEN IP.[dsch_disp] = 'AMA' THEN 'Left Against Medical Advice, Elopement'
			WHEN IP.[dsch_disp] = 'ATB' THEN 'Correctional Institution'
			WHEN IP.[dsch_disp] = 'ATE' THEN 'SNF -Sub Acute'
			WHEN IP.[dsch_disp] = 'ATF' THEN 'Specialty Hospital ( i.e Sloan, Schneiders)'
			WHEN IP.[dsch_disp] = 'ATH' THEN 'Hospital - Med/Surg (i.e Stony Brook)'
			WHEN IP.[dsch_disp] = 'ATL' THEN 'SNF - Long Term'
			WHEN IP.[dsch_disp] = 'ATN' THEN 'Hospital - VA'
			WHEN IP.[dsch_disp] = 'ATP' THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
			WHEN IP.[dsch_disp] = 'ATT' THEN 'Hospice at Home, Adult Home, Assisted Living'
			WHEN IP.[dsch_disp] = 'ATW' THEN 'Home, Adult Home, Assisted Living with Homecare'
			WHEN IP.[dsch_disp] = 'ATX' THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
			WHEN IP.[dsch_disp] = 'C1A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C1N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C1Z' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C2A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C2N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C2Z' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C3A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C3N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C3Z' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C4A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C4N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C4Z' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C7A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C7N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C7Z' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C8A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C8N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'C8Z' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D1A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D1N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D1Z' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D2A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D2N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D2Z' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D3A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D3N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D3Z' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D4A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D4N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D4Z' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D7A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D7N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D7Z' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D8A' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D8N' THEN 'Death'
			WHEN IP.[dsch_disp] = 'D8Z' THEN 'Death'
		END AS 'Short Discharge Description'
) DSCH_DESC_SHORT

WHERE IP.drg_cost_weight IS NOT NULL 
	AND ICUV.[ICU Flag] IS NOT NULL 
  
ORDER BY IP.[Dsch Date Time] ASC 
