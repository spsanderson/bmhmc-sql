/*
This query will get our initial population of interest wherin we would
like to try and predict the length of stay of any given patient within
a specified service line.
*/
SET ANSI_NULLS OFF
GO

-- Variable declaration
DECLARE @IP_START_DATE DATE;
DECLARE @IP_END_DATE   DATE;

SET @IP_START_DATE = '2012-06-01';
SET @IP_END_DATE   = '2014-05-01';

DECLARE @INIT_POP TABLE (
	  ID                  INT IDENTITY(1, 1) PRIMARY KEY
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
	, [Discharge YYYY-M]  VARCHAR(MAX)
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
		, CONVERT(INT, A.Days_Stay)       AS [Days Stay]
		, CASE
			WHEN B.[READMIT] IS NULL
			THEN 0
			ELSE 1
		  END                             AS [Readmitted in 30?]
		, DATEPART(MONTH, A.DSCH_DATE)    AS [Discharge Month]
		, DATEPART(YEAR, A.Dsch_Date)     AS [Discharge Year]
		, (
		CAST(DATEPART(YEAR, A.DSCh_DATE)  AS VARCHAR(MAX)) + '-' +
		CAST(DATEPART(MONTH, A.DSCH_DATE) AS VARCHAR(MAX))
		)	                              AS [Discharge YYYY-M]
		, CASE
			WHEN C.src_spclty_cd = 'HOSIM'
			THEN 1
			ELSE 0
		  END                             AS [Hospitalist Flag]

	FROM smsdss.BMH_PLM_PtAcct_V       A
		LEFT JOIN smsdss.vReadmits     B
		ON A.PtNo_Num = B.[INDEX]
			AND B.INTERIM <= 30        -- This ensures that we only get
			                           -- the accounts that are 30 Day
			                           -- RA's
		LEFT JOIN smsdss.pract_dim_v   C
		ON A.Atn_Dr_No = C.src_pract_no
		
	WHERE Dsch_Date >= @IP_START_DATE
		AND Dsch_Date < @IP_END_DATE
		AND Plm_Pt_Acct_Type = 'I'
		AND PtNo_Num < '20000000'
		AND Days_Stay > 1
		AND C.orgz_cd = 'S0X0'
)

INSERT INTO @INIT_POP
SELECT
	  C1.PtNo_Num
	, C1.Pt_Sex
	, C1.Pt_Race
	, C1.dsch_disp
	, C1.hosp_svc
	, C1.Pt_Age
	, C1.Pt_Zip_Cd
	, C1.drg_no
	, C1.drg_cost_weight
	, C1.[Adm Date Time]
	, C1.[Dsch Date Time]
	, ROUND(C1.[Days Stay], 1)
	, C1.[Readmitted in 30?]
	, C1.[Discharge Month]
	, C1.[Discharge Year]
	, C1.[Discharge YYYY-M]
	, C1.[Hospitalist Flag]

FROM CTE1 C1

-- Select out the data
--SELECT * 
--FROM @INIT_POP IP
--ORDER BY IP.[Dsch Date] ASC

/*
This is the end of the query that will get the initial population of 
interest
*/

/*-------------------------------------------------------------------*/

/*
This query will pull together if the patient is poly-pharmacy or not
*/
DECLARE @PLYPHARM TABLE(
	ID INT IDENTITY(1, 1)  PRIMARY KEY
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

	FROM smsdss.qoc_med                 A
		JOIN smsdss.QOC_vst_summ        B
		ON A.pref_vst_pms_id_col = B.pref_vst_pms_id_col
		JOIN smsdss.BMH_PLM_PtAcct_V    C
		ON C.PtNo_Num = B.episode_no

	WHERE 
		A.med_lst_type = 'HML'
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

	HAVING COUNT(A.MED_NAME) >= 6
)

INSERT INTO @PLYPHARM
SELECT
	C2.[Patient Name]
	, C2.[Admit Date Time]
	, C2.[Med List Type]
	, C2.[Last Status Update]
	, C2.[Visit ID]
	, C2.[Home Med Count]

FROM CTE2 C2

