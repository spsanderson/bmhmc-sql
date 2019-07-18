-- RUN THE HOMECARE STORED PROCEDURE BEFORE RUNNING THE QUERY SO 
-- THAT THE MOST UP TO DATE DATA IS CAPTURED
EXEC smsdss.c_Home_Care_sp
GO

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
	, Homecare_Vendor           VARCHAR(5)
	, Homecare_Comments         VARCHAR(MAX)
	, Letter_FaxPrint_DateTime  DATETIME
	, DocumentName              VARCHAR(MAX)
	, PrinterName               VARCHAR(MAX)
	, Rownumber                 INT
);

WITH CTE1 AS (
	SELECT A.BILL_NO            AS [Encounter]
	, B.S_HOMECARE_VENDOR       AS [Homecare Vendor]
	, B.S_CPM_HOMECARE_COMMENTS AS [Homecare_Comments]
	, C.[DATETIME]              AS [LETTER FAX/PRINT DATE]
	, D.NAME                    AS [DocumentName]
	, E.PRINTER                 AS [PrinterName]
	, ROW_NUMBER() OVER(
						PARTITION BY A.BILL_NO 
						ORDER BY C.[DATETIME] DESC
						)       AS RN

	FROM [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[visit_view]              AS A
	LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[ctc_visit]          AS B
	ON A.VISIT_ID = B._FK_VISIT
	LEFT JOIN [BMH-3MHIS-DB].[MMM_cor_BMH_LIVE].[DBO].[CTC_DOCUMENTSENT]   AS C
	ON B._FK_VISIT = C._FK_VISIT
	LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[Dbo].[ctc_letter]         AS D
	ON D._FK_DOCUMENTSENT = C._PK
	LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[Dbo].[ctc_letterPrintJob] AS E
	ON D._PK = E._FK_LETTER
	
	-- This will make sure we start from the beginning case in the 
	-- Home Care Rpt Tbl
	WHERE A.BILL_NO >= (
			SELECT MIN(PtNo_Num)
			FROM SMSDSS.c_Home_Care_Rpt_Tbl
		)
	-- Only capture Inpatients
	AND A.BILL_NO < '20000000'
	AND LEFT(A.BILL_NO, 4) != '1999'
	AND B._PK IS NOT NULL
	AND B.S_CPM_PATIENT_STATUS <> 'IP'
	AND (
		B.S_CPM_REASONFORHOMECARE IS NOT NULL
		OR
		B.S_HOMECARE_VENDOR IS NOT NULL
		OR
		B.DC_TO_DEST IN ('02', '05')
		OR
		B.VISIT_DC_STATUS = 'ATW'
	)
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

/*
=======================================================================
CREATE TABLE THAT WILL GET THE CODED DISCHARGE DISPOSITION OF THE VISIT
=======================================================================
*/
DECLARE @CodedDispo TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, Coded_Disposition   VARCHAR(3)
);

WITH CTE3 AS (
	SELECT A.PtNo_Num
	, A.dsch_disp

	FROM SMSDSS.BMH_PLM_PtAcct_V AS A
	
	WHERE A.PtNo_Num >= (
		SELECT MIN(PtNo_Num)
		FROM SMSDSS.c_Home_Care_Rpt_Tbl
	)
	AND a.PtNo_Num < '20000000'
	AND a.Plm_Pt_Acct_Type = 'I'
)

INSERT INTO @CodedDispo
SELECT *
FROM CTE3 C3
/*
=======================================================================
END
=======================================================================
*/

/*
=======================================================================
GET THE DESCRIPTION OF THE FINAL DISCHARGE ORDER FROM SORIAN
=======================================================================
*/
DECLARE @FinalDischargeOrder TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, Order_Number        INT
	, Order_Date          DATE
	, Order_Time          TIME
	, Order_Description   VARCHAR(MAX)
);

