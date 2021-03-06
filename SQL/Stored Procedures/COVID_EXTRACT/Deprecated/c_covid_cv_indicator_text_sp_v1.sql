USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_cv_indicator_text_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
    [SC_server].[Soarian_Clin_Prd_1].dbo.HExtendedPatientVisit

Creates Table:
	smsdss.c_covid_indicator_text_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the covid indicator text

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_cv_indicator_text_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
    -- Create a new table called 'c_covid_indicator_text_tbl' in schema 'smsdss'
    -- Drop the table if it already exists
    IF OBJECT_ID('smsdss.c_covid_indicator_text_tbl', 'U') IS NOT NULL
    DROP TABLE smsdss.c_covid_indicator_text_tbl;

    /*
    Covid Indicator Text
    */
    DECLARE @CovidIndTbl TABLE (
        PatientVisit_OID INT,
        PatientAccountID INT,
        Covid_Indicator VARCHAR(1000)
        )

    INSERT INTO @CovidIndTbl
    SELECT A.OBJECTID AS PatientVisit_OID,
        A.PATIENTACCOUNTID,
        B.USERDEFINEDSTRING20
    FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
    INNER JOIN [SC_server].[Soarian_Clin_Prd_1].dbo.HExtendedPatientVisit AS B ON A.PatientVisitExtension_OID = B.objectid
    WHERE A.OBJECTID IN (
            SELECT DISTINCT PatientVisitOID
            FROM smsdss.c_covid_ptvisitoid_tbl
            );

    SELECT *
    INTO smsdss.c_covid_indicator_text_tbl
    FROM @CovidIndTbl

END;