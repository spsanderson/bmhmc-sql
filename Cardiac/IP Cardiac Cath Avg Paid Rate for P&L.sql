SELECT COUNT(DISTINcT(b.pt_id)),
SUM(b.tot_pymts_w_pip)


FROM smsdss.c_tot_pymts_w_pip_v b left outer join smsmir.mir_acct a
ON b.pt_id=a.pt_id AND b.unit_seq_no=a.unit_Seq_no




WHERE a.tot_bal_amt = '0'
AND a.tot_chg_amt > '0'
AND b.pt_id IN 

(


SELECT DISTINCT(pt_id)
FROM smsmir.mir_actv
WHERE actv_dtime BETWEEN '01/01/2018' AND '04/30/2018'
AND LEFT(actv_cd,3)='070'
AND pt_id BETWEEN '000010000000' AND '000029999999'

)
