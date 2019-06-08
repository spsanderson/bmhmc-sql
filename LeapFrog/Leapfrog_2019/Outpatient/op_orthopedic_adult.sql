/*
***********************************************************************
File: op_orthopedic_adult.sql

Input Parameters:
	None

Tables/Views:
	SMSDSS.BMH_PLM_PtAcct_V
	SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New
	SMSDSS.BMH_UserTwoFact_V AS D
	SMSDSS.BMH_UserTwoField_Dim_V

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Pull adult/peds cases for adult ortho procedures 2019 op lf

Revision History:
Date		Version		Description
----		----		----
2019-06-04	v1			Initial Creation
***********************************************************************
*/

SELECT PAV.Med_Rec_No
, PAV.PtNo_Num
, E.UserDataCd
, D.UserDataText AS 'ORSOS_CASE_NO'
, PAV.Adm_Date
, pvn.ClasfCd
, 'Orthopedic_Adult' AS 'LeapFrog_Procedure_Group'
, CCS.[Description] AS 'CCS_Description'

FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN
ON PAV.Pt_No = PVN.Pt_No
	AND (
		PVN.ClasfCd BETWEEN '64702' AND '64727' OR 
		PVN.ClasfCd BETWEEN '24583' AND '24685' OR 
		PVN.ClasfCd BETWEEN '25500' AND '25620' OR 
		PVN.ClasfCd BETWEEN '25622' AND '25645' OR 
		PVN.ClasfCd BETWEEN '25670' AND '25670' OR 
		PVN.ClasfCd BETWEEN '26600' AND '26785' OR 
		PVN.ClasfCd BETWEEN '25441' AND '25449' OR 
		PVN.ClasfCd BETWEEN '24105' AND '24105' OR 
		PVN.ClasfCd BETWEEN '24301' AND '24342' OR 
		PVN.ClasfCd BETWEEN '25000' AND '25031' OR 
		PVN.ClasfCd BETWEEN '25109' AND '25116' OR 
		PVN.ClasfCd BETWEEN '25260' AND '25318' OR 
		PVN.ClasfCd BETWEEN '26035' AND '26060' OR 
		PVN.ClasfCd BETWEEN '26113' AND '26113' OR 
		PVN.ClasfCd BETWEEN '26116' AND '26125' OR 
		PVN.ClasfCd BETWEEN '26160' AND '26180' OR 
		PVN.ClasfCd BETWEEN '26350' AND '26510' OR 
		PVN.ClasfCd BETWEEN '24343' AND '24352' OR 
		PVN.ClasfCd BETWEEN '24357' AND '24359' OR 
		PVN.ClasfCd BETWEEN '25320' AND '25320' OR 
		PVN.ClasfCd BETWEEN '25800' AND '25830' OR 
		PVN.ClasfCd BETWEEN '26540' AND '26545' OR 
		PVN.ClasfCd BETWEEN '26820' AND '26863' OR 
		PVN.ClasfCd BETWEEN '29835' AND '29838' OR 
		PVN.ClasfCd BETWEEN '29844' AND '29846' OR 
		PVN.ClasfCd BETWEEN '23500' AND '23680' OR 
		PVN.ClasfCd BETWEEN '24498' AND '24582' OR 
		PVN.ClasfCd BETWEEN '25431' AND '25440' OR 
		PVN.ClasfCd BETWEEN '29825' AND '29825' OR 
		PVN.ClasfCd BETWEEN '23470' AND '23474' OR 
		PVN.ClasfCd BETWEEN '29826' AND '29826' OR 
		PVN.ClasfCd BETWEEN '23073' AND '23073' OR 
		PVN.ClasfCd BETWEEN '23405' AND '23412' OR 
		PVN.ClasfCd BETWEEN '23430' AND '23440' OR 
		PVN.ClasfCd BETWEEN '29827' AND '29828' OR 
		PVN.ClasfCd BETWEEN '29806' AND '29807' OR 
		PVN.ClasfCd BETWEEN '63265' AND '63308' OR 
		PVN.ClasfCd BETWEEN '27125' AND '27138' OR 
		PVN.ClasfCd BETWEEN '29914' AND '29916' OR 
		PVN.ClasfCd BETWEEN '29861' AND '29868' OR 
		PVN.ClasfCd BETWEEN '29870' AND '29871' OR 
		PVN.ClasfCd BETWEEN '29888' AND '29889' OR 
		PVN.ClasfCd BETWEEN '29873' AND '29873' OR 
		PVN.ClasfCd BETWEEN '29884' AND '29884' OR 
		PVN.ClasfCd BETWEEN '27403' AND '27409' OR 
		PVN.ClasfCd BETWEEN '29880' AND '29883' OR 
		PVN.ClasfCd BETWEEN '27420' AND '27424' OR 
		PVN.ClasfCd BETWEEN '27427' AND '27429' OR 
		PVN.ClasfCd BETWEEN '27437' AND '27447' OR 
		PVN.ClasfCd BETWEEN '27570' AND '27580' OR 
		PVN.ClasfCd BETWEEN '29874' AND '29879' OR 
		PVN.ClasfCd BETWEEN '29885' AND '29887' OR 
		PVN.ClasfCd BETWEEN '27750' AND '27848' OR 
		PVN.ClasfCd BETWEEN '28320' AND '28322' OR 
		PVN.ClasfCd BETWEEN '28400' AND '28675' OR 
		PVN.ClasfCd BETWEEN '29850' AND '29856' OR 
		PVN.ClasfCd BETWEEN '27600' AND '27606' OR 
		PVN.ClasfCd BETWEEN '27650' AND '27692' OR 
		PVN.ClasfCd BETWEEN '28008' AND '28011' OR 
		PVN.ClasfCd BETWEEN '28086' AND '28092' OR 
		PVN.ClasfCd BETWEEN '27695' AND '27698' OR 
		PVN.ClasfCd BETWEEN '28740' AND '28750' OR 
		PVN.ClasfCd BETWEEN '29891' AND '29892' OR 
		PVN.ClasfCd BETWEEN '29894' AND '29899' OR 
		PVN.ClasfCd BETWEEN '29815' AND '29819' OR 
		PVN.ClasfCd BETWEEN '29830' AND '29834' OR 
		PVN.ClasfCd BETWEEN '29999' AND '29999' OR
		PVN.ClasfCd BETWEEN '28192' AND '28250'
	)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D
ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E
ON D.UserDataKey = E.UserTwoKey