WITH CTE4 AS (
	SELECT B.episode_no
	, B.ord_no
	, B.DATE
	, B.TIME
	, B.desc_as_written

	FROM (
		SELECT EPISODE_NO
		, ORD_NO
		, CAST(ENT_DTIME AS DATE) AS [DATE]
		, CAST(ENT_DTIME AS TIME) AS [TIME]
		, desc_as_written
		, ROW_NUMBER() OVER(
							PARTITION BY EPISODE_NO ORDER BY ORD_NO DESC
							) AS ROWNUM
		FROM smsmir.sr_ord
		WHERE svc_desc = 'DISCHARGE TO'
		AND episode_no < '20000000'
	) B

	WHERE B.ROWNUM = 1
)

INSERT INTO @FinalDischargeOrder
SELECT *
FROM CTE4 C4
/*
=======================================================================
END
=======================================================================
*/

DECLARE @SoarianDispCode TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, Full_Soarian_Dispo  VARCHAR(200)
	, Soarian_Disp_Code   VARCHAR(5)
);

WITH CTE5 AS (
	SELECT episode_no
	, dsch_disp
	, CASE
		WHEN LEFT(dsch_disp, 1) = 'A'
			THEN SUBSTRING(dsch_disp, PATINDEX('%A-%', dsch_disp), 1) +
				 SUBSTRING(dsch_disp, PATINDEX('%A-%', dsch_disp) + 2, 2)
		WHEN (
				PATINDEX('%C -%', dsch_disp) = 1
				OR
				PATINDEX('%D -%', dsch_disp) = 1
			)
			THEN 'Death'			
	  END AS [Soarian_Discharge_Code]
	
	FROM smsmir.mir_sr_vst_pms

	WHERE episode_no < '20000000'
	AND LEFT(episode_no, 4) != '1999'
	AND episode_no NOT IN (
		'12345678910', '99990000999'
	)
	AND dsch_disp IS NOT NULL 
)

INSERT INTO @SoarianDispCode
SELECT * FROM CTE5

--SELECT * FROM @SoarianDispCode
--ORDER BY Encounter
/*
=======================================================================
PULL IT ALL TOGETHER
=======================================================================
*/
SELECT A.Encounter
, B.MRN
, B.Homecare_MRN
, D.Order_Description AS [Final_Soarian_Discharge_Order_Desc]
, CASE
	WHEN PATINDEX('%(A-%', D.Order_Description) != 0
		THEN SUBSTRING(D.Order_Description, PATINDEX('%(A-%', D.ORDER_DESCRIPTION) + 1, 1) +
		     SUBSTRING(D.Order_Description, PATINDEX('%(A-%', D.ORDER_DESCRIPTION) + 3, 2)
	ELSE ''
  END                 AS [Final_Soarian_Disch_Ord_Dispo_Code]
, E.Soarian_Disp_Code AS [Actual_Soarian_Disch_Dispo_Code]
, C.Coded_Disposition
, CASE
	WHEN SUBSTRING(D.Order_Description, PATINDEX('%(A-%', D.ORDER_DESCRIPTION) + 1, 1) +
		 SUBSTRING(D.Order_Description, PATINDEX('%(A-%', D.ORDER_DESCRIPTION) + 3, 2)
		 = C.Coded_Disposition
		THEN 1
	ELSE 0
  END                 AS [Soarian = Coded Dispo (1 = Y, 0 = N)]
, A.Homecare_Vendor
--, A.Homecare_Comments
, A.Letter_FaxPrint_DateTime
, A.PrinterName
, B.Admit_Date
, B.Discharge_Date
, B.Start_of_care_date
, B.NTUC_Date
, B.NTUC_Reason
, B.Entered_into_Invision_DateTime

FROM @Referral                       AS A
LEFT OUTER JOIN @HomeCareTable       AS B
ON A.Encounter = B.Encounter
LEFT OUTER JOIN @CodedDispo          AS C
ON A.Encounter = C.Encounter
LEFT OUTER JOIN @FinalDischargeOrder AS D
ON A.Encounter = D.Encounter
LEFT OUTER JOIN @SoarianDispCode     AS E
ON A.Encounter = E.Encounter