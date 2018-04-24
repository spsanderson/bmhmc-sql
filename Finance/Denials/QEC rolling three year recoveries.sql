SELECT SUM([appl_dollars_appealed]) as 'Denials',
SUM ([appl_dollars_recovered]) as 'Recoveries'
     
  FROM [SMSPHDSSS0X0].[smsdss].[c_Softmed_Denials_Detail_v] as a 
  LEFT OUTER JOIN smsmir.mir_pyr_mstr as b
  ON a.pyr_cd=b.pyr_cd
  
  WHERE rvw_date BETWEEN '01/01/2012' AND '01/31/2015'
  AND appl_Status <> 'PEND'
  
