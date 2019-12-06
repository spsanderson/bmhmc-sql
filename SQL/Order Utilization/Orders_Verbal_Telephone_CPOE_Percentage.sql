/*
Author: Steven P Sanderson II, MPH
Department: Finance, Revenue Cycle

Aggregate Order Utilizaiton for CPOE/Telephone/Verbal/Other orders

This query aggregates by req_pty_cd, gets total cpoe percentage if a provider
has greater than or equal to 600 cpoe orders

V2	- 2018-06-11	- Add excl_ord_for_CPOE_ind = 0
*/
DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2017-11-01';
SET @END   = '2018-05-01';
---------------------------------------------------------------------------------------------------

DECLARE @ALL_ORDERS TABLE (
	-- GET ALL OF THE ELIGIBLE ORDERS
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Req_Pty_Cd          VARCHAR(20)
	, Ord_Src_Modf_Name   VARCHAR(50)
	, Order_Entry_Month   INT
	, Order_Entry_Year    INT
);

WITH CTE AS (
	SELECT req_pty_cd
	, ord_src_modf_name
	, MONTH(A.ent_date)      AS [Order Entry Month]
	, YEAR(A.ent_date)       AS [Order Entry Year]

	FROM smsdss.QOC_Ord_v        AS A
	LEFT JOIN smsdss.pract_dim_v AS B
	ON A.req_pty_cd = B.src_pract_no
		AND B.orgz_cd = 'S0X0'

	WHERE phys_req_ind = 1
	AND A.ent_date >= @START
	AND A.ent_date < @END
	AND A.req_pty_cd IS NOT NULL
	AND A.req_pty_cd NOT IN (
		'000000', '000059', '000099','000666','004337'
		,'4337','999998'
	)
	AND A.excl_ord_for_CPOE_ind = 0
)

INSERT INTO @ALL_ORDERS
SELECT * FROM CTE
;
--SELECT * FROM @ALL_ORDERS 
---------------------------------------------------------------------------------------------------

DECLARE @TOTAL_ORD_COUNT TABLE (
	-- GET THE TOTAL ORDERS BY MONTH AND YEAR
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Req_Pty_Cd          CHAR(6)
	, Ordering_Year       INT
	, Ordering_Month      INT
	, Total_Order_Count   INT
);

WITH CTE AS (
	SELECT A.Req_Pty_Cd
	, A.Order_Entry_Year
	, A.Order_Entry_Month
	, COUNT(A.Req_Pty_Cd) AS Total_Orders
	
	FROM @ALL_ORDERS AS A
	
	GROUP BY A.Req_Pty_Cd
	, A.Order_Entry_Year
	, A.Order_Entry_Month
)

INSERT INTO @TOTAL_ORD_COUNT
SELECT * FROM CTE
--SELECT * 
--FROM @TOTAL_ORD_COUNT AS A 
--ORDER BY A.Req_Pty_Cd, A.Ordering_Year, A.Ordering_Month
---------------------------------------------------------------------------------------------------

DECLARE @VERBAL_ORDERS TABLE (
	-- GET THE TOTAL VERBAL ORDERS BY MONTH AND YEAR
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Req_Pty_Cd          CHAR(6)
	, Ordering_Year       INT
	, Ordering_Month      INT
	, Verbal_Order_Count  INT
);

WITH CTE AS (
	SELECT A.Req_Pty_Cd
	, A.Order_Entry_Year
	, A.Order_Entry_Month
	, COUNT(A.Req_Pty_Cd) AS Verbal_Orders
	
	FROM @ALL_ORDERS AS A
	
	WHERE A.Ord_Src_Modf_Name = 'Verbal Order'
	
	GROUP BY A.Req_Pty_Cd
	, A.Order_Entry_Year
	, A.Order_Entry_Month
)

INSERT INTO @VERBAL_ORDERS
SELECT * FROM CTE
--SELECT * FROM @VERBAL_ORDERS
---------------------------------------------------------------------------------------------------

DECLARE @TELE_ORDERS TABLE (
	-- GET THE TOTAL VERBAL ORDERS BY MONTH AND YEAR
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Req_Pty_Cd          CHAR(6)
	, Ordering_Year       INT
	, Ordering_Month      INT
	, Tele_Order_Count    INT
);

WITH CTE AS (
	SELECT A.Req_Pty_Cd
	, A.Order_Entry_Year
	, A.Order_Entry_Month
	, COUNT(A.Req_Pty_Cd) AS Telephone_Orders
	
	FROM @ALL_ORDERS AS A
	
	WHERE A.Ord_Src_Modf_Name = 'Telephone'
	
	GROUP BY A.Req_Pty_Cd
	, A.Order_Entry_Year
	, A.Order_Entry_Month
)

INSERT INTO @TELE_ORDERS
SELECT * FROM CTE
--SELECT * FROM @TELE_ORDERS
---------------------------------------------------------------------------------------------------

