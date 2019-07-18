,CASE
	WHEN a.drg_no IN (
	'34','35','36','37','38','39'
	) 
	THEN 'Carotid Endarterectomy'
	WHEN a.drg_no IN (
	'61','62','63','64','65','66'
	) 
	THEN 'CVA'
	WHEN a.drg_no IN (
	'67','68','69'
	) 
	THEN 'TIA'
	WHEN a.drg_no IN (
	'190','191','192'
	) 
	THEN 'COPD'
	WHEN a.drg_no IN (
	'193','194','195'
	) 
	THEN 'Pneumonia'
	WHEN a.drg_no IN (
	'216','217','218'
	) 
	THEN 'Valve Replacement W Cath'
	WHEN a.drg_no IN (
	'219','220','221'
	) 
	THEN 'Valve Replacement W/O Cath'
	WHEN a.drg_no IN (
	'231','232','233'
	) 
		AND (
			NOT(
				Diag01 IN (
				'41412','4150','42292','4230','42490','4275','4295','4296',
				'44322','44329')
				) 
			OR NOT(
				LEFT(Diag01, 3) IN (
							   '420','421','441','444','785','861','996'
									)
					)
			) 
	THEN 'CABG W Cath'
	WHEN a.drg_no IN (
	'235','236'
	) 
		AND (
			NOT(
				Diag01 IN (
				'41412','4150','42292','4230','42490','4275','4295','4296',
				'44322','44329'
						)
				) 
		OR NOT(
			LEFT(Diag01, 3) IN (
			'420','421','441','444','785','861','996'
					)
				)
			) 
	THEN 'CABG W/O Cath'
	WHEN a.drg_no IN (
	'250','251','249','247','248','246'
	) 
		AND Proc01 IN (
		  '0066','3606','3607'
					  ) 
	THEN 'PTCA'
	WHEN a.drg_no IN (
	'280','281','282','283','284','285'
	) 
		AND LEFT(Diag01, 4) IN (
		'4100','4101','4102','4103','4104','4105','4106',
		'4107','4108','4109'
		) 
	THEN 'MI'
	WHEN a.drg_no IN ('291') 
		AND Shock_Ind IS NULL 
	THEN 'Heart Failure'
	WHEN a.drg_no IN ('313') 
		OR (a.drg_no IN ('287') 
			AND Diag01 IN (
				'78650','78651','78652','78659','7850','7851','7859','V717'
							)
			) 
	THEN 'Chest Pain'
	WHEN a.drg_no IN ('377','378','379') 
	THEN 'GI Hemorrhage'
	WHEN a.drg_no IN ('469','470') 
		AND Proc01 IN ('8151','8152','8154') 
		AND (NOT
				(Diag01 IN ('73314','73315','8220','8221')) 
				OR NOT(LEFT
						(Diag01, 3) IN ('820','821')
						)
			) 
	THEN 'Hip & Knee Replacement'
	WHEN a.drg_no IN (
		'739','740','741','742','743'
		) 
		AND LEFT(Proc01, 3) IN (
			'683','684','685','689'
			) 
	THEN 'Hysterectomy'
	WHEN a.drg_no IN ('765','766') 
	THEN 'C-Section'
	WHEN a.drg_no IN ('774','775') 
	THEN 'Vaginal Delivery'
	WHEN a.drg_no IN ('795') 
	THEN 'Normal Newborn'
	WHEN a.drg_no IN ('417','418','419') 
	THEN 'Lap Chole'
	WHEN a.drg_no IN ('945','946') 
	THEN 'Rehab'
	WHEN a.drg_no IN ('312') 
	THEN 'Syncope'
	WHEN a.drg_no IN ('881') 
		OR (a.drg_no IN ('885') 
			AND Diag01 IN (
				'29620','29621','29622','29623','29625','29626','29630',
				'29631','29632','29633','29635','29636'
				)
			) 
	THEN 'Psychoses-Major Depression'
	WHEN a.drg_no IN ('885') 
		AND Diag01 IN (
			'29600','29601','29602','29603','29605','29606','29640','29641',
			'29642','29643','29645','29646','29650','29651','29652','29653',
			'29655','29656','29660','29661','29662','29663','29665','29667',
			'29680','29681','29682','29689','29690','29699'
			) 
	THEN 'Psychoses/Bipolar Affective Disorders'
	WHEN a.drg_no IN ('885') 
		AND (Diag01 IN (
			'29604','29624','29634','29644','29654','29664'
			) 
			OR LEFT(Diag01,3) IN ('295','297','298')
			) 
	THEN 'Psychoses/Schizophrenia'
	WHEN (a.drg_no IN ('286','302','303','311') 
		AND NOT ('Intermed_Coronary_Synd_Ind' Is NULL)
		) 
		OR (a.drg_no IN ('287') 
			AND NOT('Intermed_Coronary_Synd_Ind' IS NULL) 
			AND Diag01 NOT IN (
				'78650','78651','78652','78659','7850','7851','7859','V717')
			) 
	THEN 'Acute Coronary Syndrome'
	WHEN a.drg_no IN (
		'582','583','584','585'
		) 
		AND LEFT(Proc01,3)='854' 
	THEN 'Mastectomy'
	WHEN a.drg_no IN ('896','897') 
		AND Diag01 IN (
			'2910','2911','2912','2913','2914','2915','2918','29181',
			'29189','2919','30300','30301','30302','30303','30390','30391',
			'30392','30393','30500','30501','30502','30503','3030','3039',
			'3050'
			) 
	THEN 'Alcohol Abuse'
	WHEN a.drg_no IN ('619','620','621') 
		AND LEFT(Diag01, 3) IN ('443') 
	THEN 'Gastric By-pass'
	WHEN a.drg_no IN ('602','603') 
		AND LEFT(Diag01,3) IN ('681','682') 
	THEN 'Cellulitis'
	WHEN a.drg_no BETWEEN 1 AND 8 
		OR a.drg_no BETWEEN 10 and 14  
		OR a.drg_no IN (16,17) 
		OR a.drg_no BETWEEN 20 and 42 
	THEN 'Surgical'
	ELSE 'Medical'
END AS 'LIHN_Svc_Line'