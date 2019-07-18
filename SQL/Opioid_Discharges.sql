SELECT Med_Rec_No
, COUNT(med_rec_no) AS discharge_count

FROM smsdss.BMH_PLM_PtAcct_V

WHERE prin_dx_cd IN (
	'965.01', -- Overdose on heroin
	'965.00', -- Overdose on other opiate
	'304.00', -- Heroine dependence
	'304.01', -- Heroine dependence
	'304.10', -- Sedative/hypnotic dependence 
	'304.11', -- Sedative/hypnotic dependence
	'304.20', -- Cocaine dependence 
	'304.21', -- Cocaine dependence 
	'304.30', -- Thc/cannabis dependence
	'304.31', -- Thc/cannabis dependence
	'304.40', -- Amphetamine/psychostimulant dependence
	'304.41', -- Amphetamine/psychostimulant dependence
	'304.50', -- Hallucinogen dependence
	'304.51', -- Hallucinogen dependence
	'304.60', -- Other dependence, huffing, pcp
	'304.61', -- Other dependence, huffing, pcp
	'304.70', -- Combonation of opioids with other drugs
	'304.71', -- Combonation of opioids with other drugs
	'304.80', -- Combonation of drugs, excluding opioids
	'304.81', -- Combonation of drugs, excluding opioids
	'304.90', -- Unspecified dependence
	'304.91', -- Unspecified dependence
	
	-- ICD-10 EQUIVALENT CODES FOR 965.01
	'T40.1X4A', 'T40.1X3A', 'T40.1X2A', 'T40.1X1A', 
	
	-- ICD-10 EQUIVALENT CODES FOR 965.00
	'T40.0X4A', 'T40.0X3A', 'T40.0X2A', 'T40.0X1A', 
	
	-- ICD-9 304 SERIES CODES
	'F1910', 'F19.99', 'F19.97', 'F19.96', 'F19.94', 
	'F19.90', 'F19.29', 'F19.27', 'F19.26', 'F19.24', 'F19.21', 'F19.20', 
	'F19.19', 'F19.17', 'F19.16', 'F19.14', 'F18.99', 'F18.97', 'F18.94', 
	'F18.90', 'F18.29', 'F18.27', 'F18.24', 'F18.21', 'F18.20', 'F18.19', 
	'F18.17', 'F18.14', 'F18.10', 'F16.99', 'F16.94', 'F16.90', 'F16.29', 
	'F16.24', 'F16.21', 'F16.20', 'F16.19', 'F16.14', 'F16.10', 'F15.99', 
	'F15.94', 'F15.93', 'F15.90', 'F15.29', 'F15.24', 'F15.23', 'F15.21', 
	'F15.20', 'F15.19', 'F15.14', 'F15.10', 'F14.99', 'F14.94', 'F14.90', 
	'F14.29', 'F14.24', 'F14.23', 'F14.21', 'F14.20', 'F14.19', 'F14.14', 
	'F14.10', 'F13.99', 'F13.97', 'F13.96', 'F13.94', 'F13.90', 'F13.29', 
	'F13.27', 'F13.26', 'F13.24', 'F13.21', 'F13.20', 'F13.19', 'F13.14', 
	'F13.10', 'F12.99', 'F12.90', 'F12.29', 'F12.21', 'F12.20', 'F12.19', 
	'F12.10', 'F11.99', 'F11.94', 'F11.93', 'F11.90', 'F11.29', 'F11.24', 
	'F11.23', 'F11.21', 'F11.20', 'F11.19', 'F11.14', 'F11.10'
) 
-- ICD-9 304 SERIES CODES
OR	(
	   prin_dx_cd BETWEEN 'F11.120' AND 'F11.129'
	OR prin_dx_cd BETWEEN 'F11.150' AND 'F11.159'
	OR prin_dx_cd BETWEEN 'F11.181' AND 'F11.188'
	OR prin_dx_cd BETWEEN 'F11.220' AND 'F11.229'
	OR prin_dx_cd BETWEEN 'F11.250' AND 'F11.259'
	OR prin_dx_cd BETWEEN 'F11.281' AND 'F11.288'
	OR prin_dx_cd BETWEEN 'F11.920' AND 'F11.929'
	OR prin_dx_cd BETWEEN 'F11.950' AND 'F11.959'
	OR prin_dx_cd BETWEEN 'F11.981' AND 'F11.988'
	OR prin_dx_cd BETWEEN 'F12.120' AND 'F11.129'
	OR prin_dx_cd BETWEEN 'F12.150' AND 'F12.159'
	OR prin_dx_cd BETWEEN 'F12.180' AND 'F12.188'
	OR prin_dx_cd BETWEEN 'F12.220' AND 'F12.229'
	OR prin_dx_cd BETWEEN 'F12.250' AND 'F12.259'
	OR prin_dx_cd BETWEEN 'F12.280' AND 'F12.288'
	OR prin_dx_cd BETWEEN 'F12.920' AND 'F12.929'
	OR prin_dx_cd BETWEEN 'F12.950' AND 'F12.959'
	OR prin_dx_cd BETWEEN 'F12.980' AND 'F12.988'
	OR prin_dx_cd BETWEEN 'F13.120' AND 'F13.129'
	OR prin_dx_cd BETWEEN 'F13.150' AND 'F13.159'
	OR prin_dx_cd BETWEEN 'F13.180' AND 'F13.188'
	OR prin_dx_cd BETWEEN 'F13.220' AND 'F13.229'
	OR prin_dx_cd BETWEEN 'F13.230' AND 'F13.239'
	OR prin_dx_cd BETWEEN 'F13.250' AND 'F13.259'
	OR prin_dx_cd BETWEEN 'F13.280' AND 'F13.288'
	OR prin_dx_cd BETWEEN 'F13.920' AND 'F13.929'
	OR prin_dx_cd BETWEEN 'F13.930' AND 'F13.939'
	OR prin_dx_cd BETWEEN 'F13.950' AND 'F13.959'
	OR prin_dx_cd BETWEEN 'F13.980' AND 'F13.988'
	OR prin_dx_cd BETWEEN 'F14.120' AND 'F14.129'
	OR prin_dx_cd BETWEEN 'F14.150' AND 'F14.159'
	OR prin_dx_cd BETWEEN 'F14.180' AND 'F14.188'
	OR prin_dx_cd BETWEEN 'F14.220' AND 'F14.229'
	OR prin_dx_cd BETWEEN 'F14.250' AND 'F14.259'
	OR prin_dx_cd BETWEEN 'F14.280' AND 'F14.288'
	OR prin_dx_cd BETWEEN 'F14.920' AND 'F14.929'
	OR prin_dx_cd BETWEEN 'F14.950' AND 'F14.959'
	OR prin_dx_cd BETWEEN 'F14.980' AND 'F14.988'
	OR prin_dx_cd BETWEEN 'F15.120' AND 'F15.129'
	OR prin_dx_cd BETWEEN 'F15.150' AND 'F15.159'
	OR prin_dx_cd BETWEEN 'F15.180' AND 'F15.188'
	OR prin_dx_cd BETWEEN 'F15.220' AND 'F15.229'
	OR prin_dx_cd BETWEEN 'F15.250' AND 'F15.259'
	OR prin_dx_cd BETWEEN 'F15.280' AND 'F15.288'
	OR prin_dx_cd BETWEEN 'F15.920' AND 'F15.929'
	OR prin_dx_cd BETWEEN 'F15.950' AND 'F15.959'
	OR prin_dx_cd BETWEEN 'F15.980' AND 'F15.988'
	OR prin_dx_cd BETWEEN 'F16.120' AND 'F16.129'
	OR prin_dx_cd BETWEEN 'F16.150' AND 'F16.159'
	OR prin_dx_cd BETWEEN 'F16.180' AND 'F16.188'
	OR prin_dx_cd BETWEEN 'F16.220' AND 'F16.229'
	OR prin_dx_cd BETWEEN 'F16.250' AND 'F16.259'
	OR prin_dx_cd BETWEEN 'F16.280' AND 'F16.288'
	OR prin_dx_cd BETWEEN 'F16.920' AND 'F16.929'
	OR prin_dx_cd BETWEEN 'F16.950' AND 'F16.959'
	OR prin_dx_cd BETWEEN 'F16.980' AND 'F16.988'
	OR prin_dx_cd BETWEEN 'F18.120' AND 'F18.129'
	OR prin_dx_cd BETWEEN 'F18.150' AND 'F18.159'
	OR prin_dx_cd BETWEEN 'F18.180' AND 'F18.188'
	OR prin_dx_cd BETWEEN 'F18.220' AND 'F18.229'
	OR prin_dx_cd BETWEEN 'F18.250' AND 'F18.259'
	OR prin_dx_cd BETWEEN 'F18.280' AND 'F18.288'
	OR prin_dx_cd BETWEEN 'F18.920' AND 'F18.929'
	OR prin_dx_cd BETWEEN 'F18.950' AND 'F18.959'
	OR prin_dx_cd BETWEEN 'F18.980' AND 'F18.988'
	OR prin_dx_cd BETWEEN 'F19.120' AND 'F19.129'
	OR prin_dx_cd BETWEEN 'F19.150' AND 'F19.159'
	OR prin_dx_cd BETWEEN 'F19.180' AND 'F19.188'
	OR prin_dx_cd BETWEEN 'F19.220' AND 'F19.229'
	OR prin_dx_cd BETWEEN 'F19.230' AND 'F19.239'
	OR prin_dx_cd BETWEEN 'F19.250' AND 'F19.259'
	OR prin_dx_cd BETWEEN 'F19.280' AND 'F19.288'
	OR prin_dx_cd BETWEEN 'F19.920' AND 'F19.929'
	OR prin_dx_cd BETWEEN 'F19.930' AND 'F19.939'
	OR prin_dx_cd BETWEEN 'F19.950' AND 'F19.959'
	OR prin_dx_cd BETWEEN 'F19.980' AND 'F19.988'
)

AND Dsch_Date >= ''
AND Dsch_Date <  ''

GROUP BY Med_Rec_No
