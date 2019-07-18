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
	, TimeLeftED
	, ED_MD
	, Disposition

	FROM smsdss.c_Wellsoft_Rpt_tbl
)

SELECT C1.MR#
, C1.Account            AS [Initial Account]
, C2.Account            AS [Secondary Account]
, C1.Patient
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
, DATEDIFF(HOUR, c1.TimeLeftED, C2.[Arrival Datetime]) AS [Interim Hours]

FROM CTE       C1
INNER JOIN CTE C2
ON C1.MR# = C2.MR#

WHERE C1.[Arrival Datetime] <> C2.[Arrival Datetime]
AND C1.RN+1 = C2.RN
AND DATEDIFF(HOUR, c1.TimeLeftED, c2.[Arrival Datetime]) <= 72
and LEFT(c1.TimeLeftED, 4) = '2018'

-- Use below to get between specific dates
AND c1.[Arrival Datetime] >= '2018-02-01'
AND c1.[Arrival Datetime] < '2018-05-01'
AND LEFT(C1.Account, 1) = '8'

ORDER BY [Initial ED Md]
, MR#
, [Arrival 1]