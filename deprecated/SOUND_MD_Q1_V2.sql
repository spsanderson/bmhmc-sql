/*SOUND_MD_Q1_version_2*/
/*
THIS REPORT IS FOR SOUND PHYSICIAN, IT WILL BE USED ON A MONTHLY
BASIS GOING FORWARD IN ORDER FOR THEIR INTERNAL BENCHMARKING
*/
SET ANSI_NULLS OFF
GO
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME;
DECLARE @ED DATETIME;
DECLARE @CP_1 INT;
DECLARE @CP_2 INT;
DECLARE @CP_3 INT;
DECLARE @SCT VARCHAR(10);
DECLARE @CDSCHM VARCHAR(10);

SET @SD = '2015-01-01';
SET @ED = '2015-09-30';
SET @CP_1 = 1;
SET @CP_2 = 2;
SET @CP_3 = 3;
SET @SCT = 'DF';
SET @CDSCHM = 9;

/*
-----------------------------------------------------------------------
THIS QUERY WILL GET ALL THE FRONT END INFORMATION REQUIRED FOR HOSIM
AND INSERT IT INTO A TABLE THAT WILL GET MATCHED UP WITH THE DISCHARGE
ORDERS TABLE. WE WILL ONLY GET RESULTS BACK ON THOSE PATIETNS THAT WERE
ADMITTED AND ATTENDED TO BY A HOSPITALIST
-----------------------------------------------------------------------
START OF QUERY 1
-----------------------------------------------------------------------
*/
-- TABLE DECLARATION
DECLARE @T1 TABLE (
	Acct_No                      VARCHAR (200)
	, /*NEW*/Med_Rec_No          VARCHAR (20)	
	, /*NEW*/Date_Of_Birth       DATETIME
	, /*NEW*/Gender              VARCHAR (10)
	, FinancialClass_Code        VARCHAR (10)
	, FinancialClass_Defin       VARCHAR (200)
	, Admiss_Date                DATE
	, Admiss_Time                TIME
	, Admit_From_Code            VARCHAR (200)
	, Admit_From_Defin           VARCHAR (200)
	, Discharge_Date             DATE
	, Discharge_Time             TIME
	, /*NEW*/Admitting_Phys      VARCHAR (200)
	, /*NEW*/Attending_Phys      VARCHAR (200)
	/*Discharging_Phys - can't get*/
	, DC_Dispo_Code              VARCHAR (10)
	, DC_Dispo_Defin             VARCHAR (200)
	, [MS DRG]                   VARCHAR (200)
	, MSDRG_Descript             VARCHAR (200)
	, LOS                        VARCHAR (20)
	, [ADMIT PATIENT STATUS]     VARCHAR (10)
	, [DISCHARGE PATIENT STATUS] VARCHAR (10)
	, [DISCHARGE UNIT]           VARCHAR (200) -- NOT NEEDED FOR FINAL QUERY JUST BASELINE
)
-- WHAT GETS INSERTED INTO @T1
INSERT INTO @T1
SELECT
A.[VISIT ID]
, A.MRN
, A.DOB
, A.GENDER
, A.[FINANCIAL CLASS CODE]
, A.FINANCIALCLASSORIG
, A.[ADMIT DATE]
, A.[ADMIT TIME]
, A.[ADMIT FROM]
, A.[ADMIT DESC]
, A.[DISCHARGE DATE]
, A.[DISCHARGE TIME]
, A.[ADMITTING DR]
, A.[ATTENDING DR]
/*Discharging_Phys - can't get*/
, A.[DISCHARGE DISP CODE]
, A.[DISCHARGE DISPOSITION]
, A.[MS DRG]
, A.[DRG NAME]
, A.LOS
, A.[ADMIT PATIENT STATUS]
, A.[DISCHARGE PATIENT STATUS]
, A.[DISCHARGE UNIT]
-- END @T1 INSERT SELECTION

