USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_er_rt_esi_staff_sp]    Script Date: 12/14/2020 3:43:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_er_rt_esi_staff_sp.sql

Input Parameters:
	@LookBackPeriods

Tables/Views:
	smsdss.c_real_time_er_staffing_tbl
	smsdss.c_real_time_er_census_tbl

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the last n (@LookBackPeriods) for the ED Census and Staff
	where each period is 15 minutes.

	The data from the smsdss.c_real_time_er_staffing_tbl comes from the
	dbo.c_real_time_er_staffing_tbl_sp

	The data from the smsdss.c_real_time_er_census_tbl comes from the
	WellSoft census Extract automation that runs every 15 minutes, it
	excludes Express Care and Access


Revision History:
Date		Version		Description
----		----		----
2020-12-10	v1			Initial Creation
2020-12-10	v2			Change 
						From: PVT.[Registered Nurse]
						To:   PVT.[Registered Nurse] - 5 AS [Registered Nurse]
						To take counts away from Walk In Triage, Express Care,
						Charge Nurse, Ambulance Bay, and Treatment Room
2021-05-03	v3			Change @ESI_Pvt_Tbl ESI_# from VARCHAR(2) to VARCHAR(20)
***********************************************************************
*/
ALTER PROCEDURE [dbo].[c_er_rt_esi_staff_sp] (@LookBackPeriods AS INT = N'96')
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	DECLARE @Current_DTime AS DATETIME2;
	DECLARE @StartDate AS SMALLDATETIME;
	DECLARE @EndDate AS SMALLDATETIME;

	SET @Current_DTime = GETDATE();
	SET @StartDate = '2020-12-01 08:00:00';
	SET @EndDate = GETDATE();

	DECLARE @ESI_Tbl TABLE (
		[PK] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
		Census_DateTime SMALLDATETIME,
		ESI VARCHAR(2),
		ESI_Count FLOAT
		)

	INSERT INTO @ESI_Tbl
	SELECT Run_DateTime,
		CASE 
			WHEN ESI IS NULL
				OR ESI = ''
				THEN 0
			ELSE ESI
			END AS ESI,
		COUNT(ESI) AS [ESI_COUNT]
	FROM SMSDSS.c_real_time_er_census_tbl
	GROUP BY Run_DateTime,
		ESI
	ORDER BY Run_DateTime,
		ESI;

	DECLARE @ESI_Pvt_Tbl TABLE (
		[PK] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
		Census_DateTime SMALLDATETIME,
		ESI_0 VARCHAR(20),
		ESI_1 VARCHAR(20),
		ESI_2 VARCHAR(20),
		ESI_3 VARCHAR(20),
		ESI_4 VARCHAR(20),
		ESI_5 VARCHAR(20)
		)

	INSERT INTO @ESI_Pvt_Tbl
	SELECT PVT.Census_DateTime,
		PVT.[0] AS [ESI_0],
		PVT.[1] AS [ESI_1],
		PVT.[2] AS [ESI_2],
		PVT.[3] AS [ESI_3],
		PVT.[4] AS [ESI_4],
		PVT.[5] AS [ESI_5]
	FROM (
		SELECT Census_DateTime,
			ESI,
			ESI_Count
		FROM @ESI_Tbl
		) AS A
	PIVOT(MAX(ESI_COUNT) FOR [ESI] IN ("0", "1", "2", "3", "4", "5")) AS PVT

	DECLARE @Staff_Tbl TABLE (
		[PK] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
		Staff_DateTime SMALLDATETIME,
		Staff_Title VARCHAR(100),
		Staff_Count FLOAT
		)

	INSERT INTO @Staff_Tbl
	SELECT Run_DateTime,
		person_title,
		COUNT(person_title) AS Staff_Count
	FROM SMSDSS.c_real_time_er_staffing_tbl
	GROUP BY Run_DateTime,
		person_title
	ORDER BY Run_DateTime

	DECLARE @Staff_Pvt_Tbl TABLE (
		[PK] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
		Staff_DateTime SMALLDATETIME,
		Nurse_Aide_Count FLOAT,
		Nurse_Aide_II_Count FLOAT,
		Registered_Nurse_Count FLOAT
		)

	INSERT INTO @Staff_Pvt_Tbl
	SELECT PVT.Staff_DateTime,
		PVT.[Nurse Aide],
		PVT.[Nurse Aide II],
		PVT.[Registered Nurse] - 5 AS [Registered Nurse]
	FROM (
		SELECT Staff_DateTime,
			Staff_Title,
			Staff_Count
		FROM @Staff_Tbl
		) AS A
	PIVOT(MAX(Staff_Count) FOR Staff_Title IN ("Registered Nurse", "Nurse Aide", "Nurse Aide II")) AS PVT

	DECLARE @TEMP TABLE (
		[PK] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
		Census_DateTime SMALLDATETIME,
		ESI_0 FLOAT,
		ESI_1 FLOAT,
		ESI_2 FLOAT,
		ESI_3 FLOAT,
		ESI_4 FLOAT,
		ESI_5 FLOAT,
		Nurse_Aide_Count FLOAT,
		Nurse_Aide_II_Count FLOAT,
		Registered_Nurse_Count FLOAT,
		id_num INT
		)

	INSERT INTO @TEMP
	SELECT A.Census_DateTime,
		A.ESI_0,
		A.ESI_1,
		A.ESI_2,
		A.ESI_3,
		A.ESI_4,
		A.ESI_5,
		B.Nurse_Aide_Count,
		B.Nurse_Aide_II_Count,
		B.Registered_Nurse_Count,
		id_Num = SUM(1) OVER (
			ORDER BY A.Census_DateTime DESC
			)
	FROM @ESI_Pvt_Tbl AS A
	LEFT JOIN @Staff_Pvt_Tbl AS B ON A.Census_DateTime < B.Staff_DateTime
		AND DATEDIFF(MINUTE, A.Census_DateTime, b.Staff_DateTime) <= 10

	SELECT Census_DateTime,
		ESI_0,
		ESI_1,
		ESI_2,
		ESI_3,
		ESI_4,
		ESI_5,
		Nurse_Aide_Count,
		Nurse_Aide_II_Count,
		Registered_Nurse_Count
	FROM @TEMP
	WHERE id_num <= @LookBackPeriods
	ORDER BY Census_DateTime;
END
