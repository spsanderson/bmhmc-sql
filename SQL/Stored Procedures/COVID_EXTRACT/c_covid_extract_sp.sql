USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_covid_extract_sp]    Script Date: 7/7/2020 2:19:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: 
	c_covid_extract_sp.sql

Input Parameters: 
	None

Tables/Views:
	None

Creates Table: 
	None

Functions: 
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose:
	This sp runs the follwing stored procedures in the following order not parallel:
	1. smsdss.c_covid_vents_sp
	2. smsdss.c_covid_orders_sp
	3. smsdss.c_covid_order_results_sp
	4. smsdss.c_covid_mis_ref_results_sp
	5. smsdss.c_covid_miscref_sp
	6. smsdss.c_covid_wellsoft_sp
	7. smsdss.c_covid_rt_census_sp
	8. smsdss.c_covid_posres_subsequent_visit_sp
	9. smsdss.c_covid_external_positive_sp
	10. smsdss.c_covid_distinct_visit_oid_sp
	11. smsdss.c_covid_patient_visit_data_sp
	12. smsdss.c_covid_hwac_pivot_sp
	13. smsdss.c_covid_adt02order_sp

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
***********************************************************************
*/

ALTER PROCEDURE [smsdss].[c_covid_extract_sp]
AS

BEGIN

	-- below can run in parallel
	EXECUTE smsdss.c_covid_vents_sp 
	EXECUTE smsdss.c_covid_orders_sp
	EXECUTE smsdss.c_covid_order_results_sp 
	EXECUTE smsdss.c_covid_mis_ref_results_sp
	EXECUTE smsdss.c_covid_miscref_sp
	EXECUTE smsdss.c_covid_wellsoft_sp
	EXECUTE smsdss.c_covid_rt_census_sp
	EXECUTE smsdss.c_covid_posres_subsequent_visit_sp
	EXECUTE smsdss.c_covid_external_positive_sp
	
	-- cannot run in parallel
	EXECUTE smsdss.c_covid_distinct_visit_oid_sp
	EXECUTE smsdss.c_covid_patient_visit_data_sp
	
	-- must run after smsdss.c_covid_patient_visit_data_sp
	EXECUTE smsdss.c_covid_hwac_pivot_sp
	EXECUTE smsdss.c_covid_adt02order_sp

END

