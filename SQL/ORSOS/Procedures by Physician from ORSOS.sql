/*
We want to get the Surgical Data from ORSOS as a base, we will left join
onto it data from DSS in order to tie back to the financials.

We will also use the SoftMed DB (old) in order to get the name of the 
physician practice.

ORSOS <-- DSS <-- SoftMed
*/

-- VARIABLES
DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = '2016-01-01';
SET @END   = '2016-02-01';
---------------------------------------------------------------------------------------------------

-- get practice names addresses old softmed 
DECLARE @Practice_Info TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Practice Name]      VARCHAR(MAX)
	, [Address Line 1]     VARCHAR(100)
	, [Address Line 2]     VARCHAR(100)
	, [Address Line 3]     VARCHAR(100)
	, [City]               VARCHAR(100)
	, [State]              VARCHAR(100)
	, [Zip Code]           VARCHAR(100)
	, [Phone]              VARCHAR(100)
	, [Fax]                VARCHAR(100)
	, [SoftMed Prov Num]   VARCHAR(100)
	, [Prof Title]         VARCHAR(100)
	, [Doc Name]           VARCHAR(100)
	, [Suffix]             VARCHAR(100)
	, [Status]             VARCHAR(100)
	, [Reason]             VARCHAR(MAX)
	, [DSS Prov Num]       VARCHAR(100)
	, [DSS Doc Name]       VARCHAR(100)
	, [DSS Med Staff Dept] VARCHAR(100)
	, [DSS Specialty]      VARCHAR(100)
	, [DSS Spclty Code]    VARCHAR(100)
);

WITH CTE1 AS (
	select a.name AS PRACTICE_NAME
	, a.address1
	, a.address2
	, a.address3
	, a.city
	, a.state
	, a.postcode
	, a.phone
	, a.fax
	, c.provnum
	, c.proftitle
	, c.name
	, c.suffix
	, c.status
	, c.reason
	, d.src_pract_no
	, d.pract_rpt_name
	, d.med_staff_dept
	, d.spclty_desc
	, d.spclty_cd

	from [bmh-softmed-db].[ssi_bmh_live].[dbo].[cre_practice] as a
	left join [BMH-SOFTMED-DB].[SSI_BMH_LIVE].[dbo].[cre_provider_practice] as b
	on a._PK = b.pPractice
	left join [BMH-SOFTMED-DB].[SSI_BMH_LIVE].[dbo].[cre_provider] as c
	on b._parent = c._PK
	left join smsdss.pract_dim_v as d
	on SUBSTRING(c.provnum, 3, 6) = rtrim(ltrim(d.src_pract_no))COLLATE SQL_Latin1_General_CP1_CI_AS
		and d.orgz_cd = 's0x0'
		
	--where a._pk = '1'
	where d.src_pract_no is not null
	and d.src_pract_no != '000000'
)

INSERT INTO @Practice_Info
SELECT * FROM CTE1

--SELECT * FROM @Practice_Info
---------------------------------------------------------------------------------------------------
-- Grab the ORSOS information here

DECLARE @ORSOS_Tbl TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [DSS MRN]           VARCHAR(10)
	, [Facility Acct Num] VARCHAR(15)
	, [Patient Name]      VARCHAR(50)
	, [Admit Date]        DATE
	, [Discharge Date]    DATE
	, [ORSOS Case Num]    VARCHAR(15)
	, [Procedure ID]      VARCHAR(15)
	, [Procedure Desc]    VARCHAR(MAX)
	, [Start Date]        DATETIME
	, [Resource ID]       VARCHAR(10) -- Physician or any other resource
	, [Role Code]         VARCHAR(10)
	, [Description]       VARCHAR(25) 
);

WITH CTE2 AS (
	SELECT c.gpi    AS [dss_med_rec_no]
	, e.facility_account_no
	, c.patient_name
	, e.admit_date
	, e.discharge_date
	, a.case_no
	, a.procedure_id
	, d.description AS [proc_desc]
	, a.start_date
	, a.resource_id AS [physician]
	, a.role_code
	, f.description

	FROM [BMH-ORSOS].orsprod.ORSPROD.POST_RESOURCE     as a
	INNER JOIN [bmh-orsos].orsprod.orsprod.post_case   as b
	ON a.case_no = b.case_no
	INNER JOIN [bmh-orsos].orsprod.orsprod.demographic as c
	ON b.medical_record_no = c.medical_record_no
	INNER JOIN [bmh-orsos].orsprod.orsprod.procedures  as d
	ON a.procedure_id = d.procedure_id
	INNER JOIN [bmh-orsos].orsprod.orsprod.clinical    as e
	ON b.account_no = e.account_no
	INNER JOIN [bmh-orsos].orsprod.ORSPROD.CODES_ROLE  as f
	ON a.role_code = f.code

	WHERE a.start_date >= @START
	AND a.start_date < @END
	--AND a.resource_id = '013987' -- Pulipati Ravi
	AND a.role_code = '1' -- PROVIDER
	AND LEFT(e.facility_account_no, 1) != '0' -- GETS RID OF J CODES
	--AND E.FACILITY_ACCOUNT_NO = ''	
)

