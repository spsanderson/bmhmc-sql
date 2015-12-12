DECLARE @PHYS_3M TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, NAME                VARCHAR(40)
	, NPI                 INT
)

INSERT INTO @PHYS_3M
SELECT A.*
FROM (
	SELECT NAME, NPI
	
	From [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[BMH_RosterList_V]
	
	WHERE [Status] = 'Approved'
) A

--SELECT * FROM @PHYS_3M

DECLARE @PHYS_DSS TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, NAME                VARCHAR(50)
	, NPI                 INT
	, ID_NUM              VARCHAR(15)
)

INSERT INTO @PHYS_DSS
SELECT B.*
FROM (
	SELECT pract_rpt_name
	, npi_no
	, src_pract_no

	FROM SMSDSS.pract_dim_v

	WHERE orgz_cd = 'S0X0'
	AND npi_no != '?'
	AND src_spclty_cd = 'gteim'
) B

--SELECT * FROM @PHYS_DSS

SELECT A.NAME
, A.NPI
, b.ID_NUM

FROM @PHYS_3M AS A
INNER MERGE JOIN @PHYS_DSS AS B
ON A.NPI = B.NPI