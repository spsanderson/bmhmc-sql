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
2019-06-25	v2			Add CCSParent Description
2021-06-17	v3			2021 survery 2020 data
***********************************************************************
*/

SELECT PAV.Med_Rec_No,
	PAV.PtNo_Num,
	E.UserDataCd,
	D.UserDataText AS 'ORSOS_CASE_NO',
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	pvn.ClasfCd,
	'Orthopedic_Adult' AS 'LeapFrog_Procedure_Group',
	CCS.[Description] AS 'CCS_Description'
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN ON PAV.Pt_No = PVN.Pt_No
	AND PVN.ClasfCd IN (
		-- General_Orthopedic_Procedures
		'20665', '20670', '20680', '20690', '20692', '20693', '20694', '20696', '20697', '23480', '23485', '23490', '23491', '29830', '29834', '29999',
		-- Toe Foot Ankle and Leg
		'27600', '27601', '27602', '27603', '27604', '27605', '27606', '27650', '27652', '27654', '27656', '27658', '27659', '27664', '27665', '27675', '27676', '27680', '27681', '27685', '27686', '27687', '27690', '27691', '27692', '27695', '27696', '27698', '27750', '27752', '27756', '27758', '27759', '27760', '27762', '27766', '27767', '27768', '27769', '27780', '27781', '27784', '27786', '27788', '27792', '27808', '27810', '27814', '27816', '27818', '27822', '27823', '27824', '27825', '27826', '27827', '27828', '27829', '27831', '27832', '27842', '27846', '27848', '27870', '27871', '27880', '27881', '27882', '27884', '27886', '27888', '27889', '27892', '27893', '27894', '27899', '28001', '28002', '28003', '28008', '28010', '28011', '28020', '28022', '28024', '28035', '28039', '28041', '28043', '28045', '28046', '28047', '28050', '28052', '28054', '28055', '28060', '28062', '28070', '28072', '28080', '28086', '28088', '28090', '28092', '28190', '28192', '28193', '28200', '28202', '28208', '28210', '28220', '28222', '28225', '28226', '28230', '28232', '28234', '28238', '28240', '28250', '28320', '28322'
		, '28400', '28405', '28406', '28415', '28420', '28430', '28435', '28436', '28445', '28446', '28450', '28455', '28456', '28465', '28470', '28475', '28476', '28485', '28490', '28495', '28496', '28505', '28510', '28515', '28525', '28530', '28531', '28545', '28546', '28555', '28570', '28575', '28576', '28585', '28600', '28605', '28606', '28615', '28630', '28635', '28636', '28645', '28665', '28666', '28675', '28705', '28715', '28725', '28730', '28735', '28737', '28740', '28750', '28755', '28760', '28810', '28820', '28825', '29850', '29851', '29855', '29856', '29891', '29892', '29894', '29895', '29897', '29898', '29899',
		-- Knee Procedures
		'27403', '27405', '27407', '27409', '27412', '27415', '27416', '27418', '27420', '27422', '27424', '27425', '27427', '27428', '27429', '27430', '27435', '27437', '27438', '27440', '27441', '27442', '27443', '27445', '27446', '27447', '27448', '27450', '27454', '27455', '27457', '27465', '27466', '27468', '27470', '27472', '27475', '27477', '27479', '27485', '27486', '27487', '27488', '27495', '27496', '27497', '27498', '27499', '27500', '27501', '27502', '27503', '27506', '27507', '27508', '27509', '27510', '27511', '27513', '27514', '27516', '27517', '27519', '27520', '27524', '27530', '27532', '27535', '27536', '27538', '27540', '27550', '27552', '27556', '27557', '27558', '27560', '27562', '27566', '27570', '27580', '29866', '29867', '29868', '29870', '29871', '29873', '29874', '29875', '29876', '29877', '29879', '29880', '29881', '29882', '29883', '29884', '29885', '29886', '29887', '29888', '29889',
		-- Hip Procedures
		'27125', '27130', '27132', '27134', '27137', '27138', '27140', '27146', '27147', '27151', '27156', '27158', '27161', '27165', '27170', '27175', '27176', '27177', '27178', '27179', '27181', '27185', '27187', '27197', '27198', '27200', '27202', '27215', '27216', '27217', '27218', '27220', '27222', '27226', '27227', '27228', '27230', '27236', '27238', '27244', '27245', '27246', '27248', '27250', '27252', '27253', '27254', '27257', '27258', '27259', '27265', '27266', '27267', '27268', '27269', '27232', '27235', '27240', '29861', '29862', '29863', '29914', '29915', '29916',
		-- Spine Procedures
		'63030', '63035', '63040', '63042', '63043', '63044', '63045', '63046', '63047', '63048', '63265', '63266', '63267', '63268', '63270', '63271', '63272', '63273', '63275', '63276', '63277', '63278', '63280', '63281', '63282', '63283', '63285', '63286', '63287', '63290', '63295', '63300', '63301', '63302', '63303', '63304', '63305', '63306', '63307', '63308',
		-- Shoulder Procedures
		'23071', '23073', '23078', '23100', '23101', '23105', '23106', '23107', '23120', '23125', '23130', '23140', '23145', '23146', '23150', '23155', '23156', '23170', '23172', '23174', '23180', '23182', '23184', '23190', '23195', '23200', '23210', '23220', '23330', '23333', '23334', '23335', '23350', '23395', '23397', '23400', '23405', '23406', '23410', '23412', '23430', '23440', '23470', '23472', '23473', '23474', '23500', '23505', '23515', '23530', '23532', '23550', '23552', '23570', '23575', '23585', '23600', '23605', '23615', '23616', '23620', '23625', '23630', '23655', '23660', '23665', '23670', '23675', '23680', '24498', '24500', '24505', '24515', '24516', '24530', '24535', '24538', '24545', '24546', '24560', '24565', '24566', '24575', '24576', '24577', '24579', '24582', '25431', '25440', '29806', '29807', '29819', '29820', '29821', '29822', '29823', '29824', '29825', '29826', '29827', '29828',
		-- Finger Hand Wrist Forearm and Elbow Procedures
		'24105', '24301', '24305', '24310', '24320', '24330', '24331', '24332', '24340', '24341', '24342', '24343', '24344', '24345', '24346', '24357', '24358', '24359', '24586', '24587', '24600', '24605', '24615', '24620', '24635', '24640', '24650', '24655', '24665', '24666', '24670', '24675', '24685', '25000', '25001', '25020', '25023', '25024', '25025', '25028', '25031', '25109', '25110', '25111', '25112', '25115', '25116', '25260', '25263', '25265', '25270', '25272', '25274', '25275', '25280', '25290', '25295', '25300', '25301', '25310', '25312', '25315', '25316', '25320', '25441', '25442', '25443', '25444', '25445', '25446', '25447', '25449', '25500', '25505', '25515', '25520', '25525', '25526', '25530', '25535', '25545', '25560', '25565', '25574', '25575', '25600', '25605', '25606', '25607', '25608', '25609', '25622', '25624', '25628', '25630', '25635', '25645', '25650', '25651', '25652', '25660', '25670', '25671', '25675', '25676', '25680', '25685', '25690', '25695', '25800', '25805', '25810', '25820', '25825', '25830', '26035', '26037', '26040', '26045', '26055', '26060', '26113', '26116', '26117'
		, '26118', '26121', '26123', '26125', '26160', '26170', '26180', '26350', '26352', '26356', '26357', '26358', '26370', '26372', '26373', '26390', '26392', '26410', '26412', '26415', '26416', '26418', '26420', '26426', '26428', '26432', '26433', '26434', '26437', '26440', '26442', '26445', '26449', '26450', '26455', '26460', '26471', '26474', '26476', '26477', '26478', '26479', '26480', '26483', '26485', '26489', '26490', '26492', '26494', '26496', '26497', '26498', '26499', '26500', '26502', '26508', '26510', '26540', '26541', '26542', '26545', '26600', '26605', '26607', '26608', '26615', '26645', '26650', '26665', '26675', '26676', '26685', '26686', '26705', '26706', '26715', '26720', '26725', '26727', '26735', '26740', '26742', '26746', '26750', '26755', '26756', '26765', '26770', '26775', '26776', '26785', '26820', '26841', '26842', '26843', '26844', '26850', '26852', '26860', '26861', '26862', '26863', '26951', '29835', '29836', '29837', '29838', '29844', '29845', '29846', '29847', '29848', '64702', '64704', '64708', '64712', '64713', '64714', '64716', '64718', '64719', '64721', '64722', 
		'64726', '64727'
		)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E ON D.UserDataKey = E.UserTwoKey
