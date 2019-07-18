SELECT smsmir.mir_cen_hist.episode_no
, smsmir.mir_cen_hist.nurs_sta_from
, case
	when datepart(hour, [xfer_eff_dtime]) < 12
	then 1
	else 0
  end as DischBeforeNoon
, so.ent_dtime
, smsmir.mir_cen_hist.xfer_eff_dtime
, DATEDIFF(hour,so.ent_dtime, smsmir.mir_cen_hist.xfer_eff_dtime) as [interim]
, smsmir.mir_sr_vst_pms.dsch_disp
, so.pty_name
, PRAC.pract_no
, CASE
	WHEN PRAC.src_spclty_cd = 'HOSIM'
	THEN 'Hospitalist'
	ELSE 'Community'
  END AS Hospitalist_Flag

FROM smsmir.mir_cen_hist 
LEFT JOIN (
	select b.episode_no
		, b.ord_no
		, b.ent_dtime
		, b.pty_cd
		, b.pty_name
		, b.svc_cd
	
	from (
		select episode_no
		, ord_no
		, ent_dtime
		, pty_cd
		, pty_name
		, svc_cd
		, ROW_NUMBER() over (
			partition by episode_no order by ord_no desc
			) as rownum

		from smsmir.sr_ord
		where svc_cd = 'adt09'
		and episode_no < '20000000'
	) b
	where b.rownum = 1
) so
ON smsmir.mir_cen_hist.episode_no = so.episode_no
INNER JOIN smsmir.mir_sr_vst_pms 
ON smsmir.mir_cen_hist.episode_no = smsmir.mir_sr_vst_pms.episode_no
LEFT JOIN smsdss.pract_dim_v AS PRAC
ON so.pty_cd = PRAC.src_pract_no
	AND PRAC.orgz_cd = 'S0X0'

WHERE smsmir.mir_cen_hist.nurs_sta_from != 'PSY"'
AND smsmir.mir_cen_hist.xfer_eff_dtime >= '2016-04-01'
And smsmir.mir_cen_hist.xfer_eff_dtime < '2017-01-01'
AND smsmir.mir_cen_hist.cng_type = 'D'
AND so.svc_cd = 'ADT09'
AND PRAC.src_spclty_cd = 'HOSIM'

ORDER BY smsmir.mir_cen_hist.episode_no
, smsmir.mir_cen_hist.nurs_sta_from
, so.ent_dtime
;