/*
Find pediatric mental health patients that are non-citizens from inpatients
 - request from Govenors office
 
v1	- 2018-06-22	- request from govenors office, initial creation
*/

DECLARE @START DATETIME;
DECLARE @END   DATETIME;
DECLARE @TODAY DATETIME;

SET @TODAY = GETDATE();
SET @START = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY), - 2);
SET @END   = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY), - 1);

SELECT A.Med_Rec_No
, A.PtNo_Num
, A.Pt_Name
, A.Adm_Date
, A.Pt_Age
, B.UserDataText

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V AS B
ON A.PtNo_Num = B.PtNo_Num

WHERE A.hosp_svc = 'PSY'  -- INPATIENT HOSPITAL SERVICE OF PSY
AND Pt_Age < 18           -- AGE AT ADMIT IS LESS THAN 18
AND Adm_Date >= @START
AND Adm_Date < @END
AND B.UserDataKey = '163' -- TWO FIELD FROM INVISION 2CITIZEN
AND B.UserDataText = 'N'  -- ANSWER TO 2CITIZEN

GO
;