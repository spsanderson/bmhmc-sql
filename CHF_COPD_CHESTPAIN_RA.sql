DECLARE @S DATE;
DECLARE @E DATE;

/*
THE FOLLOWING ARE THE INDEX DATES, SO YOU WANT TO SEE WHO WAS
SAY INITIALLY ADMITTED IN JANUARY - WHICH OF THEM WAS SUBSEQUENTLY
READMITTED
*/
SET @S = '2014-01-01';
SET @E = '2014-04-01';

SELECT
R.med_rec_no
, R.Episode_No
, R.pt_name
, R.adm_date
, R.dsch_date
, CAST(R.days_stay AS INT) AS LOS
, P.PT_AGE
, R.prin_dx_cd
, R.clasf_desc
, R.Admit_Atn_Dr_Name
, R.Days_To_Readmit
, R.B_Adm_Date
, R.B_Dsch_Date
, CAST(R.B_Days_Stay AS INT)

FROM smsdss.c_readmissions_v r
JOIN smsdss.BMH_PLM_PtAcct_V P
ON R.Episode_No = P.PtNo_Num

WHERE R.adm_date >= @S
AND R.adm_date < @E
AND R.adm_src_desc != 'SCHEDULED ADMISSION'
AND R.pt_no < 20000000
AND R.B_Adm_Src_Desc != 'SCHEDULED ADMISSION'
AND R.B_Pt_No < 20000000
AND P.PtNo_Num < '20000000'
AND R.drg_no IN (
		'190','191','192'  -- COPD
		,'291','292','293' -- CHF
		,'287','313'       -- CHEST PAIN
)