CROSS APPLY (
	SELECT
		CASE
			WHEN PVN.CLASFCD BETWEEN '64702' AND '64727' THEN 'Decompression peripheral nerve'
			WHEN PVN.CLASFCD BETWEEN '24583' AND '24685' THEN 'Treatment, fracture or dislocation of radius and ulna'
			WHEN PVN.CLASFCD BETWEEN '25500' AND '25620' THEN 'Treatment, fracture or dislocation of radius and ulna'
			WHEN PVN.CLASFCD BETWEEN '25622' AND '25645' THEN 'Other fracture and dislocation procedure'
			WHEN PVN.CLASFCD BETWEEN '25670' AND '25670' THEN 'Other fracture and dislocation procedure'
			WHEN PVN.CLASFCD BETWEEN '26600' AND '26785' THEN 'Other fracture and dislocation procedure'
			WHEN PVN.CLASFCD BETWEEN '25441' AND '25449' THEN 'Arthroplasty other than hip or knee'
			WHEN PVN.CLASFCD BETWEEN '24105' AND '24105' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '24301' AND '24342' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '25000' AND '25031' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '25109' AND '25116' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '25260' AND '25318' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '26035' AND '26060' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '26113' AND '26113' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '26116' AND '26125' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '26160' AND '26180' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '26350' AND '26510' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '24343' AND '24352' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '24357' AND '24359' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '25320' AND '25320' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '25800' AND '25830' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '26540' AND '26545' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '26820' AND '26863' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '29835' AND '29838' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '29844' AND '29846' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '23500' AND '23680' THEN 'Other fracture and dislocation procedure'
			WHEN PVN.CLASFCD BETWEEN '24498' AND '24582' THEN 'Other fracture and dislocation procedure'
			WHEN PVN.CLASFCD BETWEEN '25431' AND '25440' THEN 'Other fracture and dislocation procedure'
			WHEN PVN.CLASFCD BETWEEN '29825' AND '29825' THEN 'Division of joint capsule, ligament or cartilage'
			WHEN PVN.CLASFCD BETWEEN '23470' AND '23474' THEN 'Arthroplasty other than hip or knee'
			WHEN PVN.CLASFCD BETWEEN '29826' AND '29826' THEN 'Arthroplasty other than hip or knee'
			WHEN PVN.CLASFCD BETWEEN '23073' AND '23073' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '23405' AND '23412' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '23430' AND '23440' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '29827' AND '29828' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '29806' AND '29807' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '63265' AND '63308' THEN 'Other OR therapeutic nervous system procedures'
			WHEN PVN.CLASFCD BETWEEN '27125' AND '27138' THEN 'Hip replacement, total and partial'
			WHEN PVN.CLASFCD BETWEEN '29914' AND '29916' THEN 'Hip replacement, total and partial'
			WHEN PVN.CLASFCD BETWEEN '29861' AND '29868' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '29870' AND '29871' THEN 'Arthroscopy'
			WHEN PVN.CLASFCD BETWEEN '29888' AND '29889' THEN 'Arthroscopy'
			WHEN PVN.CLASFCD BETWEEN '29873' AND '29873' THEN 'Division of joint capsule, ligament or cartilage'
			WHEN PVN.CLASFCD BETWEEN '29884' AND '29884' THEN 'Division of joint capsule, ligament or cartilage'
			WHEN PVN.CLASFCD BETWEEN '27403' AND '27409' THEN 'Excision of semilunar cartilage of knee'
			WHEN PVN.CLASFCD BETWEEN '29880' AND '29883' THEN 'Excision of semilunar cartilage of knee'
			WHEN PVN.CLASFCD BETWEEN '27420' AND '27424' THEN 'Arthroplasty knee'
			WHEN PVN.CLASFCD BETWEEN '27427' AND '27429' THEN 'Arthroplasty knee'
			WHEN PVN.CLASFCD BETWEEN '27437' AND '27447' THEN 'Arthroplasty knee'
			WHEN PVN.CLASFCD BETWEEN '27570' AND '27580' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '29874' AND '29879' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '29885' AND '29887' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '27750' AND '27848' THEN 'Treatment, fracture or dislocation of lower extremity (other than hip or femur)'
			WHEN PVN.CLASFCD BETWEEN '28320' AND '28322' THEN 'Treatment, fracture or dislocation of lower extremity (other than hip or femur)'
			WHEN PVN.CLASFCD BETWEEN '28400' AND '28675' THEN 'Treatment, fracture or dislocation of lower extremity (other than hip or femur)'
			WHEN PVN.CLASFCD BETWEEN '29850' AND '29856' THEN 'Treatment, fracture or dislocation of lower extremity (other than hip or femur)'
			WHEN PVN.CLASFCD BETWEEN '27600' AND '27606' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '27650' AND '27692' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '28008' AND '28011' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '28086' AND '28092' THEN 'Other therapeutic procedures on muscles and tendons'
			WHEN PVN.CLASFCD BETWEEN '27695' AND '27698' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '28740' AND '28750' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '29891' AND '29892' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '29894' AND '29899' THEN 'Other OR therapeutic procedures on joints'
			WHEN PVN.CLASFCD BETWEEN '29815' AND '29819' THEN 'Arthroscopy'
			WHEN PVN.CLASFCD BETWEEN '29830' AND '29834' THEN 'Arthroscopy'
			WHEN PVN.CLASFCD BETWEEN '29999' AND '29999' THEN 'Arthroscopy'
			WHEN PVN.CLASFCD BETWEEN '28192' AND '28250' THEN 'Other therapeutic procedures on muscles and tendons'
		END AS 'Description'
) AS CCS

WHERE PAV.Pt_Age >= 18
AND PAV.tot_chg_amt > 0
AND LEFT(PAV.PTNO_NUM, 1) NOT IN ('2', '8')
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.Adm_Date >= '2018-01-01'
AND PAV.Adm_Date < '2019-01-01'
AND PAV.Plm_Pt_Acct_Type != 'I'

ORDER BY PAV.PtNo_Num