/*
=======================================================================
GET THE LAST DISCHARGE ORDER
=======================================================================
*/
DECLARE @DischargeOrder TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Pt_Id               INT
	, Encounter           VARCHAR(12)
	, Order_Number        INT
	, Order_Date          DATE
	, Order_Time          TIME
)

INSERT INTO @DischargeOrder

SELECT B.episode_no
	, '0000' + B.episode_no
	, B.ord_no
	, B.DATE
	, B.TIME

FROM (
		SELECT EPISODE_NO         AS [ENCOUNTER]
		, episode_no
		, ORD_NO
		, CAST(ENT_DTIME AS DATE) AS [DATE]
		, CAST(ENT_DTIME AS TIME) AS [TIME]
		, ROW_NUMBER() OVER(
							PARTITION BY EPISODE_NO ORDER BY ORD_NO DESC
							) AS ROWNUM
		FROM smsmir.sr_ord
		WHERE svc_desc = 'DISCHARGE TO'
		AND episode_no < '20000000'
	) B

WHERE B.ROWNUM = 1
AND B.DATE >= CAST(GETDATE() - 1 AS date)

--SELECT * FROM @DischargeOrder

/*
=======================================================================
END
=======================================================================
*/

SELECT A.Pt_Id AS [Pt_Id]
	, A.Encounter AS [Encounter]
	, A.Order_Number AS [Last_Dsch_Ord_No]
	, A.Order_Date 
	, A.Order_Time
	, B.nurse_sta
	, B.bed

FROM @DischargeOrder                     AS A
JOIN SMSDSS.c_soarian_real_time_census_v AS B
ON A.Encounter = B.pt_id
	AND A.Pt_Id = B.pt_no_num