DECLARE @CPOE_ORDERS TABLE (
	-- GET THE TOTAL VERBAL ORDERS BY MONTH AND YEAR
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Req_Pty_Cd          CHAR(6)
	, Ordering_Year       INT
	, Ordering_Month      INT
	, CPOE_Order_Count    INT
);

WITH CTE AS (
	SELECT A.Req_Pty_Cd
	, A.Order_Entry_Year
	, A.Order_Entry_Month
	, COUNT(A.Req_Pty_Cd) AS CPOE_Orders
	
	FROM @ALL_ORDERS AS A
	
	WHERE A.Ord_Src_Modf_Name = 'CPOE'
	
	GROUP BY A.Req_Pty_Cd
	, A.Order_Entry_Year
	, A.Order_Entry_Month
)

INSERT INTO @CPOE_ORDERS
SELECT * FROM CTE
--SELECT * FROM @TELE_ORDERS
---------------------------------------------------------------------------------------------------

SELECT A.Req_Pty_Cd
, A.Ordering_Year
, A.Ordering_Month
, ISNULL(A.Total_Order_Count, 0)  AS Total_Order_Count
, ISNULL(B.Tele_Order_Count, 0)   AS Total_Tele_Orders
, ISNULL(C.Verbal_Order_Count, 0) AS Total_Verbal_Orders
, ISNULL(D.CPOE_Order_Count, 0)   AS Total_CPOE_Orders
, CASE
	WHEN E.spclty_cd IS NOT NULL AND E.spclty_cd != '?' THEN E.spclty_cd
	WHEN F.spclty_cd IS NOT NULL AND F.spclty_cd != '?' THEN F.spclty_cd
	WHEN G.spclty_cd IS NOT NULL AND G.spclty_cd != '?' THEN G.spclty_cd
	WHEN H.spclty_cd IS NOT NULL AND H.spclty_cd != '?' THEN H.spclty_cd
	WHEN I.spclty_cd1 IS NOT NULL AND I.spclty_cd1 != '?' THEN I.spclty_cd1
	WHEN J.spclty_cd1 IS NOT NULL AND J.spclty_cd1 != '?' THEN J.spclty_cd1
	WHEN K.spclty_cd1 IS NOT NULL AND K.spclty_cd1 != '?' THEN K.spclty_cd1
  END AS spclty_cd
, CASE
	WHEN (
		E.src_spclty_cd = 'HOSIM' OR
		F.src_spclty_cd = 'HOSIM' OR
		G.src_spclty_cd = 'HOSIM' OR
		H.src_spclty_cd = 'HOSIM' OR
		I.spclty_cd1    = 'HOSIM' OR
		J.spclty_cd1    = 'HOSIM' OR
		K.spclty_cd1    = 'HOSIM'
	)
		THEN 'Hospitalist'
	WHEN LEFT(A.REQ_PTY_CD, 1) = '9' 
		THEN 'PA / NP'
		ELSE 'Private'
  END                             AS Hospitalist_NP_PA_Flag

INTO #TEMP_A

FROM @TOTAL_ORD_COUNT        AS A
LEFT JOIN @TELE_ORDERS       AS B
ON A.Req_Pty_Cd = B.Req_Pty_Cd
	AND A.Ordering_Year = B.Ordering_Year
	AND A.Ordering_Month = B.Ordering_Month
LEFT JOIN @VERBAL_ORDERS     AS C
ON A.Req_Pty_Cd = C.Req_Pty_Cd
	AND A.Ordering_Year = C.Ordering_Year
	AND A.Ordering_Month = C.Ordering_Month
LEFT JOIN @CPOE_ORDERS       AS D
ON A.Req_Pty_Cd = D.Req_Pty_Cd
	AND A.Ordering_Year = D.Ordering_Year
	AND A.Ordering_Month = D.Ordering_Month
LEFT JOIN smsdss.pract_dim_v AS E
ON A.Req_Pty_Cd = E.src_pract_no
	AND E.orgz_cd = 'S0X0'
LEFT JOIN smsdss.pract_dim_v AS F
ON A.Req_Pty_Cd = F.src_pract_no
	AND F.orgz_cd = 'NTX0'
LEFT JOIN smsdss.pract_dim_v AS G
ON A.Req_Pty_Cd = G.src_pract_no
	AND G.orgz_cd = 'XNT'
LEFT JOIN smsdss.pract_dim_v AS H
ON A.Req_Pty_Cd = H.src_pract_no
	AND H.orgz_cd = '0002'
LEFT JOIN smsmir.pract_mstr  AS I
ON A.Req_Pty_Cd = I.pract_no
	AND I.iss_orgz_cd = '0002'
LEFT JOIN smsmir.pract_mstr  AS J
ON A.Req_Pty_Cd = J.pract_no
	AND J.iss_orgz_cd = 'NTX0'
LEFT JOIN smsmir.pract_mstr  AS K
ON A.Req_Pty_Cd = K.pract_no
	AND K.iss_orgz_cd = 'S0X0'

