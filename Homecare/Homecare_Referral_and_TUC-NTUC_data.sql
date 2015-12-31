-- RUN THE HOMECARE STORED PROCEDURE BEFORE RUNNING THE QUERY SO 
-- THAT THE MOST UP TO DATE DATA IS CAPTURED
EXEC smsdss.c_Home_Care_sp

/*
=======================================================================
CREATE A TABLE FOR HOMECARE REFERRALS. WE DEFINE A REFERRAL AS BEING
MADE IF THE NAME OF THE DOCUMENT IS 'Home Care Referral'
GETS THE RECORD FOR THE LAST DOCUMENT PRINTED.
=======================================================================
*/
DECLARE @Referral TABLE (
	PK INT IDENTITY(1, 1)       PRIMARY KEY
	, Encounter                 INT
	, Homecare_Comments         VARCHAR(MAX)
	, Letter_FaxPrint_DateTime  DATETIME
	, DocumentName              VARCHAR(MAX)
	, PrinterName               VARCHAR(MAX)
	, Rownumber                 INT
);

WITH CTE1 AS (
	SELECT A.BILL_NO            AS [Encounter]
	, B.S_CPM_HOMECARE_COMMENTS AS [Homecare_Comments]
	, C.[DATETIME]              AS [LETTER FAX/PRINT DATE]
	, D.NAME                    AS [DocumentName]
	, E.PRINTER                 AS [PrinterName]
	, ROW_NUMBER() OVER(
						PARTITION BY A.BILL_NO 
						ORDER BY C.[DATETIME] DESC
						)       AS RN

	FROM [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[visit_view]         AS A
	JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[ctc_visit]          AS B
	ON A.VISIT_ID = B._FK_VISIT
	JOIN [BMH-3MHIS-DB].[MMM_cor_BMH_LIVE].[DBO].[CTC_DOCUMENTSENT]   AS C
	ON B._FK_VISIT = C._FK_VISIT
	JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[Dbo].[ctc_letter]         AS D
	ON D._FK_DOCUMENTSENT = C._PK
	JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[Dbo].[ctc_letterPrintJob] AS E
	ON D._PK = E._FK_LETTER
	
	-- This will make sure we start from the beginning case in the 
	-- Home Care Rpt Tbl
	WHERE A.BILL_NO >= (
			SELECT MIN(PtNo_Num)
			FROM SMSDSS.c_Home_Care_Rpt_Tbl
		)
	-- Only capture Inpatients
	AND A.BILL_NO < '20000000'
)

INSERT INTO @Referral
SELECT *
FROM CTE1 C1
WHERE C1.RN = 1

/*
=======================================================================
CREATE TABLE FOR HOMECARE INFORMATION THAT WAS ENTERED INTO INVISION
SO THAT IT CAN BE MATCHED UP WITH A CORRESPONDING REFERRAL
=======================================================================
*/
DECLARE @HomeCareTable TABLE (
	PK INT IDENTITY(1, 1)                  PRIMARY KEY
	, Encounter                            INT
	, MRN                                  INT
	, Homecare_MRN                         INT
	, Admit_Date                           DATE
	, Discharge_Date                       DATE
	, Start_of_care_date                   DATE
	, NTUC_Date                            DATE
	, NTUC_Reason                          VARCHAR(5)
	, Entered_into_Invision_DateTime       DATETIME
);

WITH CTE2 AS (
	SELECT B.PtNo_Num
	, A.Med_Rec_No
	, B.[Home Care MR/EPI]
	, CAST(A.Adm_Date AS DATE)             AS [ADM_DATE]
	, CAST(A.Dsch_Date AS DATE)            AS [DSCH_DATE]
	, CAST(B.[Start of Care Date] AS DATE) AS [Start Of Care Date]
	, CAST(B.[NTUC Date] AS DATE)          AS [NTUC Date]
	, B.[NTUC Reason]
	, B.[Information Entered into Invision On]

	FROM SMSDSS.BMH_PLM_PtAcct_V                AS A
	INNER MERGE JOIN smsdss.c_Home_Care_Rpt_Tbl AS B
	ON A.PtNo_Num = B.PtNo_Num
)

INSERT INTO @HomeCareTable
SELECT *
FROM CTE2 C2
/*
=======================================================================
END
=======================================================================
*/

SELECT A.Encounter
, A.Homecare_Comments
, A.Letter_FaxPrint_DateTime
, A.PrinterName
, B.Encounter
, B.MRN
, B.Homecare_MRN
, B.Admit_Date
, B.Discharge_Date
, B.Start_of_care_date
, B.NTUC_Date
, B.NTUC_Reason
, B.Entered_into_Invision_DateTime

FROM @Referral AS A
LEFT OUTER JOIN @HomeCareTable AS B
ON A.Encounter = B.Encounter