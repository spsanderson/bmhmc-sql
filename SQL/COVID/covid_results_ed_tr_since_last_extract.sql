/*
***********************************************************************
File: covid_results_ed_tr_since_last_extract.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_covid_extract_tbl

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the covid lab results for patients who meet the following criteria
    1. Distinct_Visit_Flag = '1'
	2. PT_ADT = 'ED Only'
	3. order_status = 'Result Signed'

Revision History:
Date		Version		Description
----		----		----
2021-08-03	v1			Initial Creation
*************************************************************************
*/

DECLARE @right_now      AS DATETIME2;
DECLARE @seven_pm_yday  AS DATETIME2;
DECLARE @seven_am_tday  AS DATETIME2;
DECLARE @seven_pm_tday  AS DATETIME2;

SET @right_now      = getdate();
SET @seven_pm_yday  = DATEADD(HOUR, 19, CONVERT(VARCHAR(10), GETDATE() - 1, 110));
SET @seven_am_tday  = DATEADD(HOUR, 7, CONVERT(VARCHAR(10), GETDATE(), 110));
SET @seven_pm_tday  = DATEADD(MINUTE, 1140, DATEDIFF(DAY, 0, GETDATE()));

WITH cte
AS (
	SELECT mrn,
		PTNO_NUM,
		Pt_Name,
		Adm_Dtime,
		Nurs_sta,
		bed,
		result_clean,
		Result_DTime,
		first_positive_flag_dtime,
		hosp_svc,
		CASE 
			WHEN Result_DTime >= @seven_pm_yday
				AND Result_DTime < @seven_am_tday
				AND @right_now BETWEEN @seven_am_tday AND @seven_pm_tday
				THEN 1
			WHEN Result_DTime >= @seven_am_tday
				AND Result_DTime < @seven_pm_tday
				AND @right_now BETWEEN @seven_am_tday and @seven_pm_tday
				THEN 2
			ELSE 0
			END AS [group_number]
	FROM smsdss.c_covid_extract_tbl
	WHERE Distinct_Visit_Flag = '1'
		AND order_status = 'Result Signed'
		AND Pt_ADT = 'ED Only'
	)
SELECT A.*,
[pt_phone] = '(' 
	+ CAST(b.pt_phone_area_city_cd AS varchar) 
	+ ')' 
	+ ' ' 
	+ CAST(LEFT(b.pt_phone_no, 3) AS varchar) 
	+ '-' 
	+ CAST(RIGHT(b.pt_phone_no, 4) AS VARCHAR),
SC_VAX_STS.PatientVaccinationStatusAnswer AS [SC_Vax_Sts],
SC_VAX_STS.AdditionalComments AS [SC_Vax_Comments],
WS_VAX_STS.PatientVaccinationStatusAnswer AS [WS_Vax_Sts]
FROM cte AS A
LEFT JOIN smsmir.hl7_pt AS B ON A.PTNO_NUM = B.pt_id
LEFT JOIN smsdss.c_covid_vax_sts_tbl AS SC_VAX_STS ON A.PTNO_NUM = SC_VAX_STS.PatientAccountID
	AND SC_VAX_STS.Source_System = 'Soarian'
LEFT JOIN smsdss.c_covid_vax_sts_tbl AS WS_VAX_STS ON A.PTNO_NUM = WS_VAX_STS.PatientAccountID
	AND WS_VAX_STS.Source_System = 'WellSoft'
WHERE A.group_number = (
		SELECT max(ZZZ.group_number)
		FROM cte ZZZ
		WHERE ZZZ.group_number != 0
		)
ORDER BY A.Pt_Name