INSERT INTO @ORSOS_Tbl
SELECT * FROM CTE2

--SELECT TOP 5 * FROM @ORSOS_Tbl
---------------------------------------------------------------------------------------------------
-- Get accounts with AMB Surge Fee 01800010 Ambulatory Surgery Fee
DECLARE @DSS_AmbSurg_Activity TABLE(
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Encounter]         INT
	, [Total Actv Qty]    INT
	, [Total Actv Charge] MONEY
);

WITH CTE3 AS (
	SELECT pt_id
	, SUM(actv_tot_qty) AS total_quantity
	, SUM(chg_tot_amt)  AS total_charge

	FROM smsmir.actv

	WHERE actv_cd = '01800010'
	AND SUBSTRING(pt_id, 5, 8) IN (
		SELECT A.[Facility Acct Num]
		FROM @ORSOS_Tbl AS A
	)

	GROUP BY pt_id

	HAVING SUM(actv_tot_qty) > 0
	AND SUM(chg_tot_amt) > 0
)

INSERT INTO @DSS_AmbSurg_Activity
SELECT * FROM CTE3

--SELECT TOP 5 * FROM @DSS_AmbSurg_Activity
---------------------------------------------------------------------------------------------------
-- Get accounts with Operating Room Time Charges
DECLARE @DSS_OR_Time_Activity TABLE(
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Encounter]         INT
	, [Total Actv Qty]    INT
	, [Total Actv Charge] MONEY
);

WITH CTE3 AS (
	SELECT pt_id
	, SUM(actv_tot_qty) AS total_quantity
	, SUM(chg_tot_amt)  AS total_charge

	FROM smsmir.actv

	WHERE actv_cd IN (
		'01800010', '00800011', '00800029', '00800037', '00800045', 
		'00800052', '00800060', '00800078', '00800086', '00800094', 
		'00800102', '00800110', '00800128', '00800136', '00800144', 
		'00800151', '00800169', '00800177', '00800185', '00800193', 
		'00800201', '00800219', '00800227', '00800235', '00800243', 
		'00800250', '00800268', '00800276', '00800284', '00800292', 
		'00800300', '00800318', '00800326'
	)
	AND SUBSTRING(pt_id, 5, 8) IN (
		SELECT A.[Facility Acct Num]
		FROM @ORSOS_Tbl AS A
	)

	GROUP BY pt_id

	HAVING SUM(actv_tot_qty) > 0
	AND SUM(chg_tot_amt) > 0
)

INSERT INTO @DSS_OR_Time_Activity
SELECT * FROM CTE3

--SELECT * FROM @DSS_OR_Time_Activity

----------------------------------------------------------------------------------------------------

DECLARE @DSS_OROSOS TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           CHAR(8)
	, Procedure_Code      VARCHAR(15)
	, Clasf_Eff_Date      DATE
	, Pocedure_Cd_Scheme  VARCHAR(2)
	, DSS_Proc_Desc       VARCHAR(500)
	, ORSOS_Case_Number   VARCHAR(10)
	, Hospital_Service    CHAR(3)
	, Patient_Type        CHAR(1)
);

WITH CTE2 AS (
SELECT SUBSTRING(A.Pt_No, 5, 8) AS [Encounter]
, A.ClasfCd
, A.Clasf_Eff_Date
--, A.ClasfPrio
, A.Proc_Cd_Schm
, B.alt_clasf_desc
--, C.UserDataKey
, C.UserDataText AS [ORSOS_Case_No]
--, D.UserDataCd
, E.hosp_svc
, E.pt_type

FROM smsdss.BMH_PLM_PtAcct_Clasf_Proc_V_New AS A
LEFT JOIN smsdss.proc_dim_v                 AS B
ON a.ClasfCd = b.proc_cd
	AND a.Proc_Cd_Schm = b.proc_cd_schm
LEFT JOIN smsdss.BMH_UserTwoFact_V          AS C
ON RTRIM(LTRIM(SUBSTRING(A.PT_NO, 5, 8))) = C.PtNo_Num
	AND C.UserDataKey = '571'
LEFT JOIN smsdss.BMH_UserTwoField_Dim_V     AS D
	ON C.UserDataKey = D.UserTwoKey
LEFT JOIN smsdss.BMH_PLM_PtAcct_V           AS E
ON A.Pt_No = E.Pt_No

WHERE Clasf_Eff_Date >= '2016-02-21'
AND Clasf_Eff_Date <= '2016-03-05'
AND ClasfPrio = '01'
--AND C.UserDataKey = '571'
--AND A.RespParty IN ()
)

INSERT INTO @DSS_OROSOS
SELECT * FROM CTE2

SELECT A.*
, B.hosp_svc_cd_desc

FROM @DSS_OROSOS AS A
LEFT JOIN smsdss.hosp_svc_dim_v AS B
ON A.Hospital_Service = B.hosp_svc
	AND B.orgz_cd = 'S0X0'
	
WHERE LEFT(A.Encounter, 1) = '1'