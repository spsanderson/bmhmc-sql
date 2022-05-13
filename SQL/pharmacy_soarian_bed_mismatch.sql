/*
***********************************************************************
File: pharmacy_soarian_bed_mismatch.sql

Input Parameters:
	None

Tables/Views:
	imported pharmacy table
    SC_server.Soarn_Clin_Prd_1.DBO.HPatientVisit

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Entere Here

Revision History:
Date		Version		Description
----		----		----
2022-04-20	v1			Initial Creation
***********************************************************************
*/
DECLARE @PharmacyCensus_tbl TABLE (
	nurs_sta VARCHAR(12),
	bed_abbr VARCHAR(12),
	pt_name VARCHAR(255),
	ptno_num VARCHAR(12),
	med_rec_no VARCHAR(12),
	composite_key VARCHAR(255) PRIMARY KEY
)

INSERT INTO @PharmacyCensus_tbl (nurs_sta, bed_abbr, pt_name, ptno_num, med_rec_no, composite_key)
SELECT NRS_STATION,
	LEFT(BED_ABBREV, 4) AS BED_ABBREV,
	PTNAME,
	PAT_NUM,
	PTMEDREC,
	(CAST(PAT_NUM AS VARCHAR) + '_' + LEFT(BED_ABBREV, 4)) AS CK
FROM smsdss.c_test_pharmacy_census;

DECLARE @SoarianCensus_tbl TABLE (
	nurs_sta VARCHAR(12),
	bed_abbr VARCHAR(12),
	ptno_num VARCHAR(12),
	composite_key VARCHAR(255) PRIMARY KEY
)

INSERT INTO @SoarianCensus_tbl (nurs_sta, bed_abbr, ptno_num, composite_key)
SELECT A.PatientLocationName,
	A.LatestBedName,
	A.patientAccountId,
	(CAST(A.PATIENTACCOUNTID AS VARCHAR) + '_' + A.LATESTBEDNAME) AS CK
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0;

SELECT A.nurs_sta,
	a.bed_abbr,
	a.pt_name,
	a.ptno_num,
	a.med_rec_no,
	a.composite_key,
	B.nurs_sta AS [soarian_nurs_sta],
	B.bed_abbr AS [soarian_bed_abbr],
	B.ptno_num AS [soarian_ptno_num],
	B.composite_key [soarian_ck]
FROM @PharmacyCensus_tbl AS A
LEFT JOIN @SoarianCensus_tbl AS B ON A.ptno_num = B.ptno_num
WHERE (
	A.composite_key <> B.composite_key
	OR
	B.composite_key IS NULL
)