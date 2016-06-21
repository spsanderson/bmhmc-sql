-- ALIAS CV3CodedHealthIssue == CHI

SELECT CHI.CODE, CHI.Description

FROM dbo.CV3CodedHealthIssue CHI

WHERE CHI.Code IN ('443.9','437.1','437','438.8','438.9','436','250','v17.3','v12.71','533',
'250.0','250.1','250.2','250.3','796','199.1','573.9','202.8','208.9','428','209.6','593.9',
'294.1','171.8','571.2','571.5','571.6','572.3','795.71','363.14')
ORDER BY CHI.Code