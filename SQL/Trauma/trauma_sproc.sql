DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = '2017-04-01';
SET @END   = '2018-04-01';

DECLARE @Trauma_MD AS TABLE (
	ID CHAR(6)
)
INSERT INTO @Trauma_MD (ID)
VALUES('019398'),('019372'),('019356'),('019380'),('008698')
,('013813'),('017772'),('019364')
;

SELECT Surgeries.PT_ID
, Surgeries.PROC_CD_PRIO
, Surgeries.PROC_CD_SCHM
, Surgeries.PROC_CD_TYPE
, Surgeries.PROC_CD
, Surgeries.RESP_PTY_CD
, UPPER(Provider.pract_rpt_name) AS [Provider_Name]
, Surgeries.PROC_EFF_DTIME
, Surgeries.FROM_FILE_IND

--INTO #Trauma_Provider_Procedures

FROM SMSMIR.SPROC AS Surgeries
LEFT OUTER JOIN SMSDSS.PRACT_DIM_V AS Provider
ON Surgeries.resp_pty_cd = Provider.src_pract_no
	and Provider.orgz_cd = 'S0X0'

WHERE Surgeries.RESP_PTY_CD IN (
	SELECT ID
	FROM @Trauma_MD
)
AND Surgeries.proc_eff_date >= @START
AND Surgeries.proc_eff_date < @END

ORDER BY Surgeries.pt_id
;

