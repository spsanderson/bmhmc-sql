/*
***********************************************************************
File: realtime_clockedin_staff.sql

Input Parameters:
	None

Tables/Views:
	[LICOMMHOSP.KRONOS.NET].[tkcsdb].[dbo].[VP_TIMESHTPUNCHV42]
    [smsdss].[c_LI_users]

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Entere Here

Revision History:
Date		Version		Description
----		----		----
2020-11-11	v1			Initial Creation
***********************************************************************
*/
SELECT A.[PERSONFULLNAME],
	A.[PERSONNUM],
	A.[laborlevelname1],
	A.[INPUNCHDTM],
	A.[OUTPUNCHDTM],
	A.[EMPLOYEEID],
	B.[Department],
	B.[Title],
	B.[Company],
	B.[EmployeeNumber]
FROM [LICOMMHOSP.KRONOS.NET].[tkcsdb].[dbo].[VP_TIMESHTPUNCHV42] A
INNER JOIN [smsdss].[c_LI_users] B ON A.[PersonNum] = B.[EmployeeNumber]
WHERE cast(A.[inpunchdtm] AS DATE) = CAST(GETDATE() AS DATE)
	AND A.[outpunchdtm] IS NULL
	AND A.[laborlevelname1] = '6160'
	AND (
		B.Title = 'Registered Nurse'
		OR B.Title LIKE 'Nurse Aide%'
		)
ORDER BY Personfullname
;