WITH cte
AS (
	SELECT ins.pt_id,
		ins.ins_plan_no,
		ins.ins_plan_prio_no,
		msg_hdr.appl_from,
		msg_hdr.msg_type,
		ins.last_msg_cntrl_id,
		msg_hdr.msg_cntrl_id,
		msg_hdr.msg_dtime,
		[rn] = ROW_NUMBER() OVER (
			PARTITION BY ins.pt_id,
			ins.ins_plan_no ORDER BY ins.pt_id,
				ins.ins_plan_no,
				ins.ins_plan_prio_no
			)
	FROM smsmir.hl7_ins AS ins
	LEFT OUTER JOIN smsmir.hl7_msg_hdr AS msg_hdr ON ins.pt_id = msg_hdr.pt_id
		AND ins.last_msg_cntrl_id = msg_hdr.msg_cntrl_id
	LEFT OUTER JOIN smsmir.hl7_vst AS vst ON ins.pt_id = vst.pt_id
	--where ins.pt_id = '87463964'
	WHERE vst.adm_date >= '2017-05-01'
		AND vst.adm_date < '2017-11-01'
	)
--order by ins.pt_id, ins.ins_plan_no, ins.ins_plan_prio_no
SELECT cte1.pt_id
--, cte1.ins_plan_no
--, cte1.ins_plan_prio_no
--, cte1.rn
--, cte2.ins_plan_no
--, cte2.ins_plan_prio_no
--, cte2.rn
INTO #tempa
FROM cte AS cte1
INNER JOIN cte AS cte2 ON cte1.pt_id = cte2.pt_id
	AND cte1.rn != cte2.rn
	AND cte1.ins_plan_prio_no = cte2.ins_plan_prio_no
	AND cte1.ins_plan_no != cte2.ins_plan_no
	AND cte2.pt_id IS NOT NULL
	AND DATEDIFF(hour, cte1.msg_dtime, cte2.msg_dtime) >= 24
ORDER BY cte1.pt_id,
	cte1.ins_plan_no,
	cte1.ins_plan_prio_no;

SELECT DISTINCT (a.pt_id),
	b.UserDataText
FROM #tempa AS a
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V AS b ON a.pt_id = b.PtNo_Num
INNER JOIN smsdss.BMH_UserTwoField_Dim_V AS c ON b.UserDataKey = c.UserTwoKey
	AND c.UserDataCd IN ('2INADMBY', '2ERFRGBY', '2ERREGBY', '2OPPREBY', '2OPREGBY');

DROP TABLE #tempa;