CROSS APPLY (
	SELECT CASE 
			WHEN PVN.CLASFCD IN ('20665', '20670', '20680', '20690', '20692', '20693', '20694', '20696', '20697', '23480', '23485', '23490', '23491', '29830', '29834', '29999')
				THEN 'General_Orthopedic_Procedures'
			WHEN PVN.ClasfCd IN (
					'27600', '27601', '27602', '27603', '27604', '27605', '27606', '27650', '27652', '27654', '27656', '27658', '27659', '27664', '27665', '27675', '27676', '27680', '27681', '27685', '27686', '27687', '27690', '27691', '27692', '27695', '27696', '27698', '27750', '27752', '27756', '27758', '27759', '27760', '27762', '27766', '27767', '27768', '27769', '27780', '27781', '27784', '27786', '27788', '27792', '27808', '27810', '27814', '27816', '27818', '27822', '27823', '27824', '27825', '27826', '27827', '27828', '27829', '27831', '27832', '27842', '27846', '27848', '27870', '27871', '27880', '27881', '27882', '27884', '27886', '27888', '27889', '27892', '27893', '27894', '27899', '28001', '28002', '28003', '28008', '28010', '28011', '28020', '28022', '28024', '28035', '28039', '28041', '28043', '28045', '28046', '28047', '28050', '28052', '28054', '28055', '28060', '28062', '28070', '28072', '28080', '28086', '28088', '28090', '28092', '28190', '28192', '28193', '28200', '28202', '28208', '28210', '28220', '28222', '28225', '28226', '28230', '28232', '28234', '28238', '28240', '28250', 
					'28320', '28322', '28400', '28405', '28406', '28415', '28420', '28430', '28435', '28436', '28445', '28446', '28450', '28455', '28456', '28465', '28470', '28475', '28476', '28485', '28490', '28495', '28496', '28505', '28510', '28515', '28525', '28530', '28531', '28545', '28546', '28555', '28570', '28575', '28576', '28585', '28600', '28605', '28606', '28615', '28630', '28635', '28636', '28645', '28665', '28666', '28675', '28705', '28715', '28725', '28730', '28735', '28737', '28740', '28750', '28755', '28760', '28810', '28820', '28825', '29850', '29851', '29855', '29856', '29891', '29892', '29894', '29895', '29897', '29898', '29899'
					)
				THEN 'Toe_Foot_Ankle_and_Leg'
			WHEN PVN.ClasfCd IN ('27403', '27405', '27407', '27409', '27412', '27415', '27416', '27418', '27420', '27422', '27424', '27425', '27427', '27428', '27429', '27430', '27435', '27437', '27438', '27440', '27441', '27442', '27443', '27445', '27446', '27447', '27448', '27450', '27454', '27455', '27457', '27465', '27466', '27468', '27470', '27472', '27475', '27477', '27479', '27485', '27486', '27487', '27488', '27495', '27496', '27497', '27498', '27499', '27500', '27501', '27502', '27503', '27506', '27507', '27508', '27509', '27510', '27511', '27513', '27514', '27516', '27517', '27519', '27520', '27524', '27530', '27532', '27535', '27536', '27538', '27540', '27550', '27552', '27556', '27557', '27558', '27560', '27562', '27566', '27570', '27580', '29866', '29867', '29868', '29870', '29871', '29873', '29874', '29875', '29876', '29877', '29879', '29880', '29881', '29882', '29883', '29884', '29885', '29886', '29887', '29888', '29889')
				THEN 'Knee_Procedures'
			WHEN PVN.ClasfCd IN ('27125', '27130', '27132', '27134', '27137', '27138', '27140', '27146', '27147', '27151', '27156', '27158', '27161', '27165', '27170', '27175', '27176', '27177', '27178', '27179', '27181', '27185', '27187', '27197', '27198', '27200', '27202', '27215', '27216', '27217', '27218', '27220', '27222', '27226', '27227', '27228', '27230', '27236', '27238', '27244', '27245', '27246', '27248', '27250', '27252', '27253', '27254', '27257', '27258', '27259', '27265', '27266', '27267', '27268', '27269', '27232', '27235', '27240', '29861', '29862', '29863', '29914', '29915', '29916')
				THEN 'Hip_Procedures'
			WHEN PVN.ClasfCd IN ('63030', '63035', '63040', '63042', '63043', '63044', '63045', '63046', '63047', '63048', '63265', '63266', '63267', '63268', '63270', '63271', '63272', '63273', '63275', '63276', '63277', '63278', '63280', '63281', '63282', '63283', '63285', '63286', '63287', '63290', '63295', '63300', '63301', '63302', '63303', '63304', '63305', '63306', '63307', '63308')
				THEN 'Spine_Procedures'
			WHEN PVN.ClasfCd IN ('23071', '23073', '23078', '23100', '23101', '23105', '23106', '23107', '23120', '23125', '23130', '23140', '23145', '23146', '23150', '23155', '23156', '23170', '23172', '23174', '23180', '23182', '23184', '23190', '23195', '23200', '23210', '23220', '23330', '23333', '23334', '23335', '23350', '23395', '23397', '23400', '23405', '23406', '23410', '23412', '23430', '23440', '23470', '23472', '23473', '23474', '23500', '23505', '23515', '23530', '23532', '23550', '23552', '23570', '23575', '23585', '23600', '23605', '23615', '23616', '23620', '23625', '23630', '23655', '23660', '23665', '23670', '23675', '23680', '24498', '24500', '24505', '24515', '24516', '24530', '24535', '24538', '24545', '24546', '24560', '24565', '24566', '24575', '24576', '24577', '24579', '24582', '25431', '25440', '29806', '29807', '29819', '29820', '29821', '29822', '29823', '29824', '29825', '29826', '29827', '29828')
				THEN 'Shoulder_Procedures'
			WHEN PVN.ClasfCd IN (
					'24105', '24301', '24305', '24310', '24320', '24330', '24331', '24332', '24340', '24341', '24342', '24343', '24344', '24345', '24346', '24357', '24358', '24359', '24586', '24587', '24600', '24605', '24615', '24620', '24635', '24640', '24650', '24655', '24665', '24666', '24670', '24675', '24685', '25000', '25001', '25020', '25023', '25024', '25025', '25028', '25031', '25109', '25110', '25111', '25112', '25115', '25116', '25260', '25263', '25265', '25270', '25272', '25274', '25275', '25280', '25290', '25295', '25300', '25301', '25310', '25312', '25315', '25316', '25320', '25441', '25442', '25443', '25444', '25445', '25446', '25447', '25449', '25500', '25505', '25515', '25520', '25525', '25526', '25530', '25535', '25545', '25560', '25565', '25574', '25575', '25600', '25605', '25606', '25607', '25608', '25609', '25622', '25624', '25628', '25630', '25635', '25645', '25650', '25651', '25652', '25660', '25670', '25671', '25675', '25676', '25680', '25685', '25690', '25695', '25800', '25805', '25810', '25820', '25825', '25830', '26035', '26037', '26040', '26045', '26055', '26060', '26113', 
					'26116', '26117', '26118', '26121', '26123', '26125', '26160', '26170', '26180', '26350', '26352', '26356', '26357', '26358', '26370', '26372', '26373', '26390', '26392', '26410', '26412', '26415', '26416', '26418', '26420', '26426', '26428', '26432', '26433', '26434', '26437', '26440', '26442', '26445', '26449', '26450', '26455', '26460', '26471', '26474', '26476', '26477', '26478', '26479', '26480', '26483', '26485', '26489', '26490', '26492', '26494', '26496', '26497', '26498', '26499', '26500', '26502', '26508', '26510', '26540', '26541', '26542', '26545', '26600', '26605', '26607', '26608', '26615', '26645', '26650', '26665', '26675', '26676', '26685', '26686', '26705', '26706', '26715', '26720', '26725', '26727', '26735', '26740', '26742', '26746', '26750', '26755', '26756', '26765', '26770', '26775', '26776', '26785', '26820', '26841', '26842', '26843', '26844', '26850', '26852', '26860', '26861', '26862', '26863', '26951', '29835', '29836', '29837', '29838', '29844', '29845', '29846', '29847', '29848', '64702', '64704', '64708', '64712', '64713', '64714', '64716', '64718', 
					'64719', '64721', '64722', '64726', '64727'
					)
				THEN 'Finger_Hand_Wrist_Forearm_and_Elbow_Procedures'
			END AS 'Description'
	) AS CCS
WHERE PAV.Pt_Age >= 18
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) NOT IN ('2', '8')
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Adm_Date >= '2020-01-01'
	AND PAV.Adm_Date < '2021-01-01'
	AND PAV.Plm_Pt_Acct_Type != 'I'
ORDER BY PAV.PtNo_Num
