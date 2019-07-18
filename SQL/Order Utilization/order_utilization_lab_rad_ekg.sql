DECLARE @TotOrdCount TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, [MD Name]           VARCHAR(50)
	, [Encounter]         INT
	, [Order Count]       INT
	, [Service Year]      CHAR(4)
);

WITH CTE1 AS (
	SELECT UPPER(A.PRACT_RPT_NAME) AS [MD NAME]
	, A.PTNO_NUM                   AS [PT COUNT]
	, COUNT(B.ENCOUNTER)           AS [ORDER COUNT FOR PT]
	, A.SVC_YR

	FROM smsdss.C_IP_COUNT_FOR_ORDER_UTILIZATION_PROJECT AS A
	LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization         AS B
	ON A.PTNO_NUM = B.Encounter

	WHERE B.Dup_Order = 0

	GROUP BY A.PRACT_RPT_NAME
	, A.PTNO_NUM
	, B.ENCOUNTER
	, A.SVC_YR
)

INSERT INTO @TotOrdCount
SELECT * FROM CTE1
--SELECT * FROM @TotOrdCount

/*
=======================================================================
G E T - E D - R A D - O R D E R S
=======================================================================
*/
DECLARE @EDRad TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, [Encounter]          INT
	, [ED Rad Order Count] INT
	, [Service Year]       CHAR(4)
);

WITH CTE2 AS (
	SELECT A.PTNO_NUM
	, COUNT(B.ENCOUNTER) AS ED_RAD_ORDER_COUNT
	, A.SVC_YR

	FROM smsdss.C_IP_COUNT_FOR_ORDER_UTILIZATION_PROJECT AS A
	LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization         AS B
	ON A.PTNO_NUM = B.Encounter	

	WHERE B.Dup_Order = 0
	AND B.ED_IP_FLAG = 'ED'
	AND B.Svc_Dept_Desc = 'RADIOLOGY'

	GROUP BY A.PTNO_NUM
	, B.Encounter
	, A.SVC_YR
)

INSERT INTO @EDRad
SELECT * FROM CTE2
--SELECT * FROM @EDRad

/*
=======================================================================
G E T - I P - R A D - O R D E R S
=======================================================================
*/
DECLARE @IPRad TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, [Encounter]          INT
	, [IP Rad Order Count] INT
	, [Service Year]       CHAR(4)
);

WITH CTE2 AS (
	SELECT A.PTNO_NUM
	, COUNT(B.ENCOUNTER) AS ED_RAD_ORDER_COUNT
	, A.SVC_YR

	FROM smsdss.C_IP_COUNT_FOR_ORDER_UTILIZATION_PROJECT AS A
	LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization         AS B
	ON A.PTNO_NUM = B.Encounter	

	WHERE B.Dup_Order = 0
	AND B.ED_IP_FLAG = 'IP'
	AND B.Svc_Dept_Desc = 'RADIOLOGY'

	GROUP BY A.PTNO_NUM
	, B.Encounter
	, A.SVC_YR
)

INSERT INTO @IPRad
SELECT * FROM CTE2
--SELECT * FROM @IPRad

/*
=======================================================================
G E T - E D - L A B - O R D E R S
=======================================================================
*/
DECLARE @EDLab TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, [Encounter]          INT
	, [ED Lab Order Count] INT
	, [Service Year]       CHAR(4)
);

WITH CTE2 AS (
	SELECT A.PTNO_NUM
	, COUNT(B.ENCOUNTER) AS ED_RAD_ORDER_COUNT
	, A.SVC_YR

	FROM smsdss.C_IP_COUNT_FOR_ORDER_UTILIZATION_PROJECT AS A
	LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization         AS B
	ON A.PTNO_NUM = B.Encounter	

	WHERE B.Dup_Order = 0
	AND B.ED_IP_FLAG = 'ED'
	AND B.Svc_Dept_Desc = 'LABORATORY'

	GROUP BY A.PTNO_NUM
	, B.Encounter
	, A.SVC_YR
)

INSERT INTO @EDLab
SELECT * FROM CTE2
--SELECT * FROM @EDLab


/*
=======================================================================
G E T - I P - L A B - O R D E R S
=======================================================================
*/
DECLARE @IPLab TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, [Encounter]          INT
	, [IP Lab Order Count] INT
	, [Service Year]       CHAR(4)
);

