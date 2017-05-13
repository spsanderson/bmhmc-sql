select patient_name
, provider_short_name
, leave_recovery_date
, leave_recovery_time
, (CAST(LEAVE_RECOVERY_DATE AS DATETIME)+CAST(LEAVE_RECOVERY_TIME AS DATETIME)-1)+100*365.25 AS [LEFT RECOVERY]
from ORSPROD.POST_CASE
where enter_dept_date between '2013-07-01' and '2013-07-31'