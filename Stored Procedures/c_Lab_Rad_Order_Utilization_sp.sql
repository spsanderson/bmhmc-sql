USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_Lab_Rad_Order_Utilization_sp]    Script Date: 10/11/2017 1:04:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [smsdss].[c_Lab_Rad_Order_Utilization_sp]

AS

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

/*
Author: Steven P Sanderson II, MPH
Department: Finance, Revenue Cycle

Initial data load done from January 1st, 2013 through August 31st 2017

Check to see if the table even exists. If not create and populate, else insert
new records only if the Admit_DateTime is not already in the table, along with Encounter

Procedure will then populate table for data on a month to month basis, this is done to 
limit the run time of the procedure.

v1 - 2017-10-05 - Initial stored procedure creation
v2 - 2017-10-09 - Fix code for Else statement to ELSE BEGIN ... END and re-declare date
                  variables inside of the ELSE BEGIN statement
v3 - 2017-10-10 - Change from Admit Date to Discharge Date

*/

IF NOT EXISTS (
	SELECT TOP 1 * FROM sysobjects WHERE name = 'c_LabRad_OrdUtil_by_DschDT' AND xtype = 'U'
)

BEGIN

	-- DATE VARIABLE DECLARATION AND SET
	DECLARE @END DATETIME;
	DECLARE @START DATETIME;

	-- Beginning of current month
	SET @END = DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0);
	-- Beginning of previous month
	--SET @START = DATEADD(MM, DATEDIFF(mm, 0, GETDATE()) -1, 0);
	--SET @END = '2017-09-01';
	SET @START = '2013-01-01';
	
	-----
	-- If the Lab and Rad Order table does not exist (DNE) then create it.
	-- Use the above IF NOT EXISTS... statement
	CREATE TABLE smsdss.c_LabRad_OrdUtil_by_DschDT ( -- drop table after testing and just smsdss.c_Lab_Rad_Order_Utilization
       PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
       , MRN                 INT NULL
       , Encounter           INT NULL
       , Order_No            INT NULL
       , Order_Loc           VARCHAR(100) NULL
	   , ED_IP_FLAG          VARCHAR(2) NOT NULL
       , Svc_Cd              VARCHAR(100) NULL
       , Svc_Desc            VARCHAR(500) NULL
       , Ord_Set_ID          VARCHAR(200) NULL
       , Ord_Pty_Number      CHAR(6) NULL
       , Ordering_Party      VARCHAR(500) NULL
       , Ord_Pty_Spclty      CHAR(5) NULL
       , Performing_Dept     VARCHAR(100) NULL
       , Svc_Dept_Desc       VARCHAR(10) NULL
       , Svc_Sub_Dept        VARCHAR(100) NULL
	   , Svc_Sub_Dept_Desc   VARCHAR(18) NULL
       , Ord_Occ_No          INT NULL
       , Ord_Occ_Obj_ID      INT NULL
       , Ord_Entry_DTime     DATETIME NULL
       , Ord_Start_DTime     DATETIME NULL
       , Ord_Stop_DTime      DATETIME NULL
       , Order_Status        VARCHAR(250) NULL
       , Order_Occ_Status    VARCHAR(250) NULL
       , Dsch_DateTime       DATETIME NULL
	   , Dup_Order           CHAR(1) NULL
       , Dsch_Year           VARCHAR(100) 
	   , RunDate             DATE NOT NULL
	   , RunDateTime         DATETIME NOT NULL
	   , RN                  INT
	   , Ord_Ent_Yr          VARCHAR(10)
	   , Ord_Ent_Mo          VARCHAR(10)
	   , Ord_Ent_Hr          VARCHAR(10)
	   , Ord_Ent_Qtr         VARCHAR(10)
	   , Ord_Start_Yr        VARCHAR(10)
	   , Ord_Start_Mo        VARCHAR(10)
	   , Ord_Start_Hr        VARCHAR(10)
	   , Ord_Start_Qtr       VARCHAR(10)
	   , Ord_Stop_Yr         VARCHAR(10)
	   , Ord_Stop_Mo         VARCHAR(10)
	   , Ord_Stop_Hr         VARCHAR(10)
	   , Ord_Stop_Qtr        VARCHAR(10)
	   , Dsch_Mo             VARCHAR(10)
	   , Dsch_Hr             VARCHAR(10)
	   , Dsch_Qtr            VARCHAR(10)
	);

	-- Now that table is created, we can run the below in order to get the
	-- results to populate it.
	DECLARE @T1 TABLE (
       PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
       , MRN                 INT
       , Encounter           INT
       , Order_No            INT
       , Order_Loc           VARCHAR(100)
       , Svc_Cd              VARCHAR(100)
       , Svc_Desc            VARCHAR(500)
       , Ord_Set_ID          VARCHAR(200)
       , Ordering_Party      VARCHAR(500)
       , Ord_Pty_Number      CHAR(6)
       , Ord_Pty_Spclty      CHAR(5)
       , Performing_Dept     VARCHAR(100)
       , Svc_Dept            VARCHAR(100)
       , Svc_Sub_Dept        VARCHAR(100)
       , Ord_Occ_No          INT
       , Ord_Occ_Obj_ID      INT
       , Ord_Entry_DTime     DATETIME
       , Ord_Start_DTime     DATETIME
       , Ord_Stop_DTime      DATETIME
       , Order_Status        VARCHAR(250)
       , Order_Occ_sts_cd    CHAR(1)
       , Order_Occ_Status    VARCHAR(250)
       , Dsch_DateTime       DATETIME
       , Dsch_Year           VARCHAR(100) 
       , Dup_Order           CHAR(1)
	);

	WITH T1 AS (
       SELECT A.med_rec_no
       , A.episode_no
       , A.ord_no
       , A.ord_loc
       , A.svc_cd
       , A.svc_desc
       , A.ord_set_id
       , A.pty_name
       , A.pty_cd
       , E.src_spclty_cd
       , A.perf_dept
       , A.svc_dept
       , A.svc_subdept
       , A.ord_occr_no
       , A.ord_occr_obj_id
       , A.ent_dtime
       , A.Order_Str_Dtime
       , A.stp_dtime
       , C.ord_sts_modf  AS [Order_Status]
       , B.occr_sts_cd
       , B.occr_sts_modf AS [Order_Occ_Status]
       , D.dsch_dtime
       , YEAR(d.dsch_dtime) AS [Dsch_Year]
       , a.ovrd_dup_ind

       FROM smsdss.c_sr_orders_finance_rpt_v    AS A
       INNER JOIN SMSMIR.ord_occr_sts_modf_mstr AS B
       ON A.Occr_Sts = B.occr_sts_modf_cd
       INNER JOIN SMSMIR.ord_sts_modf_mstr      AS C
       ON A.ord_sts = C.ord_sts_modf_cd
       LEFT OUTER JOIN smsmir.acct              AS D
       ON A.episode_no = SUBSTRING(D.pt_id, 5, 8)
       LEFT OUTER JOIN smsdss.pract_dim_v       AS E
       ON A.pty_cd = E.src_pract_no
       AND E.orgz_cd = 'S0X0'

       WHERE LEFT(A.svc_cd, 3) IN (
              '004'   -- Lab
			  , '005' -- Rad
			  , '006' -- EKG
			  , '013' -- Cat Scan
			  , '014' -- Ultrasound
			  , '023' -- MRI
       )
       AND C.ord_sts_modf IN ('Complete', 'Discontinue')
       AND D.dsch_date >= @start -- replace with @start for prod
       AND D.dsch_date <  @end -- replace with @end for prod
	   AND LEFT(A.episode_no, 1) IN ('1', '8')
	   AND LEFT(A.episode_no, 4) != '1999'
       -- CAN ADD UNITIZED ACCOUNTS BACK IN IF NEEDED
       --AND LEFT(A.episode_no, 1) != '7'
	)

	INSERT INTO @T1
	SELECT * FROM T1
	;

	SELECT t1.MRN
	, t1.Encounter
	, t1.Order_No
	, t1.Order_Loc
	, CASE
		   WHEN T1.Order_Loc = 'EDICMS'
				  THEN 'ED'
		   WHEN T1.Order_Loc != 'EDICMS'
				  AND LEFT(T1.Encounter, 1) = '8'
				  THEN 'ED'
		   WHEN T1.Order_Loc != 'EDICMS'
				  AND T1.Ord_Pty_Spclty = 'EMRED'
				  THEN 'ED'
		   ELSE 'IP'
	  END AS [ED_IP_FLAG]
	, T1.svc_cd
	, t1.Svc_Desc
	, t1.Ord_Set_ID
	, t1.Ord_Pty_Number
	, t1.Ordering_Party
	, t1.Ord_Pty_Spclty
	, t1.Performing_Dept
	, CASE
		   WHEN T1.Performing_Dept='BMHEKG' THEN 'EKG'
		   WHEN t1.Svc_Sub_Dept IN (
		   '114', '7', '2', '137', '127', '3', '135', '6'  --117
		   )
				  THEN 'Laboratory'
		   WHEN t1.Svc_Sub_Dept IN (
		   '1045', '16', '13', '12', '11', '14', '17', '10', '1004' --133
		   )
				  THEN 'Radiology'
	  END AS [Svc_Dept_Desc]
	, T1.Svc_sub_Dept
	, CASE
		   WHEN T1.Performing_Dept = 'BMHEKG' THEN 'EKG'
		   WHEN t1.Svc_Sub_Dept = '114'  THEN 'Cytology'
		   WHEN t1.Svc_Sub_Dept = '7'    THEN 'Hematology'
		   WHEN t1.Svc_Sub_Dept = '2'    THEN 'Blood Bank'
		   WHEN t1.Svc_Sub_Dept = '137'  THEN 'Serology'
		   WHEN t1.Svc_Sub_Dept = '127'  THEN 'Other'
		   WHEN t1.Svc_Sub_Dept = '3'    THEN 'Microbiology'
		   WHEN t1.Svc_Sub_Dept = '135'  THEN 'Reference'
		   --WHEN t1.Svc_Sub_Dept = '117'  THEN 'Lab Order Only' Remove Per Jim Carr.  SCM 3-25-16
		   WHEN t1.Svc_Sub_Dept = '6'    THEN 'Chemistry'
		   WHEN t1.Svc_Sub_Dept = '1045' THEN 'Mobile PET Scan'
		   WHEN t1.Svc_Sub_Dept = '16'   THEN 'Special Procedures'
		   WHEN t1.Svc_Sub_Dept = '13'   THEN 'MRI'
		   WHEN t1.Svc_Sub_Dept = '12'   THEN 'Mammography'
		   WHEN t1.Svc_Sub_Dept = '11'   THEN 'DX Radiology'
		   --WHEN t1.Svc_Sub_Dept = '133'  THEN 'Rad Order Only' Remove Per Chris Schneider. SCM 3-25-16
		   WHEN t1.Svc_Sub_Dept = '14'   THEN 'Nuclear Medicine'
		   WHEN t1.Svc_Sub_Dept = '17'   THEN 'Ultrasound'
		   WHEN t1.Svc_Sub_Dept = '10'   THEN 'Cat Scan'
		   WHEN t1.Svc_Sub_Dept = '1004' THEN 'BNL'
	  END AS [Svc_Sub_Dept_Desc]
	, t1.Ord_Occ_No
	, t1.Ord_Occ_Obj_ID
	, t1.Ord_Entry_DTime
	, t1.Ord_Start_DTime
	, t1.Ord_Stop_DTime
	, t1.Order_Status
	, t1.Order_Occ_Status
	, t1.Dsch_DateTime
	, t1.Dup_Order
	, T1.Dsch_Year
	, RunDate = CAST(GETDATE() AS date)
	, RunDateTime = GETDATE()

	INTO #TEMP1

	FROM @T1 T1

	WHERE T1.Order_Occ_sts_cd = '4'
	AND T1.SVC_SUB_DEPT NOT IN ('133','117')
	;

	SELECT TEMP1.*
	, RN = ROW_NUMBER() OVER(
		PARTITION BY Encounter
					, Order_No
					, Ord_Occ_No
					, Ord_Occ_Obj_ID
		ORDER BY Encounter
					, Order_No
					, Ord_Occ_No
					, Ord_Occ_Obj_ID
	)
	INTO #TEMP2
	FROM #TEMP1 AS TEMP1
	WHERE TEMP1.ED_IP_FLAG IN ('IP', 'ED')
	AND TEMP1.Svc_Dept_Desc IN ('Laboratory', 'Radiology')
	;

	INSERT INTO smsdss.c_LabRad_OrdUtil_by_DschDT
		
	SELECT TEMP2.*
	, DATEPART(YEAR, TEMP2.Ord_Entry_DTime)    AS Ord_Ent_Yr
	, DATEPART(MONTH, TEMP2.Ord_Entry_DTime)   AS Ord_Ent_Mo
	, DATEPART(HOUR, TEMP2.Ord_Entry_DTime)    AS Ord_Ent_Hr
	, DATEPART(QUARTER, TEMP2.Ord_Entry_DTime) AS Ord_Qtr
	, DATEPART(YEAR, TEMP2.Ord_Start_DTime)    AS Ord_Start_Yr
	, DATEPART(MONTH, TEMP2.Ord_Start_DTime)   AS Ord_Start_Mo
	, DATEPART(HOUR, TEMP2.Ord_Start_DTime)    AS Ord_Start_Hr
	, DATEPART(QUARTER, TEMP2.Ord_Start_DTime) AS Ord_Start_Qtr
	, DATEPART(YEAR, TEMP2.Ord_Stop_DTime)     AS Ord_Stop_Yr
	, DATEPART(MONTH, TEMP2.Ord_Stop_DTime)    AS Ord_Stop_Mo
	, DATEPART(HOUR, TEMP2.Ord_Stop_DTime)     AS Ord_Stop_Hr
	, DATEPART(QUARTER, TEMP2.Ord_Stop_DTime)  AS Ord_Stop_Qtr
	, DATEPART(MONTH, TEMP2.Dsch_DateTime)     AS Dsch_Mo
	, DATEPART(HOUR, TEMP2.Dsch_DateTime)      AS Dsch_Hr
	, DATEPART(QUARTER, TEMP2.Dsch_DateTime)   AS Dsch_Qtr

	FROM #TEMP2 AS TEMP2

	WHERE TEMP2.RN = 1
	;

	DROP TABLE #TEMP1;
	DROP TABLE #TEMP2;
