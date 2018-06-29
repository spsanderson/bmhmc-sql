SELECT A.episode_no
, A.ord_no
, A.ent_dtime
, A.svc_cd
, A.desc_as_written
, A.ord_loc
, A.ord_sts
, B.ord_sts_modf

FROM smsmir.sr_ord AS A
LEFT OUTER JOIN smsmir.ord_sts_modf_mstr AS B
ON A.ord_sts = B.ord_sts_modf_cd

WHERE A.ord_sts IN ( -- 10 will most likely be the only sts returned as it is a PCO order
	'10', -- Active
    '14', -- Pending Specimen Collection
    '39', -- Validated
    '41'  -- Active-Per Protocol
)

AND svc_cd in (
	'PCO_SafetyWatch',
	'PCO_ConstantoBS'
)

ORDER BY A.episode_no, A.svc_cd

GO
;