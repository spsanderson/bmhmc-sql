/*
***********************************************************************
File: obs_cd_finder.sql

Input Parameters:
	None

Tables/Views:
	Start Here

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Find Observation Codes from DSS MIR tabls like smsmir.obsv

Revision History:
Date		Version		Description
----		----		----
2020-10-01	v1			Initial Creation
***********************************************************************
*/


SELECT A.episode_no,
	A.dept_cd,
	A.obsv_cre_dtime AS Result_Date,
	A.coll_dtime AS Service_Date,
	C.IdentifierCode AS LoincCd,
	A.dsply_val AS ResultValue,
	A.obsv_std_unit AS ResultUnits,
	A.obsv_cd AS ObsvCd,
	A.obsv_cd_name AS ObsCdDesc,
	C.IdentifierDesc,
	B.RequestedByName AS ProviderName
FROM smsmir.mir_sr_obsv AS A
LEFT OUTER JOIN smsmir.mir_sc_InvestigationResultSuppInfo AS B ON A.rslt_supl_info_obj_id = B.ObjectID
LEFT OUTER JOIN smsmir.mir_sc_ResultIdentifierDetail AS C ON B.ResultIdentifierDetailOid = C.ResultIdentifierDetailOid
WHERE (
		A.coll_dtime BETWEEN '2020-09-01'
			AND '2020-09-02'
		)
ORDER BY A.episode_no,
	A.obsv_cd