WITH CTE2 AS (
	SELECT A.PTNO_NUM
	, COUNT(B.ENCOUNTER) AS ED_RAD_ORDER_COUNT
	, A.SVC_YR

	FROM smsdss.C_IP_COUNT_FOR_ORDER_UTILIZATION_PROJECT AS A
	LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization         AS B
	ON A.PTNO_NUM = B.Encounter	

	WHERE B.Dup_Order = 0
	AND B.ED_IP_FLAG = 'IP'
	AND B.Svc_Dept_Desc = 'LABORATORY'

	GROUP BY A.PTNO_NUM
	, B.Encounter
	, A.SVC_YR
)

INSERT INTO @IPLab
SELECT * FROM CTE2
--SELECT * FROM @IPLab

/*
=======================================================================
G E T - E D - E K G - O R D E R S
=======================================================================
*/
DECLARE @EDEKG TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, [Encounter]          INT
	, [ED EKG Order Count] INT
	, [Service Year]       CHAR(4)
);

WITH CTE2 AS (
	SELECT A.PTNO_NUM
	, COUNT(B.ENCOUNTER) AS ED_RAD_ORDER_COUNT
	, A.SVC_YR

	FROM smsdss.C_IP_COUNT_FOR_ORDER_UTILIZATION_PROJECT AS A
	LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization         AS B
	ON A.PTNO_NUM = B.Encounter	

	WHERE B.Dup_Order = 0
	AND B.ED_IP_FLAG = 'ED'
	AND B.Svc_Dept_Desc = 'EKG'

	GROUP BY A.PTNO_NUM
	, B.Encounter
	, A.SVC_YR
)

INSERT INTO @EDEKG
SELECT * FROM CTE2
--SELECT * FROM @EDEKG


/*
=======================================================================
G E T - I P - E K G - O R D E R S
=======================================================================
*/
DECLARE @IPEKG TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, [Encounter]          INT
	, [IP EKG Order Count] INT
	, [Service Year]       CHAR(4)
);

WITH CTE2 AS (
	SELECT A.PTNO_NUM
	, COUNT(B.ENCOUNTER) AS ED_RAD_ORDER_COUNT
	, A.SVC_YR

	FROM smsdss.C_IP_COUNT_FOR_ORDER_UTILIZATION_PROJECT AS A
	LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization         AS B
	ON A.PTNO_NUM = B.Encounter	

	WHERE B.Dup_Order = 0
	AND B.ED_IP_FLAG = 'IP'
	AND B.Svc_Dept_Desc = 'EKG'

	GROUP BY A.PTNO_NUM
	, B.Encounter
	, A.SVC_YR
)

INSERT INTO @IPEKG
SELECT * FROM CTE2
--SELECT * FROM @IPEKG

/*
=======================================================================
F I N A L - J O I N S
=======================================================================
*/
SELECT A.[MD Name]
, A.Encounter
, ISNULL(B.[ED Rad Order Count], 0) AS [ED Rad Order Count]
, ISNULL(C.[IP Rad Order Count], 0) AS [IP Rad Order Count]
, (
	ISNULL(B.[ED Rad Order Count], 0)
	+ 
	ISNULL(C.[IP Rad Order Count], 0)
)                                   AS [Total Rad Order Count]
, ISNULL(D.[ED Lab Order Count], 0) AS [ED Lab Order Count]
, ISNULL(E.[IP Lab Order Count], 0) AS [IP Lab Order Count]
, (
	ISNULL(D.[ED Lab Order Count], 0)
	+
	ISNULL(E.[IP Lab Order Count], 0)
)                                   AS [Total Lab Order Count]
, ISNULL(F.[ED EKG Order Count], 0) AS [ED EKG Order Count]
, ISNULL(G.[IP EKG Order Count], 0) AS [IP EKG Order Count]
, (
	ISNULL(F.[ED EKG Order Count], 0)
	+
	ISNULL(G.[IP EKG Order Count], 0)
)                                   AS [Total EKG Order Count]
, A.[Order Count] AS [Total Ord Count]
, A.[Service Year]

FROM @TotOrdCount AS A
LEFT JOIN @EDRad  AS B
ON A.Encounter = B.Encounter
LEFT JOIN @IPRad  AS C
ON A.Encounter = C.Encounter
LEFT JOIN @EDLab  AS D
ON A.Encounter = D.Encounter
LEFT JOIN @IPLab  AS E
ON A.Encounter = E.Encounter
LEFT JOIN @EDEKG AS F
ON A.Encounter = F.Encounter
LEFT JOIN @IPEKG AS G
ON A.Encounter = G.Encounter