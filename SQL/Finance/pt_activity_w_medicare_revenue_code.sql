SELECT A.pt_id		
, a.actv_cd		
, D.actv_name		
, D.actv_group		
, D.actv_type_desc		
, D.actv_cd_desc		
, D.actv_type_cd_desc		
, a.actv_tot_qty		
, A.CHG_TOT_AMT		
, B.rev_cd		
, C.rev_std_abbr		
, case		
	when b.rev_cd is null	
	and D.actv_group = 'lab'	
		then '300'
	when B.rev_cd is null	
	and d.actv_group = 'pharm'	
		then '250'
	when B.rev_cd is null	
	and d.actv_group = 'rad'	
		then '320'
	when B.rev_cd is null	
	and d.actv_group in ('stats', 'room and board')	
		then '120'
		else B.rev_cd
  end as [rev_code]		
, case		
	when b.rev_cd is null	
	and d.actv_group = 'lab'	
		then 'Lab'
	when B.rev_cd is null	
	and d.actv_group = 'pharm'	
		then 'Pharmacy'
	when B.rev_cd is null	
	and D.actv_group = 'rad'	
		then 'Radiology'
	when B.rev_cd is null	
	and d.actv_group in ('stats', 'room and board')	
		then 'Room/Board'
		else C.rev_std_abbr
  end as [rev_cd_desc]		
--, SUM(A.chg_tot_amt) AS [tot_chgs]		
		
INTO #TEMPA		
		
FROM SMSMIR.ACTV AS A		
LEFT OUTER JOIN SMSMIR.MIR_ACTV_PROC_SEG_XREF AS B		
ON A.actv_cd = B.ACTV_CD		
	AND B.PROC_PYR_IND = 'A'	
LEFT OUTER JOIN SMSDSS.REV_CD_DIM_V AS C		
ON B.REV_CD = C.REV_CD		
LEFT OUTER JOIN smsdss.actv_cd_dim_v AS D		
ON A.actv_cd = D.actv_cd		
		
WHERE a.chg_tot_amt != 0				
		
SELECT DISTINCT A.*
, CLAIM.pay_desc
, CLAIM.pay_entry_date

FROM #TEMPA AS A
LEFT OUTER JOIN smsmir.pay AS CLAIM
ON A.pt_id = CLAIM.pt_id
AND CLAIM.pay_cd = '10501435'

WHERE rev_code = '510'

ORDER BY A.pt_id
, A.rev_cd
;

DROP TABLE #TEMPA;



