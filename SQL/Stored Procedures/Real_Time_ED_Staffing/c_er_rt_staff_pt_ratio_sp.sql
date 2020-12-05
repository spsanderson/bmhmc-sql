USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_er_rt_staff_pt_ratio_sp.sql

Input Parameters:
	@LookBackPeriods

Tables/Views:
	smsdss.c_real_time_er_staffing_tbl
	smsdss.c_real_time_er_census_tbl

Creates Table:
	smsdss.c_temp_ed_census_tbl
	smsdss.c_temp_ed_staff_tbl
	smsdss.c_temp_staff_pt_ratio_tbl

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
2020-12-03	v1			Initial Creation
***********************************************************************
*/
ALTER PROCEDURE [dbo].[c_er_rt_staff_pt_ratio_sp] (@LookBackPeriods AS INT = N'96')
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

	IF OBJECT_ID('smsdss.c_temp_ed_census_tbl', 'U') IS NOT NULL
		TRUNCATE TABLE smsdss.c_temp_ed_census_tbl
	ELSE
		CREATE TABLE smsdss.c_temp_ed_census_tbl (
			[PK_Id] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
			[Census_DateTime] SMALLDATETIME,
			[Census_Count] FLOAT
			);

	INSERT INTO smsdss.c_temp_ed_census_tbl
	SELECT run_datetime,
		count(*) AS [pt_count]
	FROM smsdss.c_real_time_er_census_tbl
	WHERE Run_DateTime >= @StartDate
	GROUP BY Run_DateTime
	ORDER BY Run_DateTime;

	IF OBJECT_ID('smsdss.c_temp_ed_staff_tbl', 'U') IS NOT NULL
		TRUNCATE TABLE smsdss.c_temp_ed_staff_tbl
	ELSE
		CREATE TABLE smsdss.c_temp_ed_staff_tbl (
			[PK_Id] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
			[Staff_DateTime] SMALLDATETIME,
			[Staff_Count] FLOAT
			);

	INSERT INTO smsdss.c_temp_ed_staff_tbl
	SELECT run_datetime,
		count(*) AS [staff_count]
	FROM smsdss.c_real_time_er_staffing_tbl
	WHERE Run_DateTime >= @StartDate
	GROUP BY Run_DateTime
	ORDER BY Run_DateTime;

	IF OBJECT_ID('smsdss.c_temp_staff_pt_ratio_tbl', 'U') IS NOT NULL
		TRUNCATE TABLE smsdss.c_temp_staff_pt_ratio_tbl
	ELSE
		CREATE TABLE smsdss.c_temp_staff_pt_ratio_tbl (
			[PK] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
			[Census_DateTime] SMALLDATETIME,
			[Census_Count] FLOAT,
			[Staff_DateTime] SMALLDATETIME,
			[Staff_Count] FLOAT,
			[Staff_Pt_Ratio] FLOAT,
			[id_num] INT
			);

	INSERT INTO smsdss.c_temp_staff_pt_ratio_tbl
	SELECT a.Census_DateTime,
		A.Census_Count,
		B.Staff_DateTime,
		B.Staff_Count,
		[Pt_Nurse_Ratio] = ROUND(a.Census_Count / b.Staff_Count, 2),
		[id_num] = sum(1) OVER (
			ORDER BY a.census_datetime DESC
			)
	FROM smsdss.c_temp_ed_census_tbl AS A
	LEFT JOIN smsdss.c_temp_ed_staff_tbl AS B
		-- ensure that the census file from wellsoft has been put into
		-- DSS before the staffing data and that the difference between
		-- the two is 10 minutes or less
		ON A.Census_DateTime < B.Staff_DateTime
		AND DATEDIFF(MINUTE, A.CENSUS_DATETIME, B.STAFF_DATETIME) <= 10;

	SELECT Census_DateTime,
		Census_Count,
		Staff_DateTime,
		Staff_Count,
		Staff_Pt_Ratio
	-- jobs run 96 times a day -> 24 hours divided by 15 minutes = 96
	FROM smsdss.c_temp_staff_pt_ratio_tbl
	WHERE id_num <= @LookBackPeriods
	ORDER BY Census_DateTime;
END
GO


