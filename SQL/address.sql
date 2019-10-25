-- for python
DECLARE @ADDRESS TABLE ( 
        PT_FULL_ADDRESS VARCHAR(MAX) 
 ) 
 
INSERT INTO @ADDRESS 
 
SELECT A.FULL_ADDRESS 
 
FROM ( 
    select a.addr_line1 + ', ' + a.Pt_Addr_City + ', ' + a.Pt_Addr_State + ' ' + a.Pt_Addr_Zip AS [FULL_ADDRESS] 
 
	FROM smsdss.c_patient_demos_v AS A
	LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS B
	ON A.pt_id = B.Pt_No
		AND A.from_file_ind = B.from_file_ind
	LEFT OUTER JOIN SMSDSS.c_geocoded_address AS C
	ON B.PtNo_Num = C.Encounter

    WHERE a.Pt_Addr_City IS NOT NULL 
    AND a.addr_line1 IS NOT NULL 
    AND a.Pt_Addr_State IS NOT NULL 
    AND a.Pt_Addr_Zip IS NOT NULL 
    AND b.Plm_Pt_Acct_Type = 'I' 
    AND b.tot_chg_amt > 0 
    AND LEFT(B.PTNO_NUM, 1) != '2' 
    AND LEFT(B.PTNO_NUM, 4) != '1999'
	--AND B.PtNo_Num NOT IN (
	--	SELECT Encounter
	--	FROM smsdss.c_geocoded_address
	--)
	AND B.Dsch_Date >= '2019-01-01'
    AND A.addr_line1 != '101 HOSPITAL RD'
	AND C.Encounter IS NULL
) A 
; 
 
SELECT * FROM @ADDRESS 
; 
--------
-- For R 
SELECT PtNo_Num
, a.addr_line1 + ', ' + a.Pt_Addr_City + ', ' + a.Pt_Addr_State + ', ' + a.Pt_Addr_Zip AS [FullAddress] 
, a.Pt_Addr_Zip
, a.Pt_Addr_City + ', ' + a.Pt_Addr_State + ', ' + a.Pt_Addr_Zip AS [PartialAddress]
 
FROM smsdss.c_patient_demos_v AS A
LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS B
ON A.pt_id = B.Pt_No
	AND A.from_file_ind = B.from_file_ind
LEFT OUTER JOIN SMSDSS.c_geocoded_address AS C
ON B.PtNo_Num = C.Encounter

WHERE a.Pt_Addr_City IS NOT NULL 
AND a.addr_line1 IS NOT NULL 
AND a.Pt_Addr_State IS NOT NULL 
AND a.Pt_Addr_Zip IS NOT NULL 
AND b.Plm_Pt_Acct_Type = 'I' 
AND b.tot_chg_amt > 0 
AND LEFT(B.PTNO_NUM, 1) != '2' 
AND LEFT(B.PTNO_NUM, 4) != '1999'
AND B.Dsch_Date >= '2019-01-01'
AND A.addr_line1 != '101 HOSPITAL RD'
AND C.Encounter IS NULL