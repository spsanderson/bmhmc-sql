DECLARE @START DATE;
DECLARE @END   DATE;
SET @START = '2016-02-01';
SET @END   = '2016-03-01';

/*
Get patients who have Sepsis, this will be the driver for the report
and will then be used to select from the orders table to eventually
form the sepsis report
*/
DECLARE @SepsisTbl TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Name                VARCHAR(500)
	, MRN                 INT
	, Account             INT
	, Age                 INT -- Age at arrival
	, Arrival             DATETIME
	, Triage_StartDT      DATETIME
	, Left_ED_DT          DATETIME
	, Disposition         VARCHAR(500)
	, Mortality           CHAR(1)
);

WITH Patients AS (
	SELECT UPPER(Patient)             AS [Name]
	, MR#
	, Account
	, DATEDIFF(YEAR, AgeDob, Arrival) AS [Age_at_Arrival]
	, CASE
		WHEN Arrival = '-- ::00'
			THEN ''
			ELSE Arrival
	  END AS Arrival
	, CASE
		WHEN Triage_Start = '-- ::00'
			THEN ''
			ELSE Triage_Start
	  END AS Triage_Start
	, CASE
		WHEN TimeLeftED = '-- ::00'
			THEN ''
			ELSE TimeLeftED
	  END AS TimeLeftED

	, Disposition
	, CASE
		WHEN Disposition IN (
			'Medical Examiner', 'Morgue'
		)
		THEN 'Y'
		ELSE 'N'
	  END                             AS [Mortality]

	FROM SMSDSS.c_Wellsoft_Rpt_tbl
	WHERE Triage_Start IS NOT NULL
	AND (
		Diagnosis LIKE '%SEPSIS%'
		OR
		Diagnosis LIKE '%SEPTIC%'
	)
	AND Arrival >= @START
	AND Arrival < @END
)

INSERT INTO @SepsisTbl
SELECT * FROM Patients

--=====================================================================
-- Get the first IV Fluids order
--=====================================================================
DECLARE @IVTbl TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Account             INT
	, MR#                 INT
	, OrderName           VARCHAR(MAX)
	, Placer#             VARCHAR(30)
	, OrderDT             DATETIME
	, InProgDT            DATETIME
	, CompDT              DATETIME
	, RN                  INT
);

WITH CTE1 AS (
	SELECT A.Account
	, A.MR#
	, A.OrderName
	, A.Placer#
	, A.SchedDT AS OrderDT
	, A.InProgDT
	, A.CompDT
	, ROW_NUMBER() OVER(
		PARTITION BY A.ACCOUNT
		ORDER BY A.SchedDT
		) AS [RN]

	FROM SMSDSS.c_Wellsoft_Ord_Rpt_Tbl   AS A
	INNER JOIN SMSDSS.C_WELLSOFT_RPT_TBL AS B
	ON A.Account = B.Account

	WHERE (
		   [OrderName] LIKE '%DEXTROS%'
		OR [OrderName] LIKE '%SODIUM BICARB%'
		OR [OrderName] LIKE '%IVF (plain)%'
	)
	AND A.Account IN (
		SELECT Account
		FROM SMSDSS.c_Wellsoft_Rpt_tbl
		WHERE (
			Diagnosis LIKE '%SEPSIS%'
			OR
			Diagnosis LIKE '%SEPTIC%'
		)
	)
)

INSERT INTO @IVTbl 
SELECT * FROM CTE1 C1
WHERE C1.RN = 1

--SELECT * FROM @IVTbl

--=====================================================================
-- Get the first chest x-ray
--=====================================================================
DECLARE @XRAYTbl TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Account             INT
	, MR#                 INT
	, OrderName           VARCHAR(MAX)
	, Placer#             VARCHAR(30)
	, OrderDT             DATETIME
	, InProgDT            DATETIME
	, CompDT              DATETIME
	, RN                  INT
);

WITH CTE2 AS (
SELECT A.Account
	, A.MR#
	, A.OrderName
	, A.Placer#
	, A.SchedDT AS OrderDT
	, A.InProgDT
	, A.CompDT
	, ROW_NUMBER() OVER(
		PARTITION BY A.ACCOUNT
		ORDER BY A.SchedDT
		) AS [RN]

	FROM SMSDSS.c_Wellsoft_Ord_Rpt_Tbl   AS A
	INNER JOIN SMSDSS.C_WELLSOFT_RPT_TBL AS B
	ON A.Account = B.Account

	WHERE (
		   [OrderName] LIKE '%XR CHEST%'
		OR [OrderName] LIKE '%CHEST%XRAY%'
		OR [OrderName] LIKE '%Portable Chest-Single View%'
	)
	AND A.Account IN (
		SELECT Account
		FROM SMSDSS.c_Wellsoft_Rpt_tbl
		WHERE (
			Diagnosis LIKE '%SEPSIS%'
			OR
			Diagnosis LIKE '%SEPTIC%'
		)
	)
)

