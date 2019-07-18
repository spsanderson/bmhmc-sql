/*
--------------------------------------------------------------------------------

File : j_accounts.sql

Parameters : 
	NONE
--------------------------------------------------------------------------------
Purpose: Get J accounts from ORSOS

Tables: 
	[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE]
	[BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES]
	[BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL]
	[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE]
	[BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ANES_TYPE]
	
Views:
	None
	
Functions: None
	
Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle
	
Revision History: 
Date		Version		Description
----		----		----
2018-10-05	v1			Initial Creation
--------------------------------------------------------------------------------
*/

DECLARE @ORSOS_START_DT DATETIME;
DECLARE @ORSOS_END_DT   DATETIME;

SET @ORSOS_START_DT = '2018-09-01 00:00:00';
SET @ORSOS_END_DT   = '2018-09-30 00:00:00';
---------------------------------------------------------------------------------------------------
SELECT A.CASE_NO
, C.FACILITY_ACCOUNT_NO

FROM 
(
	(
		[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE] AS A
		INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES] AS B
		ON A.MAIN_PROCEDURE_ID = B.PROCEDURE_ID
	)
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS C
	ON A.ACCOUNT_NO = C.ACCOUNT_NO
)
LEFT JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE] AS D
ON A.CASE_NO = D.CASE_NO
LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ANES_TYPE] AS E
ON D.ANES_TYPE_CODE = E.CODE

WHERE (
	A.DELETE_FLAG IS NULL
	OR 
	(
		A.DELETE_FLAG = ''
		OR
		A.DELETE_FLAG = 'Z'
	)
)
AND (
	A.START_DATE >= @ORSOS_START_DT
	AND
	A.START_DATE <  @ORSOS_END_DT 
)

AND RIGHT(c.FACILITY_ACCOUNT_NO, 1) = 'J'

ORDER BY C.FACILITY_ACCOUNT_NO