-- WHERE IT ALL COMES FROM
-- COLUMN SELECTION
FROM (
	SELECT DISTINCT PAV.PtNo_Num        AS [VISIT ID]
	, /*NEW*/PAV.Med_Rec_No             AS MRN
	, /*NEW*/PAV.Pt_Birthdate           AS DOB
	, /*NEW*/PAV.Pt_Sex                 AS GENDER
	, /*NEW*/PAV.Pyr1_Co_Plan_Cd        AS [FINANCIAL CLASS CODE]
	, PD.pyr_name                       AS [FINANCIALCLASSORIG]
	, CAST(PAV.Adm_Date AS DATE)        AS [ADMIT DATE]
	, CAST(PAV.vst_start_dtime AS TIME) AS [ADMIT TIME]
	, PAV.Adm_Source                    AS [ADMIT FROM]
	, ASDV.adm_src_cd_desc              AS [ADMIT DESC]
	, CAST(PAV.Dsch_Date AS DATE)       AS [DISCHARGE DATE]
	, CAST(PAV.Dsch_DTime AS TIME)      AS [DISCHARGE TIME]
	, /*NEW*/PDV.pract_rpt_name         AS [ADMITTING DR]
	, /*NEW*/PDVB.pract_rpt_name        AS [ATTENDING DR]
	/*Discharging_Phys - can't get*/
	, PAV.drg_no                        AS [MS DRG]
	, /*NEW*/DRG.drg_name_modf          AS [DRG NAME]
	, PAV.Days_Stay                     AS [LOS]
	, 'I'                               AS [ADMIT PATIENT STATUS]
	, 'I'                               AS [DISCHARGE PATIENT STATUS]
	, PAV.dsch_disp                     AS [DISCHARGE DISP CODE]
	, DDM.dsch_disp_desc                AS [DISCHARGE DISPOSITION]
	, VR.ward_cd                        AS [DISCHARGE UNIT]

	-- FROM DB(S)                          -- Alias
	FROM smsdss.BMH_PLM_PtAcct_V              PAV
	     JOIN smsdss.pract_dim_v              PDV
	     ON PAV.Adm_Dr_No = PDV.src_pract_no
	     /*GET SECOND DR NAME*/
	     JOIN smsdss.pract_dim_v              PDVB
	     ON PAV.Atn_Dr_No = PDVB.src_pract_no
	     /*END*/
	     JOIN smsdss.pyr_dim                  PD
	     ON PAV.Pyr1_Co_Plan_Cd = PD.pyr_cd
	     JOIN smsmir.vst_rpt                  VR
	     ON PAV.PtNo_Num = VR.acct_no
	     JOIN smsdss.dsch_disp_mstr           DDM
	     ON VR.dsch_disp = DDM.dsch_disp
	     JOIN smsdss.adm_src_dim_v            ASDV
	     ON PAV.Adm_Source = ASDV.src_adm_src
	     JOIN smsdss.drg_dim_v                DRG
	     ON PAV.drg_no = DRG.drg_no

	-- FILTER(S)
	WHERE PAV.Dsch_Date >= @SD 
	AND PAV.Dsch_Date < @ED
	AND PAV.Plm_Pt_Acct_Type = 'I'
	AND PAV.PtNo_Num < '20000000'
	/*
	WE WILL ONLY GET RECORDS BACK WHERE BOTH THE ADMITTING
	AND ATTENDING WERE HOSPITALISTS
	*/
	AND PDV.src_spclty_cd = 'HOSIM'
	AND PDV.orgz_cd = 'S0X0'
	AND PDVB.src_spclty_cd = 'HOSIM'
	AND PDVB.orgz_cd = 'S0X0'
	/*
	END
	*/
	AND PD.orgz_cd = 'S0X0'
	AND PD.pyr_name != '?'
	/*
	ADMIT SOURCE DIM V RESTRICTIONS
	*/
	AND ASDV.orgz_cd = 'S0X0'
	/*DRG RESTRICTIONS*/
	AND DRG.drg_vers = 'MS-V25'
) A

--SELECT * FROM @T1

/*
########################################################################

THIS WILL GET THE ICD9 INFORMATION

########################################################################
*/
DECLARE @ICD9_1 TABLE (
PtNo_Num VARCHAR(20)
, ICD_1  VARCHAR(10)
)

INSERT INTO @ICD9_1
SELECT 
B.PtNo_Num
, B.CLASFCD_1
	
FROM (
	SELECT DISTINCT PtNo_Num,
	ClasfCd AS CLASFCD_1

	FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V

	WHERE ClasfPrio = @CP_1
	AND SortClasfType = @SCT
	AND ClasfSch = @CDSCHM
) B

--SELECT * FROM @ICD9_1

