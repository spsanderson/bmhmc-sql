/*
COPD patient population for DSRIP sub-program MAX (Medicaid Accelerated Exchangt)
The MRN's have been defined already, so some of the queries will use specified MRNs
or hae the ability to filter on the MRN
*/

/*
Profile Data
*/
DECLARE @PT_DEMOGRAPHICS_TBL TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Med_Rec_no          VARCHAR(8)
	, PtNo_Num            VARCHAR(12)
	, PT_Age_Today        INT
	, Pt_Age_at_Visit     INT
	, Pt_Sex              VARCHAR(1)
	, Pt_Race             VARCHAR(1)
	, marital_sts_desc    VARCHAR(15)
	, addr_line1          VARCHAR(MAX)
	, Pt_Addr_Line2       VARCHAR(MAX)
	, Pt_Addr_City        VARCHAR(MAX)
	, Pt_Addr_State       VARCHAR(MAX)
	, Pt_Addr_Zip         VARCHAR(MAX)
	, Pt_Phone_No         VARCHAR(MAX)
	, Pt_Employer         VARCHAR(MAX)
	, Pt_Emp_Addr1        VARCHAR(MAX)
	, Pt_Emp_Addr2        VARCHAR(MAX)
	, Pt_Emp_Addr_City    VARCHAR(MAX)
	, Pt_Emp_Addr_State   VARCHAR(MAX)
	, Pt_Emp_Addr_Zip     VARCHAR(MAX)
	, Pt_Emp_Phone_No     VARCHAR(MAX)
	, Pyr1_Co_Plan_Cd     VARCHAR(MAX)
	, User_Pyr1_Cat       VARCHAR(MAX)
	, Pyr2_Co_Plan_Cd     VARCHAR(MAX)
	, fc                  VARCHAR(MAX)
	, Type_of_Insurance   VARCHAR(MAX)
	, visit_start_dtime   DATETIME
	, RN                  INT

)

INSERT INTO @PT_DEMOGRAPHICS_TBL
SELECT A.*
FROM (
	SELECT A.Med_Rec_No
	, A.PtNo_Num
	, ROUND(
		DATEDIFF(YEAR, 
				A.Pt_Birthdate, 
				GETDATE()), 
			2)                   AS [Pt_Age_Today]
	, A.Pt_Age                   AS Pt_Age_at_Visit
	, A.Pt_Sex
	, A.Pt_Race
	, B.marital_sts_desc
	, B.addr_line1
	, B.Pt_Addr_Line2
	, B.Pt_Addr_City
	, B.Pt_Addr_State
	, B.Pt_Addr_Zip
	, B.Pt_Phone_No
	, C.Pt_Employer
	, C.Pt_Emp_Addr1
	, C.Pt_Emp_Addr2
	, C.Pt_Emp_Addr_City
	, C.Pt_Emp_Addr_State
	, C.Pt_Emp_Addr_Zip
	, C.Pt_Emp_Phone_No
	, A.Pyr1_Co_Plan_Cd
	, A.User_Pyr1_Cat
	, A.Pyr2_Co_Plan_Cd
	, A.fc
	, INS.Type_of_Insurance
	, A.vst_start_dtime
	, RN = ROW_NUMBER() OVER(PARTITION BY A.MED_REC_NO ORDER BY A.VST_START_DTIME)

	FROM [smsdss].[BMH_PLM_PTACCT_V]                      A
	LEFT OUTER JOIN [smsdss].[c_patient_demos_v]          B
	ON A.Pt_No = B.pt_id
	LEFT OUTER JOIN [smsdss].[c_patient_employer_demos_v] C
	ON A.Pt_No = C.pt_id
		AND A.pt_id_start_dtime = C.pt_id_start_dtime

	CROSS APPLY (
		SELECT
			CASE
				WHEN A.fc = 'A' THEN 'MEDICARE'
				WHEN A.fc = 'B' THEN 'BLUE CROSS'
				WHEN A.fc = 'C' THEN 'WORKERS COMP'
				WHEN A.fc = 'D' THEN 'SELF PAY'
				WHEN A.fc = 'E' THEN 'SELF PAY'
				WHEN A.fc = 'F' THEN 'Section 1011'
				WHEN A.fc = 'G' THEN 'SELF PAY'
				WHEN A.fc = 'H' THEN 'SELF PAY'
				WHEN A.fc = 'I' THEN 'MEDICAID HMO'
				WHEN A.fc = 'J' THEN 'SELF PAY'
				WHEN A.fc = 'K' THEN 'HMO'
				WHEN A.fc = 'L' THEN 'Care Payment'
				WHEN A.fc = 'M' THEN 'BLUE CROSS'
				WHEN A.fc = 'N' THEN 'NO FAULT'
				WHEN A.fc = 'P' THEN 'SELF PAY'
				WHEN A.fc = 'Q' THEN 'SELF PAY'
				WHEN A.fc = 'R' THEN 'SELF PAY'
				WHEN A.fc = 'T' THEN 'SELF PAY'
				WHEN A.fc = 'U' THEN 'SELF PAY'
				WHEN A.fc = 'W' THEN 'MEDICAID'
				WHEN A.fc = 'X' THEN 'COMM INSURANCE'
				WHEN A.fc = 'Y' THEN 'SELF PAY'
				WHEN A.fc = 'Z' THEN 'MEDICARE'
			END AS [Type_of_Insurance]
	) INS
 

	WHERE A.Med_Rec_No IN (

	)

	--ORDER BY A.Med_Rec_No
	--, A.vst_start_dtime
) A