INSERT INTO @XRAYTbl
SELECT * FROM CTE2 C2
WHERE C2.RN = 1

--SELECT * FROM @XRAYTbl

--=====================================================================
-- Get the first Antibiotics order
--=====================================================================
DECLARE @ABTbl TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Account             INT
	, MR#                 INT
	, OrderName           VARCHAR(MAX)
	, Placer#             VARCHAR(30)
	, OrderDT             DATETIME
	, InProgDT            DATETIME
	, CompDT              DATETIME
	, RN                  INT
);

WITH CTE3 AS (
	SELECT A.Account
	, A.MR#
	, A.OrderName
	, A.Placer#
	, A.SchedDT AS OrderDT
	, A.InProgDT
	, A.CompDT
	, ROW_NUMBER() OVER(
		PARTITION BY A.ACCOUNT
		ORDER BY A.SchedDT
		) AS [RN]

	FROM SMSDSS.c_Wellsoft_Ord_Rpt_Tbl   AS A
	INNER JOIN SMSDSS.C_WELLSOFT_RPT_TBL AS B
	ON A.Account = B.Account

	WHERE (
		   [OrderName] LIKE '%ANCEF%'
		OR [OrderName] LIKE '%AZITH%'
		OR [OrderName] LIKE '%CEF%'
		OR [OrderName] LIKE '%CIPRO%'
		OR [OrderName] LIKE '%CLINDA%'
		OR [OrderName] LIKE '%DAPT%'
		OR [OrderName] LIKE '%DAPTOM%'
		OR [OrderName] LIKE '%LEVOF%'
		OR [OrderName] LIKE '%LINEZ%'
		OR [OrderName] LIKE '%Metronid%'
		OR [OrderName] LIKE '%PENIC%'
		OR [OrderName] LIKE '%Piper%'
		OR [OrderName] LIKE '%Prima%'
		OR [OrderName] LIKE '%Tazobac%'
		OR [OrderName] LIKE '%Vanco%'
		OR [OrderName] LIKE '%VANCO%'
		OR [OrderName] LIKE '%ZOSYN%'
		OR [OrderName] LIKE '%LEVAQ%'
		OR [OrderName] LIKE '%ROCE%'
		OR [OrderName] LIKE '%ZITHR%'
		OR [OrderName] LIKE '%INVANZ%'
	)
	AND A.Account IN (
		SELECT Account
		FROM SMSDSS.c_Wellsoft_Rpt_tbl
		WHERE (
			Diagnosis LIKE '%SEPSIS%'
			OR
			Diagnosis LIKE '%SEPTIC%'
		)
	)
)

INSERT INTO @ABTbl
SELECT * FROM CTE3 C3
WHERE C3.RN = 1

--SELECT * FROM @ABTbl

--=====================================================================
-- Get the first CBC with WBC DIFFERENTIAL
--=====================================================================
-- Get the first Antibiotics order
DECLARE @WBCTbl TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Account             INT
	, MR#                 INT
	, OrderName           VARCHAR(MAX)
	, Placer#             VARCHAR(30)
	, OrderDT             DATETIME
	, InProgDT            DATETIME
	, CompDT              DATETIME
	, RN                  INT
);

WITH CTE4 AS (
	SELECT A.Account
	, A.MR#
	, A.OrderName
	, A.Placer#
	, A.SchedDT AS OrderDT
	, A.InProgDT
	, A.CompDT
	, ROW_NUMBER() OVER(
		PARTITION BY A.ACCOUNT
		ORDER BY A.SchedDT
		) AS [RN]

	FROM SMSDSS.c_Wellsoft_Ord_Rpt_Tbl   AS A
	INNER JOIN SMSDSS.C_WELLSOFT_RPT_TBL AS B
	ON A.Account = B.Account

	WHERE [OrderName] LIKE '%CBC WITH WBC DIFFERENTIAL%'
	AND A.Account IN (
		SELECT Account
		FROM SMSDSS.c_Wellsoft_Rpt_tbl
		WHERE (
			Diagnosis LIKE '%SEPSIS%'
			OR
			Diagnosis LIKE '%SEPTIC%'
		)
	)
)

INSERT INTO @WBCTbl
SELECT * FROM CTE4 C4
WHERE C4.RN = 1

--SELECT * FROM @WBCTbl

--=====================================================================
-- Get the first Lactate Level
--=====================================================================
DECLARE @LactateTbl TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Account             INT
	, MR#                 INT
	, OrderName           VARCHAR(MAX)
	, Placer#             VARCHAR(30)
	, OrderDT             DATETIME
	, InProgDT            DATETIME
	, CompDT              DATETIME
	, RN                  INT
);

