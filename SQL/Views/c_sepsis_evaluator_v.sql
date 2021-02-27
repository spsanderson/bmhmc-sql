/*
***********************************************************************
File: c_sepsis_evaluator_v.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_clasf_dx_v
    smsdss.bmh_plm_ptacct_v
    smsdss.bmh_core_measures_dx_cds

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Make a view that can be used to get the sepsis patients for 
    NYS DOH reporting

Revision History:
Date		Version		Description
----		----		----
2021-02-24	v1			Initial Creation
***********************************************************************
*/

USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [smsdss].[c_sepsis_evaluator_v]
AS
SELECT a.Pt_No,
	a.Med_Rec_No,
	a.Adm_Date,
	a.Dsch_Date,
	a.Pt_Birthdate,
	a.Adm_Source,
	a.dsch_disp,
	a.Pt_Age,
	a.prin_dx_cd,
	SEP_Ind = ISNULL(CASE 
			WHEN (
					SELECT COUNT(c.ClasfCd)
					FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V c
					WHERE a.Pt_No = c.Pt_No
						--WHERE a.Pt_Key = c.Pt_Key
						--AND a.Bl_Unit_Key = c.Bl_Unit_Key 
						AND RTRIM(LTRIM(LEFT(c.ClasfType, 2))) = 'DF'
						--AND RTRIM(LTRIM(LEFT(c.ClasfPrio,2))) = '01'                                              
						AND c.ClasfCd IN (
							SELECT e.Clasf_Cd
							FROM smsdss.BMH_Core_Measures_Dx_Cds e
							WHERE e.Core_Group = 'SEP'
							)
					) > 0
				THEN 1
			ELSE 0
			END, 0),
	ORGF_Ind = ISNULL(CASE 
			WHEN (
					SELECT COUNT(c.ClasfCd)
					FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V c
					WHERE a.Pt_No = c.Pt_No
						--WHERE a.Pt_Key = c.Pt_Key
						--AND a.Bl_Unit_Key = c.Bl_Unit_Key 
						AND RTRIM(LTRIM(LEFT(c.ClasfType, 2))) = 'DF'
						--AND RTRIM(LTRIM(LEFT(c.ClasfPrio,2))) = '01'                                              
						AND c.ClasfCd IN (
							SELECT e.Clasf_Cd
							FROM smsdss.BMH_Core_Measures_Dx_Cds e
							WHERE e.Core_Group = 'ORGF'
							)
					) > 0
				THEN 1
			ELSE 0
			END, 0),
	COVID_Ind = ISNULL(CASE 
			WHEN (
					SELECT COUNT(c.ClasfCd)
					FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V c
					WHERE a.Pt_No = c.Pt_No
						--WHERE a.Pt_Key = c.Pt_Key
						--AND a.Bl_Unit_Key = c.Bl_Unit_Key 
						AND RTRIM(LTRIM(LEFT(c.ClasfType, 2))) = 'DF'
						--AND RTRIM(LTRIM(LEFT(c.ClasfPrio,2))) = '01'                                              
						AND c.ClasfCd IN (
							SELECT e.Clasf_Cd
							FROM smsdss.BMH_Core_Measures_Dx_Cds e
							WHERE e.Core_Group = 'COVID'
							)
					) > 0
				THEN 1
			ELSE 0
			END, 0)
FROM smsdss.BMH_PLM_PtAcct_V a
WHERE a.Dsch_date >= '2020-12-01'

GO