/*
Find pediatric mental health patients that are non-citizens from WellSoft
 - request from Govenors office
 
v1	- 2018-06-22	- request from govenors office, initial creation
*/

DECLARE @START DATETIME;
DECLARE @END   DATETIME;
DECLARE @TODAY DATETIME;

SET @TODAY = GETDATE();
SET @START = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY), - 2);
SET @END   = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY), - 1);

SELECT MR#
, Account
, Patient
, a.Arrival
, a.AgeDOB
, b.UserDataText

FROM smsdss.c_Wellsoft_Rpt_tbl AS a
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V AS b
ON a.Account = b.PtNo_Num

WHERE AreaOfCare = 'ACCESS' -- area of care for mental health
AND DATEDIFF(YEAR, AGEDOB, ARRIVAL) < 18 -- age at arrival is less than 18 years old
AND Arrival >= @START
AND Arrival < @END

AND b.UserDataKey = '163' -- two field from invision 2CITIZEN
AND b.UserDataText = 'N'  -- answer to 2CITIZEN

GO
;