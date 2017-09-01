USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_Softmed_Denials_Summary_v]    Script Date: 10/30/2015 15:19:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

ALTER VIEW [smsdss].[c_Softmed_Denials_Summary_v]

AS

SELECT b.pyr_cd
, c.pyr_name
, [cerm_review_status]
, [visit_attend_phys]
, [Attend_Dr]
, [Attend_Dr_No]
, [Attend_Spclty]
, COUNT(DISTINCT([bill_no])) AS 'Discharges'
, [Dsch_Mo]
, [Dsch_Yr]
, CASE
	WHEN Dsch_Mo IN ('1','2','3')    THEN 'Q1'
	WHEN dsch_mo IN ('4','5','6')    THEN 'Q2'
	WHEN Dsch_Mo IN ('7','8','9')    THEN 'Q3'
	WHEN Dsch_Mo IN ('10','11','12') THEN 'Q4'
  ELSE ''
  END                                AS 'Quarter'
, SUM([appl_dollars_appealed])       AS 'Dollars_Appealed'
, SUM([s_cpm_Dollars_not_appealed])  AS 'No_Appeal_Pursued'
, SUM([appl_dollars_recovered])      AS 'Recovered_Amt'
, COUNT([assoc_prvdr])               AS 'Appeals'
, SUM([Short_Stay_Indicator])        AS 'Short_Stays'
, SUM([Long_Stay_Indicator])         AS 'Long_Stays'
, SUM(Short_Stay_Appeal_Indicator)   AS 'Short_Stay_Appeals'
, SUM(Long_Stay_Appeal_Indicator)    AS 'Long_Stay_Appeals'

FROM [SMSPHDSSS0X0].[smsdss].[c_Softmed_Denials_Detail_v] 
LEFT OUTER JOIN smsmir.mir_pyr_plan                       AS b
ON bill_no = pt_id
LEFT OUTER JOIN smsmir.mir_pyr_mstr                       AS c
ON b.pyr_cd=c.pyr_Cd

GROUP BY b.pyr_cd
,c.pyr_name
,[visit_attend_phys]
,[Attend_Dr]
,[Attend_Dr_No]
,[Attend_Spclty]
,[Dsch_Yr]
,[Dsch_Mo]
,[cerm_review_status]
     
GO


