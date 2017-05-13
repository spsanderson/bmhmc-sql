SELECT [PERSONID]
,[PERSONNUM]
,[PERSONFULLNAME]
,[EMPLOYEEID]
,[EMPLOYMENTSTATUSDATE]
,[EMPLOYMENTSTATUS]
,[HOMELABORACCTNAME]
,[HOMELABORLEVELNAME1]
,[HOMELABORLEVELNAME2]
,[Last_Name]
,[First Name]
,[First Initial]
,[First Initial Last Name]
,b.username
,b.login_id
,[First Initial]+(SUBSTRING(LTRIM(RTRIM([First Name])),CAST([MI_Loc] AS int),1))+LEFT(Last_Name,11) AS 'Alt_User'
,SUBSTRING(LTRIM(RTRIM([First Name])),CAST([MI_Loc] AS int),1)
           
FROM [SMSPHDSSS0X0].[smsdss].[c_kronos_employee_v] AS a 
LEFT OUTER JOIN smsmir.mir_user_mstr               AS b
ON LEFT(a.[First Initial Last Name],12) = b.username COLLATE SQL_Latin1_General_CP1_CI_AS
  
ORDER BY PERSONFULLNAME

---

select login_id
, username
from smsmir.mir_user_mstr