SELECT PAV.Pt_Sex AS [SEX]
, AVG(PAV.Pt_Age) AS [AVG AGE]

FROM smsdss.BMH_PLM_PtAcct_V PAV

WHERE PAV.PtNo_Num IN (

)
GROUP BY PAV.Pt_Sex