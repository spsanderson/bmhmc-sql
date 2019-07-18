USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_LIHN_Svc_Lines_1_ICD10_v]    Script Date: 11/17/2015 2:47:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO
 
CREATE VIEW [smsdss].[c_LIHN_Svc_Lines_1_ICD10_v]

AS

SELECT a.pt_id
, a.drg_no
, a.drg_schm
, b.drg_name
, REPLACE(i.dx_cd,'.','')   AS [Diag01]
, i.dx_cd_schm AS [icd_cd_schm]
, j.clasf_desc AS [Diagnosis]
, REPLACE(k.proc_cd,'.','') AS [Proc01]
, k.proc_cd_schm            AS [proc_cd_schm]
, l.clasf_desc              AS [Procedure] 
, (
	SELECT DISTINCT(pt_id)
	FROM smsmir.mir_dx_grp AS tt
	WHERE a.pt_id = tt.pt_id 
	AND LEFT(tt.dx_cd_type,2) = 'DF' 
	AND tt.dx_cd IN ('R579','R570')
)                           AS [Shock_Ind]
, (
	SELECT DISTINCT(pt_id)
	FROM smsmir.mir_dx_grp AS tt
	WHERE a.pt_id = tt.pt_id 
	AND LEFT(tt.dx_cd_type,2) = 'DF' 
	AND tt.dx_cd IN ('I200')
)                           AS [Intermed_Coronary_Synd_Ind]
, CASE
	WHEN m.mdc_name LIKE '%DRUG%' 
		THEN 'Sub'
	WHEN m.mdc_name LIKE '%MENTAL%' 
		THEN 'Psych'
	ELSE 'CMN' 
  END                       AS [MS_Case_Type]

FROM smsmir.mir_drg                   AS a 
LEFT OUTER JOIN smsmir.mir_drg_mstr   AS b
ON a.drg_no=b.drg_no 
	AND LEFT(a.drg_schm,4) = LEFT(b.drg_schm,4)
LEFT OUTER JOIN smsmir.mir_dx_grp     AS i
ON a.pt_id = i.pt_id 
	AND i.dx_cd_prio ='01'
	AND LEFT(i.dx_cd_type,2) = 'DF'
	AND dx_cd_schm = '0'
LEFT OUTER JOIN smsmir.mir_clasf_mstr AS j
ON i.dx_cd = j.clasf_cd 
	AND j.clasf_schm = '0'
	-- update ------------
	AND j.clasf_type = 'D'
	-- end of update -----
LEFT OUTER JOIN smsmir.mir_sproc      AS k
ON a.pt_id = k.pt_id 
	AND k.proc_cd_prio = '01' 
	AND proc_cd_type <>'C'
	and k.proc_cd_schm = '0'
LEFT OUTER JOIN smsmir.mir_clasf_mstr AS l
ON LTRIM(RTRIM(k.proc_cd)) = LTRIM(RTRIM(l.clasf_cd)) 
LEFT OUTER JOIN smsmir.mdc_mstr       AS m
ON a.mdc_no = m.mdc

WHERE a.drg_type = '1' 
AND a.drg_schm IN ('MC11','MC12','MC13','MC14','MC15','MCT4', 'MC16', 'MC17','MC18')

GO