END

ELSE BEGIN
	-- If the IT NOT EXISTS...Evaluates to FALSE, meaning data is returned, then...
	-- DATE VARIABLE DECLARATION AND SET
	DECLARE @END_b DATETIME;
	DECLARE @START_b DATETIME;

	-- Beginning of current month
	SET @END_b = DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0);
	-- Beginning of previous month
	SET @START_b = DATEADD(MM, DATEDIFF(mm, 0, GETDATE()) -1, 0);
	-- Initial Load dates (keep for testing)
	--SET @END_b = '2017-09-01';
	--SET @START_b = '2013-01-01';

	DECLARE @T2 TABLE (
       PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
       , MRN                 INT
       , Encounter           INT
       , Order_No            INT
       , Order_Loc           VARCHAR(100)
       , Svc_Cd              VARCHAR(100)
       , Svc_Desc            VARCHAR(500)
       , Ord_Set_ID          VARCHAR(200)
       , Ordering_Party      VARCHAR(500)
       , Ord_Pty_Number      CHAR(6)
       , Ord_Pty_Spclty      CHAR(5)
       , Performing_Dept     VARCHAR(100)
       , Svc_Dept            VARCHAR(100)
       , Svc_Sub_Dept        VARCHAR(100)
       , Ord_Occ_No          INT
       , Ord_Occ_Obj_ID      INT
       , Ord_Entry_DTime     DATETIME
       , Ord_Start_DTime     DATETIME
       , Ord_Stop_DTime      DATETIME
       , Order_Status        VARCHAR(250)
       , Order_Occ_sts_cd    CHAR(1)
       , Order_Occ_Status    VARCHAR(250)
       , Dsch_DateTime       DATETIME
       , Dsch_Year           VARCHAR(100) 
       , Dup_Order           CHAR(1)
	);

	WITH T2 AS (
       SELECT A.med_rec_no
       , A.episode_no
       , A.ord_no
       , A.ord_loc
       , A.svc_cd
       , A.svc_desc
       , A.ord_set_id
       , A.pty_name
       , A.pty_cd
       , E.src_spclty_cd
       , A.perf_dept
       , A.svc_dept
       , A.svc_subdept
       , A.ord_occr_no
       , A.ord_occr_obj_id
       , A.ent_dtime
       , A.Order_Str_Dtime
       , A.stp_dtime
       , C.ord_sts_modf  AS [Order_Status]
       , B.occr_sts_cd
       , B.occr_sts_modf AS [Order_Occ_Status]
       , D.dsch_dtime
       , YEAR(d.dsch_dtime) AS [Dsch_Year]
       , a.ovrd_dup_ind

       FROM smsdss.c_sr_orders_finance_rpt_v    AS A
       INNER JOIN SMSMIR.ord_occr_sts_modf_mstr AS B
       ON A.Occr_Sts = B.occr_sts_modf_cd
       INNER JOIN SMSMIR.ord_sts_modf_mstr      AS C
       ON A.ord_sts = C.ord_sts_modf_cd
       LEFT OUTER JOIN smsmir.acct              AS D
       ON A.episode_no = SUBSTRING(D.pt_id, 5, 8)
       LEFT OUTER JOIN smsdss.pract_dim_v       AS E
       ON A.pty_cd = E.src_pract_no
       AND E.orgz_cd = 'S0X0'

       WHERE LEFT(A.svc_cd, 3) IN (
              '004'   -- Lab
			  , '005' -- Rad
			  , '006' -- EKG
			  , '013' -- Cat Scan
			  , '014' -- Ultrasound
			  , '023' -- MRI
       )
       AND C.ord_sts_modf IN ('Complete', 'Discontinue')
       AND D.dsch_date >= @START_b -- replace with @start for prod
       AND D.dsch_date <  @END_b -- replace with @end for prod
	   AND LEFT(A.episode_no, 1) IN ('1', '8')
	   AND LEFT(A.episode_no, 4) != '1999'
       -- CAN ADD UNITIZED ACCOUNTS BACK IN IF NEEDED
       --AND LEFT(A.episode_no, 1) != '7'
	)

	INSERT INTO @T2
	SELECT * FROM T2
	;

	SELECT T2.MRN
	, T2.Encounter
	, T2.Order_No
	, T2.Order_Loc
	, CASE
		   WHEN T2.Order_Loc = 'EDICMS'
				  THEN 'ED'
		   WHEN T2.Order_Loc != 'EDICMS'
				  AND LEFT(T2.Encounter, 1) = '8'
				  THEN 'ED'
		   WHEN T2.Order_Loc != 'EDICMS'
				  AND T2.Ord_Pty_Spclty = 'EMRED'
				  THEN 'ED'
		   ELSE 'IP'
	  END AS [ED_IP_FLAG]
	, T2.svc_cd
	, T2.Svc_Desc
	, T2.Ord_Set_ID
	, T2.Ord_Pty_Number
	, T2.Ordering_Party
	, T2.Ord_Pty_Spclty
	, T2.Performing_Dept
	, CASE
		   WHEN T2.Performing_Dept='BMHEKG' THEN 'EKG'
		   WHEN T2.Svc_Sub_Dept IN (
		   '114', '7', '2', '137', '127', '3', '135', '6'  --117
		   )
				  THEN 'Laboratory'
		   WHEN T2.Svc_Sub_Dept IN (
		   '1045', '16', '13', '12', '11', '14', '17', '10', '1004' --133
		   )
				  THEN 'Radiology'
	  END AS [Svc_Dept_Desc]
	, T2.Svc_sub_Dept
	, CASE
		   WHEN T2.Performing_Dept = 'BMHEKG' THEN 'EKG'
		   WHEN T2.Svc_Sub_Dept = '114'  THEN 'Cytology'
		   WHEN T2.Svc_Sub_Dept = '7'    THEN 'Hematology'
		   WHEN T2.Svc_Sub_Dept = '2'    THEN 'Blood Bank'
		   WHEN T2.Svc_Sub_Dept = '137'  THEN 'Serology'
		   WHEN T2.Svc_Sub_Dept = '127'  THEN 'Other'
		   WHEN T2.Svc_Sub_Dept = '3'    THEN 'Microbiology'
		   WHEN T2.Svc_Sub_Dept = '135'  THEN 'Reference'
		   --WHEN t1.Svc_Sub_Dept = '117'  THEN 'Lab Order Only' Remove Per Jim Carr.  SCM 3-25-16
		   WHEN T2.Svc_Sub_Dept = '6'    THEN 'Chemistry'
		   WHEN T2.Svc_Sub_Dept = '1045' THEN 'Mobile PET Scan'
		   WHEN T2.Svc_Sub_Dept = '16'   THEN 'Special Procedures'
		   WHEN T2.Svc_Sub_Dept = '13'   THEN 'MRI'
		   WHEN T2.Svc_Sub_Dept = '12'   THEN 'Mammography'
		   WHEN T2.Svc_Sub_Dept = '11'   THEN 'DX Radiology'
		   --WHEN t1.Svc_Sub_Dept = '133'  THEN 'Rad Order Only' Remove Per Chris Schneider. SCM 3-25-16
		   WHEN T2.Svc_Sub_Dept = '14'   THEN 'Nuclear Medicine'
		   WHEN T2.Svc_Sub_Dept = '17'   THEN 'Ultrasound'
		   WHEN T2.Svc_Sub_Dept = '10'   THEN 'Cat Scan'
		   WHEN T2.Svc_Sub_Dept = '1004' THEN 'BNL'
	  END AS [Svc_Sub_Dept_Desc]
	, T2.Ord_Occ_No
	, T2.Ord_Occ_Obj_ID
	, T2.Ord_Entry_DTime
	, T2.Ord_Start_DTime
	, T2.Ord_Stop_DTime
	, T2.Order_Status
	, T2.Order_Occ_Status
	, T2.Dsch_DateTime
	, T2.Dup_Order
	, T2.Dsch_Year
	, RunDate = CAST(GETDATE() AS date)
	, RunDateTime = GETDATE()

	INTO #TEMPA

	FROM @T2 T2

	WHERE T2.Order_Occ_sts_cd = '4'
	AND T2.SVC_SUB_DEPT NOT IN ('133','117')
	;

	SELECT TEMPA.*
	, RN = ROW_NUMBER() OVER(
		PARTITION BY Encounter
					, Order_No
					, Ord_Occ_No
					, Ord_Occ_Obj_ID
		ORDER BY Encounter
					, Order_No
					, Ord_Occ_No
					, Ord_Occ_Obj_ID
	)
	INTO #TEMPB
	FROM #TEMPA AS TEMPA
	WHERE TEMPA.ED_IP_FLAG IN ('IP', 'ED')
	AND TEMPA.Svc_Dept_Desc IN ('Laboratory', 'Radiology')
	;

	INSERT INTO smsdss.c_LabRad_OrdUtil_by_DschDT
	
	SELECT TEMPB.*
	, DATEPART(YEAR, TEMPB.Ord_Entry_DTime)    AS Ord_Ent_Yr
	, DATEPART(MONTH, TEMPB.Ord_Entry_DTime)   AS Ord_Ent_Mo
	, DATEPART(HOUR, TEMPB.Ord_Entry_DTime)    AS Ord_Ent_Hr
	, DATEPART(QUARTER, TEMPB.Ord_Entry_DTime) AS Ord_Qtr
	, DATEPART(YEAR, TEMPB.Ord_Start_DTime)    AS Ord_Start_Yr
	, DATEPART(MONTH, TEMPB.Ord_Start_DTime)   AS Ord_Start_Mo
	, DATEPART(HOUR, TEMPB.Ord_Start_DTime)    AS Ord_Start_Hr
	, DATEPART(QUARTER, TEMPB.Ord_Start_DTime) AS Ord_Start_Qtr
	, DATEPART(YEAR, TEMPB.Ord_Stop_DTime)     AS Ord_Stop_Yr
	, DATEPART(MONTH, TEMPB.Ord_Stop_DTime)    AS Ord_Stop_Mo
	, DATEPART(HOUR, TEMPB.Ord_Stop_DTime)     AS Ord_Stop_Hr
	, DATEPART(QUARTER, TEMPB.Ord_Stop_DTime)  AS Ord_Stop_Qtr
	, DATEPART(MONTH, TEMPB.Dsch_DateTime)     AS Adm_Mo
	, DATEPART(HOUR, TEMPB.Dsch_DateTime)      AS Adm_Hr
	, DATEPART(QUARTER, TEMPB.Dsch_DateTime)   AS Adm_Qtr

	FROM #TEMPB AS TEMPB
	
	WHERE CAST(GETDATE() AS DATE) <> ISNULL((SELECT MAX(RUNDATE) FROM smsdss.c_LabRad_OrdUtil_by_DschDT), GETDATE() - 1)
	AND TEMPB.Ord_Occ_No NOT IN (
		SELECT DISTINCT(Ord_Occ_No)
		FROM smsdss.c_LabRad_OrdUtil_by_DschDT
	)
	AND TEMPB.RN = 1	
	;

	DROP TABLE #TEMPA;
	DROP TABLE #TEMPB;
END
;