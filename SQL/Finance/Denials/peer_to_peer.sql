select [Encounter] = CAST(
	rtrim(
		ltrim('0000' + CAST(a.bill_no AS char(13)))
		) AS CHAR(13)
	) COLLATE SQL_LATIN1_GENERAL_PREF_CP1_CI_AS   
, A.last_name
, A.first_name
, A.length_of_stay
, C.ins_payor_search
, [PeerToPeerRequested] = (select 
	MAX(
		case when f.s_peer_to_peer is not null 
		then f.s_peer_to_peer 
		else ''
	end)
	)
, [DateP2PRequested] = (select
	MAX(
		case when f.dat IS not null
		then f.dat
		else ''
	end)
	)
, [Peer_to_Peer_Outcome] = (select
	MAX(
		case when f.s_peer_outcome IS not null
		then f.s_peer_outcome
		else ''
	end)
	)
, [Date_P2P_Comp] = (select
	max(
		case when f.s_date_peer_completed is not null
		then f.s_date_peer_completed
		else f.s_date_peer_completed
	end)
	)
, [Reconsideration] = (select 
	max(
		case when f.s_reconsideration is not null 
		then f.s_reconsideration 
		else '' 
	end)
	)
, [Reconsideration_Outcome] = (select 
	max(
		case when f.s_reconsideration_outcome is not null 
		then f.s_reconsideration_outcome 
		else ''  
	end)
	)
, [MD_Responded] = (select
	max(
		case when f.s_physician_responded is not null
		then f.s_physician_responded
		else ''
	end)
	)
, [PhysicianNotified] = (select 
	MAX(
		case when f.s_physician_notified is not null 
		then s_physician_notified 
		else '' 
	end)
	)
, g.Name
--, f.*

FROM [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.visit_view               AS a 
LEFT JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_VISIT           AS b
ON a.visit_id=b._fk_visit
LEFT JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_INSURANCE       AS c
ON a.visit_id=c._fk_visit
LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[CTC_UM_Denial] AS d
ON c._pk=d._fk_insurance 
LEFT OUTER JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_UM_APPEAL AS e
ON d._pk=e._fk_UM_Denial
LEFT OUTER JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[CTC_um_approval] AS f
ON C._pk = f._fk_insurance
LEFT OUTER JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.pdb_master AS g
ON f.s_physician_notified = g._PK

WHERE A.admission_date >= '2017-01-01'
--and A.bill_no = ''
and g._pk is not null

group by A.bill_no
, A.last_name
, A.first_name
, A.length_of_stay
, C.ins_payor_search
, g.Name