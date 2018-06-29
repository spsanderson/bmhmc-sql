SELECT pt_type,
Category =
(CASE 
  WHEN pt_type IN ('A','B','I','J','M','P','Q','S','W','Y') THEN 'Inpatient'
  WHEN pt_type IN ('E') THEN 'Emergency'
  WHEN pt_type IN ('O','u') THEN 'Referred Ambulatory'
  ELSE 'All Other Outpatient'
END),
Dept =  
(CASE 
  WHEN LEFT(Svc_Cd,3) = '013' THEN 'CAT Scan'
    WHEN LEFT(Svc_Cd,3) = '023' THEN 'MRI'
  ELSE 'Unassigned'
END),
--DATEPART(yyyy,Svc_Date),
SUM(Chg_Qty)


FROM smsdss.BMH_PLM_PtAcct_Svc_V_Hold

WHERE Svc_Date BETWEEN '01/01/2018' AND '04/30/2018'
AND (Svc_Cd BETWEEN '01300000' AND '01306257' OR
svc_Cd BETWEEN '01320001' and '01330406' OR
svc_Cd BETWEEN '01330604' and '01330901' OR
Svc_Cd BETWEEN '02300000' and '02320307' OR
Svc_Cd BETWEEN '02320406' AND '02399999')


AND Tot_Chg_Amt <> 0

GROUP BY pt_type, LEFT(Svc_Cd, 3), DATEPART(yyyy,Svc_Date)

ORDER BY DATEPART(yyyy,Svc_Date), Category, Dept 
