/*
#######################################################################
DOES THE PATIENT HAVE OBSERVATION TIME?
#######################################################################
*/
-- T4 DECLARATION
DECLARE @T4 TABLE (
	[MRN]        VARCHAR (200)
	, [VST STRT] DATETIME
	, [REG TIME] DATETIME
	, [SVC]      VARCHAR (5)
)

-- WHAT GETS INSERTED INTO @T4
INSERT INTO @T4
SELECT
D.Med_Rec_No
, D.vst_start_dtime
, D.Reg_Dtime
, D.hosp_svc

-- WHERE IT ALL COMES FROM
FROM (
	SELECT PAV2.MED_REC_NO
	, PAV2.vst_start_dtime
	, ER2.Reg_Dtime
	, ER2.hosp_svc
	
	FROM 
	smsdss.BMH_PLM_PtAcct_V      PAV2
	LEFT OUTER JOIN
	smsdss.c_er_tracking         ER2
	ON PAV2.Med_Rec_No = ER2.med_rec_no
		AND PAV2.vst_start_dtime = ER2.Reg_Dtime
	
	WHERE ER2.hosp_svc = 'OBV'
) D