WITH CTE5 AS (
	SELECT A.Account
	, A.MR#
	, A.OrderName
	, A.Placer#
	, A.SchedDT AS OrderDT
	, A.InProgDT
	, A.CompDT
	, ROW_NUMBER() OVER(
		PARTITION BY A.ACCOUNT
		ORDER BY A.SchedDT
		) AS [RN]

	FROM SMSDSS.c_Wellsoft_Ord_Rpt_Tbl   AS A
	INNER JOIN SMSDSS.C_WELLSOFT_RPT_TBL AS B
	ON A.Account = B.Account

	WHERE [OrderName] LIKE '%LACTIC ACID%'
	AND A.Account IN (
		SELECT Account
		FROM SMSDSS.c_Wellsoft_Rpt_tbl
		WHERE (
			Diagnosis LIKE '%SEPSIS%'
			OR
			Diagnosis LIKE '%SEPTIC%'
		)
	)
)

INSERT INTO @LactateTbl
SELECT * FROM CTE5 C5
WHERE C5.RN = 1

--SELECT * FROM @LactateTbl

/*
=======================================================================
Pull it together
=======================================================================
*/
SELECT S.Name
, S.MRN
, S.Account
, S.Age
, S.Arrival
, ''               AS [ARRIVAL MONTH]
, ''               AS [ARRIVAL YR]
, S.Triage_StartDT AS [TRIAGE TIME]
, S.Left_ED_DT     AS [DISC TIME]
, ''               AS [ARR TO TRIAGE MINUTES] --Calculated in Excel
, ''               AS [ARR TO DISC HRS] --Calculate in Excel
, ''               AS [ER DISPO] -- Get from report
, S.Disposition
, S.Mortality
, CASE
	WHEN (
		   IV.OrderDT  IS NOT NULL
		OR IV.InProgDT IS NOT NULL
		OR IV.CompDT   IS NOT NULL
	)
		THEN 'Y'
		ELSE 'N'
  END AS [IV FLUIDS]
, IV.OrderDT
, '' AS [TRIAGE TO ORDER MINUTES]
, IV.InProgDT
, '' AS [TRIAGE TO IP MINUTES]
, IV.CompDT
, '' AS [TRIAGE TO COMP MINUTES]
, CASE
	WHEN (
		   XRAY.OrderDT  IS NOT NULL
		OR XRAY.InProgDT IS NOT NULL
		OR XRAY.CompDT   IS NOT NULL
	)
		THEN 'Y'
		ELSE 'N'
  END AS [CXR]
, XRAY.OrderDT
, '' AS [TRIAGE TO ORDER MINUTES]
, XRAY.InProgDT
, '' AS [TRIAGE TO IP MINUTES]
, XRAY.CompDT
, '' AS [TRIAGE TO COMP MINUTES]
, CASE
	WHEN (
		   AB.OrderDT  IS NOT NULL
		OR AB.InProgDT IS NOT NULL
		OR AB.CompDT   IS NOT NULL
	)
		THEN 'Y'
		ELSE 'N'
  END AS [AB]
, AB.OrderDT
, '' AS [TRIAGE TO ORDER MINUTES]
, AB.InProgDT
, '' AS [TRIAGE TO IP MINUTES]
, AB.CompDT
, '' AS [TRIAGE TO COMP MINUTES]
, CASE
	WHEN (
		   WBC.OrderDT  IS NOT NULL
		OR WBC.InProgDT IS NOT NULL
		OR WBC.CompDT   IS NOT NULL
	)
		THEN 'Y'
		ELSE 'N'
  END AS [WBC]
, WBC.OrderDT
, '' AS [TRIAGE TO ORDER MINUTES]
, WBC.InProgDT
, '' AS [TRIAGE TO IP MINUTES]
, WBC.CompDT
, '' AS [TRIAGE TO COMP MINUTES]
, CASE
	WHEN (
		   L.OrderDT  IS NOT NULL
		OR L.InProgDT IS NOT NULL
		OR L.CompDT   IS NOT NULL
	)
		THEN 'Y'
		ELSE 'N'
 END AS [LACTATE]
, L.OrderDT
, '' AS [TRIAGE TO ORDER MINUTES]
, L.InProgDT
, '' AS [TRIAGE TO IP MINUTES]
, L.CompDT
, '' AS [TRIAGE TO COMP MINUTES]

FROM @SepsisTbl             AS S
LEFT OUTER JOIN @IVTbl      AS IV
ON S.Account = IV.Account
LEFT OUTER JOIN @XRAYTbl    AS XRAY
ON S.Account = XRAY.Account
LEFT OUTER JOIN @ABTbl      AS AB
ON S.Account = AB.Account
LEFT OUTER JOIN @WBCTbl     AS WBC
ON S.Account = WBC.Account
LEFT OUTER JOIN @LactateTbl AS L
ON S.Account = L.Account

WHERE S.Arrival >= @START
--AND S.Arrival < @END

ORDER BY S.Arrival