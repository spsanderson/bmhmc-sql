DECLARE @SD AS DATETIME;
DECLARE @ED AS DATETIME;
SET @SD = '2013-01-01';
SET @ED = '2013-12-31';

DECLARE @T1 TABLE (
	MRN VARCHAR(200)
	, NAME VARCHAR(200)
	, [COUNT] INT
)

INSERT INTO @T1
SELECT
A.Med_Rec_No
, A.Pt_Name
, A.[visit count]

FROM (
	SELECT DISTINCT Med_Rec_No
	, Pt_Name
	, COUNT(ptno_num) AS [visit count]

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Plm_Pt_Acct_Type = 'i'
	AND PtNo_Num < '20000000'
	AND Adm_Date BETWEEN @SD AND @ED
	GROUP BY Med_Rec_No
	, Pt_Name
) A

SELECT *
FROM @T1
WHERE [COUNT] >=4
ORDER BY [COUNT] DESC