---------------------------------------------------------------------------------------------------
SELECT a.REQ_PTY_CD
, COALESCE(
	B.PRACT_RPT_NAME, 
	C.PRACT_RPT_NAME,
	D.PRACT_RPT_NAME, 
	E.PRACT_RPT_NAME,
	F.PRACT_RPT_NAME,
	G.PRACT_RPT_NAME,
	H.PRACT_RPT_NAME
)                            AS PROVIDER_NAME
, A.SPCLTY_CD
, CASE
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'IM' THEN 'Internal Medicine'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'SG' THEN 'Surgery'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'FP' THEN 'Family Practice'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'OB' THEN 'Ob/Gyn'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'PE' THEN 'Pediatrics'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'PS' THEN 'Pyschiatry'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'DT' THEN 'Dentistry'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'AN' THEN 'Anesthesiology'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'RD' THEN 'Radiology'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'IP' THEN 'Internal Medicine/Pediatrics'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'ME' THEN 'Medical Education'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'ED' THEN 'Emergency Department'
	WHEN RIGHT(A.SPCLTY_CD, 2) = 'AH' THEN 'Allied Health Professional'
	ELSE ''
  END                        AS SPCLTY_DESC
, A.HOSPITALIST_NP_PA_FLAG
, A.ORDERING_YEAR
, A.ORDERING_MONTH
, A.TOTAL_ORDER_COUNT
, A.TOTAL_TELE_ORDERS
, A.TOTAL_VERBAL_ORDERS
, A.TOTAL_CPOE_ORDERS

INTO #TOTALS

FROM #TEMP_A                 AS A
LEFT JOIN smsdss.pract_dim_v AS B
ON A.Req_Pty_Cd = B.src_pract_no
	AND B.orgz_cd = 'NTX0'
LEFT JOIN smsdss.pract_dim_v AS C
ON A.Req_Pty_Cd = C.src_pract_no
	AND C.orgz_cd = 'XNT'
LEFT JOIN smsdss.pract_dim_v AS D
ON A.Req_Pty_Cd = D.src_pract_no
	AND D.orgz_cd = '0002'
LEFT JOIN smsdss.pract_dim_v AS E
ON A.REQ_PTY_CD = E.src_pract_no
	AND E.orgz_cd = 'S0X0'
LEFT JOIN smsmir.pract_mstr  AS F
ON A.Req_Pty_Cd = F.pract_no
	AND F.iss_orgz_cd = '0002'
LEFT JOIN smsmir.pract_mstr  AS G
ON A.Req_Pty_Cd = G.pract_no
	AND G.iss_orgz_cd = 'NTX0'
LEFT JOIN smsmir.pract_mstr  AS H
ON A.Req_Pty_Cd = H.pract_no
	AND H.iss_orgz_cd = 'S0X0'

ORDER BY A.REQ_PTY_CD
, A.ORDERING_YEAR
, A.ORDERING_MONTH
;

-----
SELECT A.Req_Pty_Cd
, A.PROVIDER_NAME
, A.SPCLTY_DESC
, A.Hospitalist_NP_PA_Flag
, SUM(A.Total_Order_Count) AS [Total_Order_Count]
, SUM(A.Total_CPOE_Orders) AS [Total_CPOE_Orders]
INTO #ORDERS
FROM #TOTALS AS A
GROUP BY A.Req_Pty_Cd
, A.PROVIDER_NAME
, A.SPCLTY_DESC
, A.Hospitalist_NP_PA_Flag
HAVING SUM(A.Total_CPOE_Orders) > 500
;

-----
SELECT A.Req_Pty_Cd
, A.PROVIDER_NAME
, A.SPCLTY_DESC
, A.Hospitalist_NP_PA_Flag
, A.Total_CPOE_Orders
, A.Total_Order_Count
, ROUND(CAST(A.TOTAL_CPOE_ORDERS AS float) / CAST(A.TOTAL_ORDER_COUNT AS float), 4) AS [CPOE_Percent]
INTO #CPOEPERC
FROM #ORDERS AS A
;
-----
SELECT TOP 10 A.Req_Pty_Cd
, A.PROVIDER_NAME
, A.SPCLTY_DESC
, A.Hospitalist_NP_PA_Flag
, A.Total_CPOE_Orders
, A.Total_Order_Count
, A.CPOE_Percent

FROM #CPOEPERC AS A

WHERE A.Hospitalist_NP_PA_Flag != 'PA / NP'

ORDER BY A.CPOE_Percent DESC
;

SELECT TOP 10 A.Req_Pty_Cd
, A.PROVIDER_NAME
, A.SPCLTY_DESC
, A.Hospitalist_NP_PA_Flag
, A.Total_CPOE_Orders
, A.Total_Order_Count
, A.CPOE_Percent

FROM #CPOEPERC AS A

WHERE A.Hospitalist_NP_PA_Flag != 'PA / NP'

ORDER BY A.CPOE_Percent ASC
;
---------------------------------------------------------------------------------------------------
DROP TABLE #TEMP_A;
DROP TABLE #TOTALS;
DROP TABLE #ORDERS;
DROP TABLE #CPOEPERC;
