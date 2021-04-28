SELECT ha.AssessmentID,
	ha.CollectedDT,
	ho.Patient_oid,
	ha.PatientVisit_oid,
	b.episode_no,
	b.vst_start_dtime,
	b.vst_end_dtime,
	b.nurs_sta_loc,
	ho.Value,
	ho.FindingAbbr,
	ZZZ.nurs_sta,
	ZZZ.xfer_eff_dtime,
	ZZZ.nurs_sta_from,
	ZZZ.cng_type
-- cv.VisitOID,  
-- cv.LocationName  
FROM [smsmir].[sc_Observation] ho WITH (NOLOCK)
INNER JOIN [smsmir].[sc_Assessment] ha WITH (NOLOCK) ON ho.AssessmentID = ha.assessmentid
LEFT OUTER JOIN [smsmir].[mir_sr_vst_pms] b ON ha.PatientVisit_oid = b.vst_no
--INNER join @CensusVisitOIDs cv  
-- ON ha.PatientVisit_OID = cv.VisitOID
-- AND ha.Patient_OID = cv.PatientOID			-- Performance Improvement  
-- last unit pt was on before assessment collection date time
LEFT JOIN SMSMIR.mir_cen_hist AS ZZZ ON B.episode_no = ZZZ.episode_no
	AND ZZZ.xfer_eff_dtime <= HA.CollectedDT
	AND ZZZ.seq_no = (
		SELECT TOP 1 BBB.SEQ_NO
		FROM SMSMIR.mir_cen_hist AS BBB
		WHERE ZZZ.episode_no = BBB.episode_no
			AND BBB.xfer_eff_dtime <= HA.CollectedDT
			AND BBB.nurs_sta IS NOT NULL
		ORDER BY BBB.seq_no DESC
		)
WHERE ho.FindingAbbr IN ('A_IV1 Type', 'A_IV2 Type', 'A_IV3 Type', 'A_IV4 Type')
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND CollectedDT BETWEEN '2021-01-01'
		AND '2021-04-14'
	AND CollectedDT < b.vst_end_dtime - 1
	AND ho.Value IN ('Central Line', 'IVAD', 'PICC Line', 'Hemodialysis Catheter')
--and ho.Value like '%hemo%'   --- @dtStartDate and @dtEndDate  
ORDER BY ha.PatientVisit_oid,
	CollectedDT DESC