-----------------------------------------------------------------------
DECLARE @ICD9_2 TABLE (
PtNo_Num VARCHAR(20)
, ICD_2  VARCHAR(10)
)

INSERT INTO @ICD9_2
SELECT 
C.PtNo_Num
, C.CLASFCD_2

FROM (
	SELECT DISTINCT PtNo_Num,
	ClasfCd AS CLASFCD_2

	FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V

	WHERE ClasfPrio = @CP_2
	AND SortClasfType = @SCT
	AND ClasfSch = @CDSCHM
) C

--SELECT * FROM @ICD9_2

-----------------------------------------------------------------------
DECLARE @ICD9_3 TABLE (
PtNo_Num VARCHAR(20)
, ICD_3  VARCHAR(10)
)

INSERT INTO @ICD9_3
SELECT 
D.PtNo_Num
, D.CLASFCD_3

FROM (
	SELECT DISTINCT PtNo_Num,
	ClasfCd AS CLASFCD_3

	FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V

	WHERE ClasfPrio = @CP_3
	AND SortClasfType = @SCT
	AND ClasfSch = @CDSCHM
) D

--SELECT * FROM @ICD9_3

-----------------------------------------------------------------------
DECLARE @ICD9F TABLE(
PTNO_NUM VARCHAR(20)
, ICD9_1 VARCHAR(10)
, ICD9_2 VARCHAR(10)
, ICD9_3 VARCHAR(10)
)

INSERT INTO @ICD9F
SELECT
E.PTNO_NUM
, E.ICD9_1
, E.ICD9_2
, E.ICD9_3

FROM (
	SELECT PV.PtNo_Num
	, ICD9_1.ICD_1 AS ICD9_1
	, ICD9_2.ICD_2 AS ICD9_2
	, ICD9_3.ICD_3 AS ICD9_3

	FROM smsdss.BMH_PLM_PtAcct_V PV
		LEFT JOIN @ICD9_1 ICD9_1
		ON PV.PtNo_Num = ICD9_1.PtNo_Num
		LEFT JOIN @ICD9_2 ICD9_2
		ON PV.PtNo_Num = ICD9_2.PtNo_Num
		LEFT JOIN @ICD9_3 ICD9_3
		ON PV.PtNo_Num = ICD9_3.PtNo_Num

	WHERE PV.Dsch_Date >= @SD
	AND PV.Dsch_Date < @ED
	AND PV.Plm_Pt_Acct_Type = 'I'
	AND PV.PtNo_Num < '20000000'
) E

--SELECT * FROM @ICD9F
-----------------------------------------------------------------------

/*
#######################################################################

GET DISCHARGE ORDER DATE AND TIME

#######################################################################
*/

-- @T2 DECLARATION
DECLARE @T2 TABLE (
	[ENCOUNTER ID]   VARCHAR(200)
	, [ORDER NUMBER] VARCHAR(200)
	, [ORDER DATE]   DATE
	, [ORDER TIME]   TIME
)

-- WHAT GETS INSERTED INTO @T2
INSERT INTO @T2
SELECT
B.episode_no
, B.ord_no
, B.DATE
, B.TIME


-- WHERE IT ALL COMES FROM
FROM (
	SELECT EPISODE_NO
	, ORD_NO
	, CAST(ENT_DTIME AS DATE) AS [DATE]
	, CAST(ENT_DTIME AS TIME) AS [TIME]
	, ROW_NUMBER() OVER(
						PARTITION BY EPISODE_NO ORDER BY ORD_NO DESC
						) AS ROWNUM
	FROM smsmir.sr_ord
	WHERE svc_desc = 'DISCHARGE TO'
	AND episode_no < '20000000'
) B

WHERE B.ROWNUM = 1

--SELECT * FROM @T2
-----------------------------------------------------------------------

/*
#######################################################################
HAS ICU VISIT Y/N
#######################################################################
*/