-- SELECT OUT THE DATA
--SELECT *
--FROM @PLYPHARM PP
--order by PP.[Admit Date Time] asc

/*
This is the end of the poly-pharma query, it will only list those
that meet the criterion of being poly-pharmacy
*/

/*
Get the LIHN Service line data, we only want to columns from the data
*/
DECLARE @LIHNSVCLINE TABLE (
	[Visit ID]            VARCHAR(MAX)
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
SELECT
	C3.pt_id
	, C3.LIHN_Svc_Line
	
FROM CTE3 C3


/*
Does the patient have some sort of ICU stay during their visit?
*/
DECLARE @ICUVISIT TABLE(
	[Visit ID]   VARCHAR(MAX)
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

	FROM smsdss.pms_vst_fct_v                   PVFV
		JOIN smsdss.pms_xfer_actv_fct_v         TXFR
		ON PVFV.pms_vst_key = TXFR.pms_vst_key
)

INSERT INTO @ICUVISIT
SELECT 
	CTE4.pt_no
	, CTE4.[Has ICU Visit]
	
FROM CTE4

--SELECT * FROM @ICUVISIT


/*
#######################################################################
PULL IT ALL TOGETHER HERE
#######################################################################
*/
SELECT 
	IP.*
	, ISNULL(PP.[Med List Type], 'No HML') AS [Home Med List]
	, CASE
		WHEN PP.[Home Med Count] IS NULL
		THEN 0
		ELSE 1
	  END                                  AS [Poly Pharmacy]
	, CASE
		WHEN IP.drg_cost_weight < 1    THEN 0
		WHEN IP.drg_cost_weight >= 1
			AND IP.drg_cost_weight < 2 THEN 1
		WHEN IP.drg_cost_weight >= 2
			AND IP.drg_cost_weight < 3 THEN 2
		WHEN IP.drg_cost_weight >= 3
			AND IP.drg_cost_weight < 4 THEN 3
		WHEN IP.drg_cost_weight >= 4   THEN 4
	  END                                  AS [DRG Weight Bin]
	, ROUND(
		CONVERT(FLOAT,VR.drg_std_days_stay)
		, 1)                               AS [DRG Std Days Stay]
	, ROUND(
		CONVERT(
			FLOAT,DATEDIFF(
						HOUR, 
						IP.[Adm Date Time], 
						IP.[Dsch Date Time]
						)/24.0
				)
			, 1)                           AS [True Days Stay]
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
	, LIHN.[LIHN Service Line]
	, ICUV.[ICU Flag]
	, DATEPART(WEEKDAY, IP.[ADM DATE TIME])  AS [Adm DOW]
	, DATEPART(MONTH, IP.[ADM DATE TIME])    AS [Adm Month]
	, DATEPART(YEAR, IP.[ADM DATE TIME])     AS [Adm Year]
	, DATEPART(HOUR, IP.[ADM DATE TIME])     AS [Adm Hour]
	, DATEPART(WEEKDAY, IP.[Dsch Date Time]) AS [Dsch DOW]
	, DATEPART(MONTH, IP.[DSCH DATE TIME])   AS [Dsch Month]
	, DATEPART(YEAR, IP.[DSCH DATE TIME])    AS [Dsch Year]
	, DATEPART(HOUR, IP.[DSCH DATE TIME])    AS [Dsch Hour]

FROM @INIT_POP IP
	LEFT MERGE JOIN @PLYPHARM                     PP
	ON IP.[Vist ID] = PP.[Visit ID]
	LEFT MERGE JOIN smsmir.vst_rpt                VR
	ON IP.[Vist ID] = SUBSTRING(PT_ID, PATINDEX('%[^0]%', pt_id), 9)
	LEFT MERGE JOIN @LIHNSVCLINE                  LIHN
	ON IP.[Vist ID] = LIHN.[Visit ID]
	LEFT MERGE JOIN @ICUVISIT                     ICUV
	ON IP.[Vist ID] = ICUV.[Visit ID]
	
WHERE IP.drg_cost_weight IS NOT NULL
	AND ICUV.[ICU Flag] IS NOT NULL
	
ORDER BY IP.[Dsch Date Time] ASC