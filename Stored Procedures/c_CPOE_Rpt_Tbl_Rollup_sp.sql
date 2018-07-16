USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
*****************************************************************************  
File: c_CPOE_Rpt_Tbl_Rollup_v.sql      

Input  Parameters:

Tables:   
	smsdss.c_CPOE_Rpt_Tbl
  
Functions:   

Author: Steve P Sanderson II, MPH

Department: Finance, Revenue Cycle

This creates a dynamic view
      
Revision History: 
Date		Version		Description
----		----		----
2018-07-11	v1			Initial Creation
-------------------------------------------------------------------------------- 
*/
--IF OBJECT_ID('smsdss.c_CPOE_Rpt_Tbl_Rollup_v', 'V') IS NOT NULL
--DROP VIEW smsdss.c_CPOE_Rpt_Tbl_Rollup_v
--GO
--;
--CREATE VIEW smsdss.c_CPOE_Rpt_Tbl_Rollup_v
--AS
--SELECT 1 as 'test'
--GO
--;

ALTER PROCEDURE [smsdss].[c_CPOE_Rpt_Tble_Rollup_sp]
AS

BEGIN

	DECLARE @cols AS NVARCHAR(MAX)
	, @query AS NVARCHAR(MAX);

	SELECT @cols = STUFF(
					(
						SELECT DISTINCT ',' + QUOTENAME([Cpoe_Flag]) 
						FROM smsdss.c_CPOE_Rpt_Tbl
						FOR XML PATH(''), TYPE
					).value('.', 'NVARCHAR(MAX)') 
			,1,1,'')
			;

	SET @query = 'ALTER VIEW smsdss.c_CPOE_Rpt_Tbl_Rollup_v
				  AS
				  SELECT ent_date
				  , req_pty_cd
				  , Spclty_Desc
				  , Hospitalist_Np_Pa_Flag
				  , Ord_Type_Abbr
				  , ' + @cols + '
				  FROM (
					SELECT [ent_date]
					, [req_pty_cd]
					, Spclty_Desc
					, Hospitalist_Np_Pa_Flag
					, Ord_Type_Abbr
					, [cpoe_flag]
					FROM smsdss.c_cpoe_rpt_tbl
				  ) x
				  PIVOT (
					COUNT([cpoe_flag])
					FOR [cpoe_flag] IN (' + @cols + ')
				  ) p 
				  ;
				  '
	EXECUTE(@query)
	
END

GO
;