SELECT A.* 

FROM @PT_DEMOGRAPHICS_TBL     A
INNER JOIN (
	SELECT Med_Rec_no, MAX(RN) AS Last_Known_Address
	FROM @PT_DEMOGRAPHICS_TBL
	GROUP BY Med_Rec_no
	)                         B
ON A.Med_Rec_no = B.Med_Rec_no
	AND A.RN = B.Last_Known_Address

ORDER BY A.Med_Rec_no
, A.visit_start_dtime


/*

Emergency Room Visit Counts -------------------------------------------

*/

DECLARE @SD DATETIME
DECLARE @ED DATETIME
SET @SD = '2015-01-01';
SET @ED = '2015-10-01';

DECLARE @ER_VISIT_COUNT TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN            VARCHAR(MAX)
	, VISIT_ID       VARCHAR(MAX)
	, VISIT_DATE     DATETIME
	, ED_VISIT_COUNT INT
)

INSERT INTO @ER_VISIT_COUNT
SELECT
A.MRN
, A.VISIT_ID
, A.VISIT_DATE
, [ED Visit Count] = ROW_NUMBER() OVER(PARTITION BY MRN ORDER BY VISIT_DATE)

FROM
(
	SELECT MED_REC_NO AS MRN
	, PtNo_Num AS VISIT_ID
	, VST_START_DTIME AS VISIT_DATE

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE (
			(
			PLM_PT_ACCT_TYPE = 'I'
			AND ADM_SOURCE NOT IN (
				'RP'
				)
			)
			OR PT_TYPE = 'E'
		)
	AND vst_start_dtime >= @SD 
	AND vst_start_dtime < @ED
	AND Med_Rec_No IN (

	)
)A

GROUP BY MRN, VISIT_ID, VISIT_DATE
ORDER BY MRN
, VISIT_DATE

SELECT E.* 
FROM @ER_VISIT_COUNT E
INNER JOIN (
	SELECT MRN, MAX(ED_VISIT_COUNT) AS MAX_VISIT
	FROM @ER_VISIT_COUNT
	GROUP BY MRN
	) groupedERVisits
ON E.MRN = groupedERVisits.MRN
	AND E.ED_VISIT_COUNT = groupedERVisits.MAX_VISIT
	
