-- this is used to create the smsdss.c_ed_e_and_m_order_utilization_project table
--DROP TABLE smsdss.c_ed_e_and_m_order_utilization_project

DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2018-12-01';
SET @END   = '2019-01-01';
-----------------------------------------------------------------------
DECLARE @EDRad TABLE (
PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
, Encounter           INT
, EDMDID              VARCHAR(8)
, ED_MD               VARCHAR(50)
, Svc_Yr              CHAR(4)
, Arrival             DATETIME
, Total_ED_Rad_Orders INT
);

WITH CTE1 AS (
SELECT A.Account
, A.EDMDID
, A.ED_MD
, YEAR(A.Arrival) AS [Svc_Yr]
, A.Arrival
, COUNT(B.Encounter) AS [Total ED Rad Orders]

FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
LEFT JOIN SMSDSS.c_Lab_Rad_Order_Utilization AS B
ON A.Account = B.Encounter
AND B.ED_IP_FLAG = 'ED'
AND B.Svc_Dept_Desc = 'RADIOLOGY'

WHERE A.EDMDID IS NOT NULL
AND A.ED_MD IS NOT NULL
AND A.Arrival >= @START
AND A.Arrival < @END

GROUP BY A.Account
, A.EDMDID
, A.ED_MD
, A.Arrival
, B.Encounter
)
INSERT INTO @EDRad
SELECT * FROM CTE1
--SELECT * FROM @EDRad
-----------------------------------------------------------------------
DECLARE @EDLab TABLE (
PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
, Encounter           INT
, EDMDID              VARCHAR(8)
, ED_MD               VARCHAR(50)
, Svc_Yr              CHAR(4)
, Arrival             DATETIME
, Total_ED_Lab_Orders INT
);

WITH CTE1 AS (
SELECT A.Account
, A.EDMDID
, A.ED_MD
, YEAR(A.Arrival) AS [Svc_Yr]
, A.Arrival
, COUNT(C.Encounter) AS [Total ED Lab Orders]

FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization AS C
ON A.Account = C.Encounter
AND C.ED_IP_FLAG = 'ED'
AND C.Svc_Dept_Desc = 'Laboratory'

WHERE A.EDMDID IS NOT NULL
AND A.ED_MD IS NOT NULL
AND A.Arrival >= @START
AND A.Arrival < @END

GROUP BY A.Account
, A.EDMDID
, A.ED_MD
, A.Arrival
, C.Encounter
)
INSERT INTO @EDLab
SELECT * FROM CTE1
--SELECT * FROM @EDLab
-----------------------------------------------------------------------
INSERT INTO smsdss.c_ed_e_and_m_order_utilization_project

SELECT A.Encounter
, A.EDMDID
, A.ED_MD
, A.Svc_Yr
, A.Arrival
, ISNULL(A.Total_ED_Lab_Orders, 0) AS [Total_ED_Lab_Orders]
, ISNULL(B.Total_ED_Rad_Orders, 0) AS [Total_ED_Rad_Orders]
, (
ISNULL(A.Total_ED_Lab_Orders, 0)
+
ISNULL(B.Total_ED_Rad_Orders, 0)
)                                  AS [Total_ED_Orders]
, C.er_level

FROM @EDLab                  AS A
LEFT OUTER MERGE JOIN @EDRad AS B
ON A.Encounter = B.Encounter
LEFT OUTER MERGE JOIN smsdss.c_er_tracking AS C
on a.Encounter = c.episode_no

WHERE A.Encounter != '99999999'
AND LEFT(A.Encounter, 1) NOT IN ('3', '6')
