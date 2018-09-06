-- for python
DECLARE @ADDRESS TABLE ( 
        PT_FULL_ADDRESS VARCHAR(MAX) 
 ) 
 
INSERT INTO @ADDRESS 
 
SELECT A.FULL_ADDRESS 
 
FROM ( 
    select a.addr_line1 + ', ' + a.Pt_Addr_City + ', ' + a.Pt_Addr_State + ' ' + a.Pt_Addr_Zip AS [FULL_ADDRESS] 
 
 
    from smsdss.c_patient_demos_v as a 
	left outer join smsdss.BMH_PLM_PtAcct_V as b 
    on a.pt_id = b.Pt_No 
        and a.from_file_ind = b.from_file_ind 


    WHERE a.Pt_Addr_City IS NOT NULL 
    AND a.addr_line1 IS NOT NULL 
    AND a.Pt_Addr_State IS NOT NULL 
    AND a.Pt_Addr_Zip IS NOT NULL 
    AND b.Plm_Pt_Acct_Type = 'I' 
    AND b.tot_chg_amt > 0 
    AND LEFT(B.PTNO_NUM, 1) != '2' 
    AND LEFT(B.PTNO_NUM, 4) != '1999' 
    AND DATEPART(YEAR, B.DSCH_DATE) = 2018 
) A 
; 
 
SELECT * FROM @ADDRESS 
; 
--------
-- For R 
DECLARE @ADDRESS TABLE (
	Encounter VARCHAR(12)
	, FullAddress VARCHAR(MAX) 
	, ZipCode VARCHAR(15)
);
DECLARE @TODAY AS DATE;
DECLARE @YESTERDAY AS DATE;

SET @TODAY = GETDATE();
SET @YESTERDAY = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY), - 1);
 
INSERT INTO @ADDRESS 
 
SELECT A.PtNo_Num
, A.[FullAddress]
, a.Pt_Addr_Zip
 
FROM ( 
    SELECT PtNo_Num
	, a.addr_line1 + ', ' + a.Pt_Addr_City + ', ' + a.Pt_Addr_State + ', ' + a.Pt_Addr_Zip AS [FullAddress] 
	, a.Pt_Addr_Zip
 
	FROM smsdss.c_patient_demos_v AS A
	LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS B
	ON A.pt_id = B.Pt_No
		AND A.from_file_ind = B.from_file_ind

    WHERE a.Pt_Addr_City IS NOT NULL 
    AND a.addr_line1 IS NOT NULL 
    AND a.Pt_Addr_State IS NOT NULL 
    AND a.Pt_Addr_Zip IS NOT NULL 
    AND b.Plm_Pt_Acct_Type = 'I' 
    AND b.tot_chg_amt > 0 
    AND LEFT(B.PTNO_NUM, 1) != '2' 
    AND LEFT(B.PTNO_NUM, 4) != '1999' 
    AND b.Dsch_Date = @YESTERDAY
	--AND B.Dsch_Date >= '2018-07-01'
	--AND B.Dsch_Date < '2018-08-01'
) A 
; 
 
SELECT * FROM @ADDRESS 
; 