/*

Polypharmacy Query ----------------------------------------------------

*/
SET ANSI_NULLS OFF
GO

DECLARE @SD DATETIME;
DECLARE @ED DATETIME;

SET @SD = GETDATE() - 180;
SET @ED = GETDATE();
/*
#######################################################################

GET LIST OF THOSE THAT ARE POLY-PHARMACY DEFINED AS 6 OR MORE HOME
MEDICATIONS

#######################################################################
*/
DECLARE @PLYPHARM TABLE(
	ID INT IDENTITY(1, 1)  PRIMARY KEY
	, [Patient Name]       VARCHAR(MAX)
	, [Admit Date Time]    DATETIME
	, [Med List Type]      VARCHAR(MAX)
	, [Last Status Update] DATETIME
	, [Visit ID]           VARCHAR(MAX)
	, [Med_Rec_No]         VARCHAR(MAX)
	, [Home Med Count]     INT
	, [Attending Doctor]   VARCHAR(MAX)
	, [RN]                 INT
);

WITH CTE AS (
	SELECT 
		B.rpt_name                        AS [Patient Name]
		, B.vst_start_dtime               AS [Admit Date Time]
		, A.med_lst_type                  AS [Med List Type]
		, B.last_cng_dtime                AS [Last Status Update]
		, B.episode_no                    AS [Visit ID]
		, B.med_rec_no                    AS [Med_Rec_No]
		, CONVERT(INT, COUNT(A.med_name)) AS [Home Med Count]
		, D.pract_rpt_name                AS [Attending Doctor]
		, RN = ROW_NUMBER() OVER(PARTITION BY C.MED_REC_NO ORDER BY B.VST_START_DTIME)

	FROM smsdss.qoc_med                     A
		JOIN smsdss.QOC_vst_summ        B
		ON A.pref_vst_pms_id_col = B.pref_vst_pms_id_col
		JOIN smsdss.BMH_PLM_PtAcct_V    C
		ON C.PtNo_Num = B.episode_no
		JOIN smsdss.pract_dim_v         D
		ON C.Atn_Dr_No = D.src_pract_no

	WHERE 
		A.med_lst_type = 'HML'
		--AND C.Dsch_Date IS NULL
		--AND C.Plm_Pt_Acct_Type = 'I'
		--AND C.PtNo_Num < '20000000'
		AND D.orgz_cd = 'S0X0'
		--AND D.src_spclty_cd = 'HOSIM'
		AND C.Med_Rec_No IN (

	)

	GROUP BY 
		B.rpt_name
		, C.Med_Rec_No
		, B.vst_start_dtime
		, A.med_lst_type
		, B.last_cng_dtime
		, B.episode_no
		, B.med_rec_no
		, D.pract_rpt_name

	--HAVING COUNT(A.MED_NAME) >= 5
)

INSERT INTO @PLYPHARM
SELECT
	C1.[Patient Name]
	, C1.[Admit Date Time]
	, C1.[Med List Type]
	, C1.[Last Status Update]
	, C1.[Visit ID]
	, C1.[Med_Rec_No]
	, C1.[Home Med Count]
	, C1.[Attending Doctor]
	, C1.RN

FROM CTE C1

-----------------------------------------------------------------------

SELECT A.*
, CASE
	WHEN A.[Home Med Count] >= 5 THEN 1
	ELSE 0
  END AS PolyPharmaFlag

FROM @PLYPHARM A

/*
-----------------------------------------------------------------------
List of home meds
-----------------------------------------------------------------------
*/
SET ANSI_NULLS OFF
GO

DECLARE @MedList TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Patient Name]  VARCHAR(MAX)
	, [MRN]           INT
	, [Encounter]     INT
	, [Admit Date]    DATETIME
	, [Disc Date]     DATETIME
	, [Home Med List] VARCHAR(MAX)
);

