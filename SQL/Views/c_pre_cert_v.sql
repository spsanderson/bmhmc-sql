USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_bmh_pre_cert_v]    Script Date: 4/11/2023 2:50:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

ALTER VIEW  [smsdss].[c_bmh_pre_cert_v]  AS 


SELECT a.episode_no,
CONVERT(varchar(13),'0000'+a.episode_no) as pt_id,
(
SELECT bb.user_data_text
FROM smsmir.mir_pms_user_episo as bb
WHERE a.episode_no=bb.episode_no AND a.pt_id_Start_dtime=bb.pt_id_Start_Dtime
AND bb.user_data_cd='2VERDATE'
) as 'Ver_Date_1',
(
SELECT cc.user_data_text
FROM smsmir.mir_pms_user_episo as cc
WHERE a.episode_no=cc.episode_no AND a.pt_id_Start_dtime=cc.pt_id_Start_Dtime
AND cc.user_data_cd='2VREPNAM'
) as 'Ver_Rep_1',
(
SELECT dd.user_data_text
FROM smsmir.mir_pms_user_episo as dd
WHERE a.episode_no=dd.episode_no AND a.pt_id_Start_dtime=dd.pt_id_Start_Dtime
AND dd.user_data_cd='2VERPLAN'
) as 'Ver_Plan_1',
(
SELECT ee.user_data_text
FROM smsmir.mir_pms_user_episo as ee
WHERE a.episode_no=ee.episode_no AND a.pt_id_Start_dtime=ee.pt_id_Start_Dtime
AND ee.user_data_cd='2VRCNTCT'
) as 'Ver_Cntct_1',
(
SELECT ff.user_data_text
FROM smsmir.mir_pms_user_episo as ff
WHERE a.episode_no=ff.episode_no AND a.pt_id_Start_dtime=ff.pt_id_Start_Dtime
AND ff.user_data_cd='2VERPHNE'
) as 'Ver_Phone_1',
(
SELECT gg.user_data_text
FROM smsmir.mir_pms_user_episo as gg
WHERE a.episode_no=gg.episode_no AND a.pt_id_Start_dtime=gg.pt_id_Start_Dtime
AND gg.user_data_cd='2EFCTDTE'
) as 'Ver_Effct_Dte_1',
(
SELECT hh.user_data_text
FROM smsmir.mir_pms_user_episo as hh
WHERE a.episode_no=hh.episode_no AND a.pt_id_Start_dtime=hh.pt_id_Start_Dtime
AND hh.user_data_cd='2VERCOPY'
) as 'Ver_CoPay_1',
(
SELECT ii.user_data_text
FROM smsmir.mir_pms_user_episo as ii
WHERE a.episode_no=ii.episode_no AND a.pt_id_Start_dtime=ii.pt_id_Start_Dtime
AND ii.user_data_cd='2VEROOP'
) as 'Ver_OOP_1',
(
SELECT jj.user_data_text
FROM smsmir.mir_pms_user_episo as jj
WHERE a.episode_no=jj.episode_no AND a.pt_id_Start_dtime=jj.pt_id_Start_Dtime
AND jj.user_data_cd='2PAYPCNT'
) as 'Ver_Prcnt_1',
(
SELECT kk.user_data_text
FROM smsmir.mir_pms_user_episo as kk
WHERE a.episode_no=kk.episode_no AND a.pt_id_Start_dtime=kk.pt_id_Start_Dtime
AND kk.user_data_cd='2AUTHDTE'
) as 'Auth_Date_1',
(
SELECT ll.user_data_text
FROM smsmir.mir_pms_user_episo as ll
WHERE a.episode_no=ll.episode_no AND a.pt_id_Start_dtime=ll.pt_id_Start_Dtime
AND ll.user_data_cd='2AREPNAM'
) as 'Auth_Rep_1',
(
SELECT mm.user_data_text
FROM smsmir.mir_pms_user_episo as mm
WHERE a.episode_no=mm.episode_no AND a.pt_id_Start_dtime=mm.pt_id_Start_Dtime
AND mm.user_data_cd='2AUTPLAN'
) as 'Auth_Plan_1',
(
SELECT nn.user_data_text
FROM smsmir.mir_pms_user_episo as nn
WHERE a.episode_no=nn.episode_no AND a.pt_id_Start_dtime=nn.pt_id_Start_Dtime
AND nn.user_data_cd='2AUCNTCT'
) as 'Auth_Cntct_1',
(
SELECT oo.user_data_text
FROM smsmir.mir_pms_user_episo as oo
WHERE a.episode_no=oo.episode_no AND a.pt_id_Start_dtime=oo.pt_id_Start_Dtime
AND oo.user_data_cd='2AUTPHNE'
) as 'Auth_Phone_1',
(
SELECT pp.user_data_text
FROM smsmir.mir_pms_user_episo as pp
WHERE a.episode_no=pp.episode_no AND a.pt_id_Start_dtime=pp.pt_id_Start_Dtime
AND pp.user_data_cd='2DYSAUTH'
) as 'Auth_Days_1',
(
SELECT qq.user_data_text
FROM smsmir.mir_pms_user_episo as qq
WHERE a.episode_no=qq.episode_no AND a.pt_id_Start_dtime=qq.pt_id_Start_Dtime
AND qq.user_data_cd='2AUTHNUM'
) as 'Auth_No_1',
(
SELECT rr.user_data_text
FROM smsmir.mir_pms_user_episo as rr
WHERE a.episode_no=rr.episode_no AND a.pt_id_Start_dtime=rr.pt_id_Start_Dtime
AND rr.user_data_cd='2CLNFAX'
) as 'Clin_Fax_1',
(
SELECT ss.user_data_text
FROM smsmir.mir_pms_user_episo as ss
WHERE a.episode_no=ss.episode_no AND a.pt_id_Start_dtime=ss.pt_id_Start_Dtime
AND ss.user_data_cd='2CLNPHNE'
) as 'Clin_Phone_1',
(
SELECT aba.user_Data_text
FROM smsmir.mir_pms_user_episo as aba
WHERE a.episode_no=aba.episode_no AND a.pt_id_start_Dtime=aba.pt_id_start_dtime
AND aba.user_data_cd='2CLNNOTE'
) as 'Clin_Note_1',
(
SELECT tt.user_data_text
FROM smsmir.mir_pms_user_episo as tt
WHERE a.episode_no=tt.episode_no AND a.pt_id_Start_dtime=tt.pt_id_Start_Dtime
AND tt.user_data_cd='2PRMNTE1'
) as 'Pre_Cert_Note_1',
(
SELECT uu.user_data_text
FROM smsmir.mir_pms_user_episo as uu
WHERE a.episode_no=uu.episode_no AND a.pt_id_Start_dtime=uu.pt_id_Start_Dtime
AND uu.user_data_cd='2PRMNTE2'
) as 'Pre_Cert_Note_2',
(
SELECT bbb.user_data_text
FROM smsmir.mir_pms_user_episo as bbb
WHERE a.episode_no=bbb.episode_no AND a.pt_id_Start_dtime=bbb.pt_id_Start_Dtime
AND bbb.user_data_cd='2PRMNTE3'
) as 'Pre_Cert_Note_3',
(
SELECT ccc.user_data_text
FROM smsmir.mir_pms_user_episo as ccc
WHERE a.episode_no=ccc.episode_no AND a.pt_id_Start_dtime=ccc.pt_id_Start_Dtime
AND ccc.user_data_cd='2NDVERDT'
) as 'Ver_Date_2',
(
SELECT ddd.user_data_text
FROM smsmir.mir_pms_user_episo as ddd
WHERE a.episode_no=ddd.episode_no AND a.pt_id_Start_dtime=ddd.pt_id_Start_Dtime
AND ddd.user_data_cd='2NDVRNAM'
) as 'Ver_Rep_2',
(
SELECT eee.user_data_text
FROM smsmir.mir_pms_user_episo as eee
WHERE a.episode_no=eee.episode_no AND a.pt_id_Start_dtime=eee.pt_id_Start_Dtime
AND eee.user_data_cd='2NDVRPLN'
) as 'Ver_Plan_2',
(
SELECT vv.user_data_text
FROM smsmir.mir_pms_user_episo as vv
WHERE a.episode_no=vv.episode_no AND a.pt_id_Start_dtime=vv.pt_id_Start_Dtime
AND vv.user_data_cd='2NDVRCNT'
) as 'Ver_Cntct_2',
(
SELECT ww.user_data_text
FROM smsmir.mir_pms_user_episo as ww
WHERE a.episode_no=ww.episode_no AND a.pt_id_Start_dtime=ww.pt_id_Start_Dtime
AND ww.user_data_cd='2NDVRPHN'
) as 'Ver_Phone_2',
(
SELECT fff.user_data_text
FROM smsmir.mir_pms_user_episo as fff
WHERE a.episode_no=fff.episode_no AND a.pt_id_Start_dtime=fff.pt_id_Start_Dtime
AND fff.user_data_cd='2NDEFDTE'
) as 'Ver_Effct_Dte_2',
(
SELECT ggg.user_data_text
FROM smsmir.mir_pms_user_episo as ggg
WHERE a.episode_no=ggg.episode_no AND a.pt_id_Start_dtime=ggg.pt_id_Start_Dtime
AND ggg.user_data_cd='2NDVRCPY'
) as 'Ver_CoPay_2',
(
SELECT hhh.user_data_text
FROM smsmir.mir_pms_user_episo as hhh
WHERE a.episode_no=hhh.episode_no AND a.pt_id_Start_dtime=hhh.pt_id_Start_Dtime
AND hhh.user_data_cd='2NDVROOP'
) as 'Ver_OOP_2',
(
SELECT iii.user_data_text
FROM smsmir.mir_pms_user_episo as iii
WHERE a.episode_no=iii.episode_no AND a.pt_id_Start_dtime=iii.pt_id_Start_Dtime
AND iii.user_data_cd='2NDPYPCT'
) as 'Ver_Prcnt_2',
(
SELECT jjj.user_data_text
FROM smsmir.mir_pms_user_episo as jjj
WHERE a.episode_no=jjj.episode_no AND a.pt_id_Start_dtime=jjj.pt_id_Start_Dtime
AND jjj.user_data_cd='2NDAUTDT'
) as 'Auth_Date_2',
(
SELECT kkk.user_data_text
FROM smsmir.mir_pms_user_episo as kkk
WHERE a.episode_no=kkk.episode_no AND a.pt_id_Start_dtime=kkk.pt_id_Start_Dtime
AND kkk.user_data_cd='2NDAURPN'
) as 'Auth_Rep_2',
(
SELECT lll.user_data_text
FROM smsmir.mir_pms_user_episo as lll
WHERE a.episode_no=lll.episode_no AND a.pt_id_Start_dtime=lll.pt_id_Start_Dtime
AND lll.user_data_cd='2NDAUPLN'
) as 'Auth_Plan_2',
(
SELECT mmm.user_data_text
FROM smsmir.mir_pms_user_episo as mmm
WHERE a.episode_no=mmm.episode_no AND a.pt_id_Start_dtime=mmm.pt_id_Start_Dtime
AND mmm.user_data_cd='2NDAUCNT'
) as 'Auth_Cntct_2',
(
SELECT nnn.user_data_text
FROM smsmir.mir_pms_user_episo as nnn
WHERE a.episode_no=nnn.episode_no AND a.pt_id_Start_dtime=nnn.pt_id_Start_Dtime
AND nnn.user_data_cd='2NDAUTPH'
) as 'Auth_Phone_2',
(
SELECT ooo.user_data_text
FROM smsmir.mir_pms_user_episo as ooo
WHERE a.episode_no=ooo.episode_no AND a.pt_id_Start_dtime=ooo.pt_id_Start_Dtime
AND ooo.user_data_cd='2NDAUDAY'
) as 'Auth_Days_2',
(
SELECT ppp.user_data_text
FROM smsmir.mir_pms_user_episo as ppp
WHERE a.episode_no=ppp.episode_no AND a.pt_id_Start_dtime=ppp.pt_id_Start_Dtime
AND ppp.user_data_cd='2NDAUNUM'
) as 'Auth_No_2',
(
SELECT qqq.user_data_text
FROM smsmir.mir_pms_user_episo as qqq
WHERE a.episode_no=qqq.episode_no AND a.pt_id_Start_dtime=qqq.pt_id_Start_Dtime
AND qqq.user_data_cd='2NDCLFAX'
) as 'Clin_Fax_2',
(
SELECT rrr.user_data_text
FROM smsmir.mir_pms_user_episo as rrr
WHERE a.episode_no=rrr.episode_no AND a.pt_id_Start_dtime=rrr.pt_id_Start_Dtime
AND rrr.user_data_cd='2NDCLPHN'
) as 'Clin_Phone_2',
(
SELECT aca.user_data_text
FROM smsmir.mir_pms_user_episo as aca
WHERE a.episode_no=aca.episode_no AND a.pt_id_Start_Dtime=aca.pt_id_start_dtime
AND aca.user_data_cd='2NDCLNTE'
) as 'Clin_Note_2',
(
SELECT sss.user_data_text
FROM smsmir.mir_pms_user_episo as sss
WHERE a.episode_no=sss.episode_no AND a.pt_id_Start_dtime=sss.pt_id_Start_Dtime
AND sss.user_data_cd='2NDYNTE1'
) as '2ndry_Note_1',
(
SELECT ttt.user_data_text
FROM smsmir.mir_pms_user_episo as ttt
WHERE a.episode_no=ttt.episode_no AND a.pt_id_Start_dtime=ttt.pt_id_Start_Dtime
AND ttt.user_data_cd='2NDYNTE2'
) as '2ndry_Note_2',
(
SELECT uuu.user_data_text
FROM smsmir.mir_pms_user_episo as uuu
WHERE a.episode_no=uuu.episode_no AND a.pt_id_Start_dtime=uuu.pt_id_Start_Dtime
AND uuu.user_data_cd='2NDYNTE3'
) as '2ndry_Note_3',
(
SELECT vvv.user_data_text
FROM smsmir.mir_pms_user_episo as vvv
WHERE a.episode_no=vvv.episode_no AND a.pt_id_Start_dtime=vvv.pt_id_Start_Dtime
AND vvv.user_data_cd='2PRCRNT1'
) as 'Addl_Note_1',
(
SELECT www.user_data_text
FROM smsmir.mir_pms_user_episo as www
WHERE a.episode_no=www.episode_no AND a.pt_id_Start_dtime=www.pt_id_Start_Dtime
AND www.user_data_cd='2PRCRNT2'
) as 'Addl_Note_2',
(
SELECT xxx.user_data_text
FROM smsmir.mir_pms_user_episo as xxx
WHERE a.episode_no=xxx.episode_no AND a.pt_id_Start_dtime=xxx.pt_id_Start_Dtime
AND xxx.user_data_cd='2PRCRNT3'
) as 'Addl_Note_3',
(
SELECT yyy.user_data_text
FROM smsmir.mir_pms_user_episo as yyy
WHERE a.episode_no=yyy.episode_no AND a.pt_id_Start_dtime=yyy.pt_id_Start_Dtime
AND yyy.user_data_cd='2PRCRNT4'
) as 'Addl_Note_4',
(
SELECT zzz.user_data_text
FROM smsmir.mir_pms_user_episo as zzz
WHERE a.episode_no=zzz.episode_no AND a.pt_id_Start_dtime=zzz.pt_id_Start_Dtime
AND zzz.user_data_cd='2PRCRNT5'
) as 'Addl_Note_5'

FROM smsmir.mir_pms_user_episo as a
WHERE a.user_data_cd='2VERDATE'



GO


