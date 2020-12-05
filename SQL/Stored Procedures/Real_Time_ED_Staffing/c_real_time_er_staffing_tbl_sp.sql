USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_real_time_er_staffing_tbl_sp.sql

Input Parameters:
	None

Tables/Views:
	[LICOMMHOSP.KRONOS.NET].[tkcsdb].[dbo].[VP_TIMESHTPUNCHV42]
	[smsdss].[c_LI_users]

Creates Table:
	smsdss.c_real_time_er_staffing_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Create real time emergency room staffing census table

Revision History:
Date		Version		Description
----		----		----
2020-11-30	v1			Initial Creation
2020-12-02	v2			Change punch_in_time parameter to look back 36 hours
***********************************************************************
*/

ALTER PROCEDURE dbo.c_real_time_er_staffing_tbl_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	IF (OBJECT_ID('smsdss.c_real_time_er_staffing_tbl', 'U')) IS NULL
		-- Create a new table called 'c_real_time_er_staffing_tbl' in schema 'smsdss'
		CREATE TABLE smsdss.c_real_time_er_staffing_tbl (
			c_real_time_er_staffing_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, -- primary key column
			[person_full_name] NVARCHAR(500) NULL,
			[person_num] NVARCHAR(6) NULL,
			[labor_level_name] NVARCHAR(6) NULL,
			[punch_datetime_in] DATETIME2 NULL,
			[punch_datetime_out] DATETIME2 NULL,
			[employee_id] VARCHAR(10) NULL,
			[department] NVARCHAR(100) NULL,
			[person_title] NVARCHAR(100) NULL,
			[company] NVARCHAR(10) NULL,
			[employee_number] NVARCHAR(10) NULL,
			[run_datetime] DATETIME2
			);

	INSERT INTO smsdss.c_real_time_er_staffing_tbl (
		[person_full_name],
		[person_num],
		[labor_level_name],
		[punch_datetime_in],
		[punch_datetime_out],
		[employee_id],
		[department],
		[person_title],
		[company],
		[employee_number],
		[run_datetime]
		)
	SELECT A.[PERSONFULLNAME],
		A.[PERSONNUM],
		A.[laborlevelname1],
		A.[INPUNCHDTM],
		A.[OUTPUNCHDTM],
		A.[EMPLOYEEID],
		B.[Department],
		B.[Title],
		B.[Company],
		B.[EmployeeNumber],
		CAST(GETDATE() AS DATETIME2) AS [run_datetime]
	FROM [LICOMMHOSP.KRONOS.NET].[tkcsdb].[dbo].[VP_TIMESHTPUNCHV42] A
	INNER JOIN [smsdss].[c_LI_users] B ON A.[PersonNum] = B.[EmployeeNumber]
	--WHERE cast(A.[inpunchdtm] AS DATE) = CAST(GETDATE() AS DATE)
	WHERE A.[inpunchdtm] >= DATEADD(HOUR, -36, GETDATE())
		AND A.[outpunchdtm] IS NULL
		AND A.[laborlevelname1] = '6160'
		AND (
			B.Title = 'Registered Nurse'
			OR B.Title LIKE 'Nurse Aide%'
			)
	ORDER BY Personfullname
END