WITH MEDLIST AS (
	SELECT
		B.rpt_name
		, B.med_rec_no
		, B.episode_no
		, B.vst_start_date
		, B.vst_end_date
		, A.med_name

	FROM SMSDSS.QOC_Med          A
	JOIN SMSDSS.QOC_vst_summ     B
	ON A.pref_vst_pms_id_col = B.pref_vst_pms_id_col

	WHERE
		A.med_lst_type = 'HML'
		AND B.med_rec_no IN (

		)
		AND b.vst_start_date >= '2015-01-01'
		AND b.vst_end_date < '2015-10-01'

	GROUP BY
		B.rpt_name
		, B.med_rec_no
		, B.episode_no
		, B.vst_start_date
		, B.vst_end_date
		, A.med_name
)

INSERT INTO @MedList
SELECT ML.*
FROM MEDLIST ML

SELECT * 

FROM @MedList

/*

INSURANCE ID NUMBER FOR THE LAST VISIT_DATE

*/

DECLARE @INS_ID TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter               INT
	, MRN                     INT
	, Last_Known_PolicyNumber VARCHAR(20)
	, Ins_Co_Name             VARCHAR(30)
	, Ins_Phone               VARCHAR(10)
	, RN                      INT
);

WITH LASTKNOWNINS AS (
	SELECT c.PtNo_Num
	, c.Med_Rec_No
	, CASE
		WHEN LEFT(A.PYR_CD, 1) IN ('A','Z')
		THEN A.pol_no + ISNULL(LTRIM(RTRIM(GRP_NO)),'')
		WHEN A.pol_no IS NULL
		THEN A.subscr_ins_grp_id
		ELSE A.pol_no
	  END AS INS_ID_NUM
	, D.ins_co_name
	, E.Ins_Tel_No
	, RN = ROW_NUMBER() OVER(PARTITION BY C.MED_REC_NO ORDER BY C.PTNO_NUM DESC)

	FROM smsmir.mir_pyr_plan                   A
	LEFT OUTER JOIN smsmir.mir_acct            B
	ON a.pt_id = b.pt_id
		AND a.pt_id_start_dtime = b.pt_id_start_dtime
		AND a.pyr_seq_no = 1
	LEFT OUTER JOIN smsdss.bmh_plm_ptacct_v    C
	ON b.pt_id = c.Pt_No
	LEFT OUTER JOIN SMSMIR.mir_pyr_mstr        D
	ON A.pyr_cd = D.pyr_cd
		AND A.src_sys_id = D.src_sys_id
		AND A.orgz_cd = D.iss_orgz_cd
	LEFT OUTER JOIN SMSDSS.c_ins_user_fields_v E
	ON A.pt_id = E.pt_id
		AND A.pyr_cd = E.pyr_cd

	WHERE c.Med_Rec_No IN (

			)
		AND c.vst_start_dtime >= '2015-01-01'
		AND c.vst_end_dtime < '2015-10-01'
)

INSERT INTO @INS_ID
SELECT *
FROM LASTKNOWNINS

SELECT *
FROM @INS_ID
WHERE RN = 1

/*

Last known emergency contact

*/

DECLARE @EMER_CONTACT TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN                   INT
	, Last_Known_First_Name VARCHAR(MAX)
	, Last_Known_Address    VARCHAR(MAX)
	, Last_Known_Phone      VARCHAR(20)
	, RN                    INT
);

WITH EMER_CONTACT AS (
SELECT pt_med_rec_no 
, empr_first_name [emer_contact_first_name]
, empr_street_addr [emer_contact_add]
, '(' + empr_phone_area_city_cd + ')' + ' - ' + empr_phone_no AS [emer_contact_phone]
, RN = ROW_NUMBER() OVER(PARTITION BY PT_MED_REC_NO ORDER BY PT_ID DESC)

FROM smsmir.mir_hl7_pt

where pt_med_rec_no IN (

			)
)

INSERT INTO @EMER_CONTACT
SELECT *
FROM EMER_CONTACT
WHERE RN = 1

SELECT *
FROM @EMER_CONTACT