/*DECLARE @T3 TABLE (
	[ENCOUNTER 3]     VARCHAR(200)
	, [HAS ICU VISIT] VARCHAR(10)
)
-- WHAT GETS INSERTED INTO @T3
INSERT INTO @T3
SELECT
C.pt_no
,C.HAS_ICU_VISIT

-- WHERE IT ALL COMES FROM
FROM (
	SELECT DISTINCT PVFV.pt_no
	, MAX(CASE
			WHEN TXFR.NURS_STA IN ('SICU','MICU','CCU')
			THEN 'Y'
			ELSE 'N'
		  END)
		  OVER (PARTITION BY PVFV.PT_NO) AS HAS_ICU_VISIT

	FROM @T1 T1
	JOIN smsdss.pms_vst_fct_v PVFV
	ON T1.Acct_No = PVFV.pt_no
	JOIN SMSDSS.PMS_XFER_ACTV_FCT_V TXFR
	ON PVFV.pms_vst_key = TXFR.pms_vst_key

WHERE PVFV.vst_end_date BETWEEN @SD AND @ED
) C*/

/*
#######################################################################
DOES THE PATIENT HAVE OBSERVATION TIME?
#######################################################################
*/
-- T4 DECLARATION
DECLARE @T4 TABLE (
	[PT ID]    VARCHAR(20)
	, [OBV CD] VARCHAR(10)
)

-- WHAT GETS INSERTED INTO @T4
INSERT INTO @T4
SELECT
D.PtNo_Num
, D.Obv_Svc_Cd

-- WHERE IT ALL COMES FROM
FROM (
	SELECT PAV2.PtNo_Num
	, OBV.Obv_Svc_Cd
	
	FROM 
	smsdss.BMH_PLM_PtAcct_V      PAV2
	LEFT OUTER JOIN
	smsdss.c_obv_Comb_1          OBV
	ON PAV2.PtNo_Num = OBV.pt_id
	
	WHERE OBV.pt_id < 20000000
) D

/*
#######################################################################

PULL IT ALL TOGETHER

#######################################################################
*/

SELECT
T1.Med_Rec_No
, T1.Acct_No
, T1.Date_Of_Birth
, T1.Gender
, T1.FinancialClass_Code
, T1.FinancialClass_Defin
, T1.Admiss_Date
, T1.Admiss_Time
, T1.Admit_From_Code            AS Admiss_From_Code
, T1.Admit_From_Defin           AS Admiss_From_Defin
, T1.Discharge_Date
, T1.Discharge_Time
, T1.Admitting_Phys
, T1.Attending_Phys
, T2.[ORDER DATE]               AS DC_Order_Date
, T2.[ORDER TIME]               AS DC_Order_Time
, T1.DC_Dispo_Code
, T1.DC_Dispo_Defin
--, T1.[DISCHARGE UNIT] AS Discharge_Unit
, T1.[MS DRG]                   AS MSDRG_Code
, T1.MSDRG_Descript
, ICD9F.ICD9_1                  AS ICD_1
, ICD9F.ICD9_2                  AS ICD_2
, ICD9F.ICD9_3                  AS ICD_3
, T1.LOS                        AS LengthofStay
, T1.[ADMIT PATIENT STATUS]     AS PtStatus_Admiss
, T1.[DISCHARGE PATIENT STATUS] AS PtStatus_Discharge
--, T3.[HAS ICU VISIT] AS ICU_Stay
, CASE
	WHEN T4.[OBV CD] IS NULL
		THEN 'NO OBS'
	WHEN T4.[OBV CD] = 'ADT11'
		THEN 'OBS'
	ELSE NULL
  END                           AS Observation_Status


FROM @T1 T1
	LEFT OUTER JOIN @ICD9F ICD9F
	ON T1.Acct_No = ICD9F.PTNO_NUM
	LEFT OUTER JOIN @T2 T2
	ON T1.Acct_No = T2.[ENCOUNTER ID]
	/*
	LEFT OUTER JOIN @T3 T3
	ON T1.Acct_No = T3.[ENCOUNTER 3]
	*/
	LEFT OUTER JOIN @T4 T4
	ON T1.Acct_No = T4.[PT ID]
	
/* 
CHANGE LOG

10-08-2015 - Steven Sanderson
Change note ** - Added a new variable [ DECLARE @CDSCHM VARCHAR(10); ]
setting it equal to 9 in order to get just the ICD-9 code for the patient.
Will reach out to Sound to see if they also want the ICD-10 codes sent
to them.

10-09-2015 - Steven Sanderson
Change note ** - Added in a select statement into table 1 @T1 that will
show if the patint had any observation time before they were admitted
into the hospital.

10-12-2015 - Steven Sanderson
Change note ** - Using smsdss.c_obv_Combo_1 instead of smsdss.c_er_tracking
*/