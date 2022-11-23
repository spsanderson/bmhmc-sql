DECLARE @START DATE;
DECLARE @END DATE;

SET @START = '2022-01-01';
SET @END = GETDATE();

DROP TABLE IF EXISTS #SICU_BED;
DROP TABLE IF EXISTS #FIRST_NONICU_BED;
DROP TABLE IF EXISTS #ADT10_ORD;

WITH SICU_BED AS (
	SELECT CenHist.episode_no,
		CenHist.nurs_sta_from,
		CenHist.nurs_sta,
		CenHist.hosp_svc,
		CenHist.xfer_eff_dtime,
		CenHist.last_data_cngdtime,
		CenHist.bed,
		CenHist.cng_type,
		[rn] = ROW_NUMBER() OVER (
        	PARTITION BY CENHIST.EPISODE_NO ORDER BY CENHIST.XFER_EFF_DTIME ASC
        	)
	FROM smsmir.mir_cen_hist AS CenHist
	WHERE Cenhist.src_sys_id = '#PMSNTX0'
	AND CenHist.nurs_sta = 'SICU'
	AND CenHist.nurs_sta_from != 'SICU'
	AND xfer_eff_dtime >= @START
	AND xfer_eff_dtime < @END
	AND CenHist.cng_type IN ('A','S','T')
)

SELECT *
INTO #SICU_BED
FROM SICU_BED;

-- Get ADT10 Orders 'Transfer To' should it exist
-- Need the order that indicates the transfer out of the sicu
SELECT ORD.episode_no,
	ORD.svc_desc,
	ORD.svc_cd,
	ORD.desc_as_written,
	ORD.ent_dtime,
	ORD.pty_cd,
	ORD.pty_name,
	ORD.signon_id,
	ORD.ord_src_modf,
	ORD.ord_src_mne,
	[rn] = ROW_NUMBER() OVER(
		PARTITION BY ORD.episode_no,
			ORD.svc_desc,
			ORD.svc_cd,
			ORD.desc_as_written,
			ORD.ent_dtime,
			ORD.pty_cd,
			ORD.pty_name,
			ORD.signon_id,
			ORD.ord_src_modf,
			ORD.ord_src_mne
		ORDER BY ORD.ent_dtime DESC
	)
INTO #ADT10_ORD
FROM smsmir.sr_ord AS ORD
LEFT JOIN #SICU_BED AS SICU ON ORD.episode_no = SICU.episode_no
	--AND ORD.ent_dtime > SICU.xfer_eff_dtime
WHERE svc_cd = 'ADT10';

DELETE
FROM #ADT10_ORD
WHERE RN != 1;

-- GET FIRST NON ICU BED AFTER SICU
WITH FIRST_NONICU AS (
	SELECT A.episode_no,
		A.nurs_sta_from,
		A.nurs_sta,
		A.hosp_svc,
		A.xfer_eff_dtime,
		A.last_data_cngdtime,
		A.bed,
		A.cng_type,
		[rn] = ROW_NUMBER() OVER (
        	PARTITION BY A.EPISODE_NO ORDER BY A.XFER_EFF_DTIME ASC
        	)
	FROM smsmir.mir_cen_hist AS A
	INNER JOIN #SICU_BED AS Z ON A.episode_no = Z.episode_no
		AND A.xfer_eff_dtime > Z.xfer_eff_dtime
	WHERE (
		(
			A.nurs_sta != 'SICU'
			AND A.nurs_sta_from = 'SICU'
		)
		OR (
			A.nurs_sta_from = 'SICU'
			AND (
				A.nurs_sta != 'SICU'
				OR A.nurs_sta IS NULL
			)
			AND A.cng_type = 'D'
		)
	)
	AND A.src_sys_id = '#PMSNTX0'
)

SELECT *
INTO #FIRST_NONICU_BED
FROM FIRST_NONICU
WHERE RN = 1;

SELECT A.episode_no,
	A.nurs_sta_from AS [nurs_sta_pre_sicu],
	--A.nurs_sta,
	A.bed AS [sicu_bed],
	A.xfer_eff_dtime AS [sicu_bed_time],
	C.ent_dtime AS [xfer_order_entry_dtime],
	C.ord_src_modf,
	C.ord_src_mne,
	C.svc_desc,
	C.desc_as_written,
	B.cng_type AS [post_sicu_change_type],
	B.nurs_sta AS [post_sicu_nurs_sta],
	B.bed AS [post_sicu_bed],
	B.xfer_eff_dtime AS [post_sicu_bed_time],
	PAV.vst_end_dtime,
	[mortality_flag] = CASE
		WHEN LEFT(PAV.DSCH_DISP, 1) IN ('C','D')
			THEN 'Y'
		ELSE 'N'
		END
FROM #SICU_BED AS A
LEFT JOIN #FIRST_NONICU_BED AS B ON A.episode_no = B.episode_no
	AND A.xfer_eff_dtime < B.xfer_eff_dtime
LEFT JOIN #ADT10_ORD AS C ON A.episode_no = c.episode_no
	AND C.ent_dtime = (
		SELECT TOP 1 ZZZ.ent_dtime
		FROM #ADT10_ORD AS ZZZ
		WHERE ZZZ.episode_no = A.episode_no
			AND ZZZ.ent_dtime > A.xfer_eff_dtime
	)
LEFT JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV ON A.episode_no = PAV.PtNo_Num
--WHERE A.episode_no = '';

--select * from #SICU_BED where episode_no = '';

--select * from #ADT10_ORD where episode_no = '';

--select * from #FIRST_NONICU_BED where episode_no = '';

--SELECT A.*,
--	ORD.*,
--	B.xfer_eff_dtime
--FROM #SICU_BED AS A
--LEFT JOIN #FIRST_NONICU_BED AS B ON A.episode_no = B.episode_no
--	AND A.xfer_eff_dtime < B.xfer_eff_dtime
--LEFT JOIN #ADT10_ORD AS ORD ON A.episode_no = ORD.episode_no
--	AND ORD.ent_dtime = (
--		SELECT TOP 1 ZZZ.ent_dtime
--		FROM #ADT10_ORD AS ZZZ
--		WHERE ZZZ.episode_no = A.episode_no
--			AND ZZZ.ent_dtime > A.xfer_eff_dtime
--	)
--	--AND ORD.ent_dtime > A.xfer_eff_dtime
--	--AND ORD.ent_dtime < B.xfer_eff_dtime
--WHERE A.episode_no = ''