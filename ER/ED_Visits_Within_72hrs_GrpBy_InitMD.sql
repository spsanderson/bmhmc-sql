WITH CTE AS (
	SELECT MR#
	, Account
	, Patient
	, RN = ROW_NUMBER() OVER(PARTITION BY MR# ORDER BY Arrival)
	, AgeDOB
	, sex
	, ChiefComplaint
	, Diagnosis
	, ICD9
	, Arrival as [Arrival Datetime]
	, ED_MD
	, Disposition

	FROM smsdss.c_Wellsoft_Rpt_tbl
)

SELECT C1.Account       AS [Initial Account]
, C2.Account            AS [Secondary Account]
, C1.Patient
, C1.MR#
, C1.ED_MD              AS [Initial ED Md]
, C2.ED_MD              AS [Secondary ED Md]
, c1.ICD9               AS [Initial ICD]
, c1.Diagnosis          AS [Initial Dx]
, c2.ICD9               AS [Secondary ICD]
, c2.Diagnosis          AS [Secondary Dx]
, C1.[Arrival Datetime] AS [Arrival 1]
, C2.[Arrival Datetime] AS [Arrival 2]
, c1.Disposition        AS [Initial Dispo]
, c2.Disposition        AS [Secondary Dispo]
, DATEDIFF(HOUR, c1.[Arrival Datetime], C2.[Arrival Datetime]) AS [Interim Hours]

FROM CTE       C1
INNER JOIN CTE C2
ON C1.MR# = C2.MR#

WHERE C1.[Arrival Datetime] <> C2.[Arrival Datetime]
AND C1.RN+1 = C2.RN
AND DATEDIFF(HOUR, c1.[Arrival Datetime], c2.[Arrival Datetime]) <= 72

-- Use below to get between specific dates
--AND c1.[Arrival Datetime] <= ''
--AND c1.[Arrival Datetime] > ''

-- Use below to get last Sunday - Saturday
AND c1.[Arrival Datetime] >= DATEADD(DD, -1, DATEADD(WK, DATEDIFF(WK, 0, GETDATE()), -7))
AND c1.[Arrival Datetime] <= DATEADD(DD, -1, DATEADD(WK, DATEDIFF(WK, 0, GETDATE()), -1))

ORDER BY [Initial ED Md]
, MR#
, [Arrival 1]