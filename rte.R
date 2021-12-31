
The purpose of this report is to first explore the average length of stay (ALOS) for patients discharged from the hospital. Once we have the data we will then, more specifically, want to see if there is a difference in the ALOS of patients seen by a Hospitalist or a Physician of the Community. Some patients will be excluded from this report, specifically psychiatric patients and those under the age of 18 as this facility does not keep a pediatric service line. Those with an age that is greater than or equal to 90 are also going to be excluded due to typically having multiple chronically acute conditions that cause longer lengths of stay from the average patient.

Importing and Viewing the Data
In this section we will pull in the Length Of Stay data and get a general feel for how the data is dispersed. During this part we will also exclude those patients with a \textbf{\texttt{PSY}} service and those under the age of 18 and 90 years of age or older.

Importing the Data
Here we are gong to graphically examine the differences in Average Length of Stay (ALOS) between Hospital Employed Physicians and the Physicians of the community. Before we do this, we will need to obtain data. The data is obtained from the hospitals data warehouse via SQL Server 2008 R2. This data ranges from '2013-10-01' through '2015-10-01'.
<<load los data>>=
  los <- read.csv("alos.csv", header=TRUE)
str(los, list.len = 5, ncharmax = 5, strict.width = "cut", 
    width = 60)

@
  
Variables
Here is a complete list of all of the variables that are inside of the \textbf{\texttt{los data.frame}}
<<los data variables>>=
  los[0,]

@

Summary of Hospital Service, Patient Age and Length of Stay
Now lets get an idea of how many patients we will be excluding due to their age and service line.
<<summary hosp_svc>>=
  summary(los$hosp_svc)

@
  
  <<sumary Patient Age>>=
  summary(los$Pt_Age)

@
  
  <<summary Days.Stay>>=
  summary(los$Days.Stay)
@
  
Preliminary data visualization
First we will want to set some basic parameters for the following graphs in order to reduce some code. We will set the bin widths for each graph. We set the bin-width equal to the following:
  \begin{center}
$bin = \frac{Max(x) - Min(x)} {25}$
  \end{center}
<<LOS Age and Days Stay binsize>>=
  library("ggplot2")
losAgebinsize = diff(range(los$Pt_Age)/25)
losDaysStaybinsize = diff(range(los$Days.Stay)/25)
blankPanel = theme(panel.grid.major = element_blank(),
                   panel.grid.minor = element_blank())
@
  
  Now we can make the graphs.
<<histogram_ptAge, fig.align='center', fig.height=4, fig.width=5>>=
  ggplot(los, aes(x = Pt_Age)) + 
  geom_histogram(binwidth = losAgebinsize, fill = "light blue", 
                 alpha = 0.315, colour = 'black') +
  blankPanel +
  xlab("Patient Age in Years") +
  ggtitle("Histogram of Patient Age")

@
  From the histogram above we can see that not too many patients fall in the age buckets that we want to exclude, so we need not worry about poor approximations of the true distribution of the length of stay once we trim out those patients.


<<histogram_los, fig.align='center', fig.height=4, fig.width=5>>=
  ggplot(los, aes(x = Days.Stay)) +
  geom_histogram(binwidth = losDaysStaybinsize, 
                 fill = "light blue",
                 alpha = 0.315, colour = 'black') +
  blankPanel +
  xlab("Length of Stay") +
  ggtitle("Histogram of Length of Stay")
@
  From the resulting histogram we can see that the length of stay data is highly skewed due to some heavy outliers. First we are going to trim out the patients to keep only those in the age range we desire, $18 \geq Age \geq 90$ then we will again take a look at the length of stay distribution to see if it changes at all.

Exclusions
We can now create a new \textbf{\texttt{data.frame}} that only includes patients that fall into the age ranges we want. After we do this, we will again look at a couple of histograms to get a view of the variation in the data. We are also going to take out \textbf{texttt{EME, HSP & OBV}}
<<data frame with desired patients>>=
  losNew <- los[los$hosp_svc != "PSY",]
losNew <- losNew[losNew$hosp_svc != "EME",]
losNew <- losNew[losNew$hosp_svc != "HSP",]
losNew <- losNew[losNew$hosp_svc != "OBV",]
losNew <- losNew[losNew$Pt_Age >= 18,]
losNew <- losNew[losNew$Pt_Age < 90,]

@
  
Visualizing Data after exclusions
Now that we have our new \textbf{\texttt{data.frame}}, it is always important to first take a look at the data and try to get a visual hold on it. We will look at histograms of patient age and length of stay.

Visualize Age and Length of Stay
We will again, as in the previous section create some variables that will help reduce some code that is shown in this report. We are going to create out bin-widths using the same formula from above:
  \begin{center}
$bin = \frac{Max(x) - Min(x)} {25}$
  \end{center}
<<New LOS and Age binsize>>=
  losNewAgebinsize = diff(range(losNew$Pt_Age)/25)
losNewDaysStaybinsize = diff(range(losNew$Days.Stay)/25)

@
  
  Now we can create our new graphs and take a look at their corresponding distributions.
<<losNew Hist Age, fig.width=5, fig.height=4, fig.align='center'>>=
  ggplot(losNew, aes(x = Pt_Age)) + 
  geom_histogram(binwidth = losNewAgebinsize, 
                 fill = "light blue", 
                 alpha = 0.315, colour = 'black') +
  blankPanel +
  xlab("Patient Age in Years") +
  ggtitle("Histogram of Patient Age")

@
  From the above we can see that the vast majority of the patients that remain fall in the range of \Sexpr{summary(losNew$Pt_Age)[2]} to \Sexpr{summary(losNew$Pt_Age)[5]}, a range of \Sexpr{IQR(losNew$Pt_Age)} years.

<<losNew Hist Length of Stay, fig.width=5, fig.height=4, fig.align='center'>>=
  ggplot(losNew, aes(x = Days.Stay)) +
  geom_histogram(binwidth = losNewDaysStaybinsize, 
                 fill = "light blue",
                 alpha = 0.315, colour = 'black') +
  blankPanel +
  xlab("Length of Stay") + 
  ggtitle("Histogram of Length of Stay")

@
  From the above we can see that trimming the age of the patients did not change the distribution in any meaningful manner. In the section we will discuss getting rid of these length of stay outliers.

Outliers
From the histogram of length of stay we see that we have substantial outliers in the data that should be taken out since they can skew our results. First we will want a summary of the \textbf{\texttt{Days.Stay}} variable so we can try and make a determination of where the cutoff should be. Typically data beyond three standard deviations of the mean can be excluded. We are also going to want to exclude those patients that were only here for one day since they can artificially deflate the true length of stay.
<<los summary Days.Stay>>=
  losNew <- losNew[losNew$Days.Stay > 1,]
summary(losNew$Days.Stay)

@
  
  The Standard Deviation of Days Stay is: 
  \Sexpr{round(sd(losNew$Days.Stay), 2)}.
Therefore the typical cutoff would be: 
  \Sexpr{round(3 * sd(losNew$Days.Stay), 2)} days which we will round up to 
\Sexpr{round(3 * sd(losNew$Days.Stay),0)}. With this new information, we will again appropriately trim the data set, remembering that the cutoff will be:
  \begin{center} 
$LOS = 3 * sd(Days.Stay)$
  \end{center}

<<losNew excluding LOS outliers>>=
  losNew <- losNew[losNew$Days.Stay <= round(
    3 * sd(losNew$Days.Stay),0),]

@
  
Visualization of trimmed data set
With the new \textbf{\texttt{data.frame}} created we can now get a summary and view of the variation of the \textbf{\texttt{Days.Stay}} variable.
<<summary length of stay trimmed>>=
  summary(losNew$Days.Stay)
IQR(losNew$Days.Stay)
@
  
  <<histogram length of stay excluding 1 days and outliers, fig.width=5, fig.height=4, fig.align='center'>>=
  newLOSbinsize <- diff(range(losNew$Days.Stay)/25)
ggplot(losNew, aes(x = Days.Stay)) +
  geom_histogram(binwidth = newLOSbinsize, fill = "light blue",
                 alpha = 0.315, colour = 'black') +
  blankPanel +
  xlab("Length of Stay") +
  ggtitle("Histogram of LOS")

@
  From the above histogram we can see that the distribution has a very high positive skew and is not normal, it is most likely an geometric distribution since we treat length of stay as discrete. We do not need to test for normality as it is visually apparent the data is not normal.

Statistical Difference?
Now that we have our \textbf{\texttt{data.frame}} set with the data we want, the next logical progression would be to ask if there is a statistical difference in the lenght of stay for patients under the care of a hospitalist or a community physician.

Viewing Hospital Employed and Community Physican data together
Now lets see if there are any stark differences in the distribution of length of stay for Hospitalist v. non-hospitalist patients. We will first need to set \textbf{\texttt{Hospitalist.Flag}} to a type of \textbf{\texttt{factor}}. To do this we will add a column to the \textbh{\textttt{data.frame}} to hold this information so that we do not lose the numeric column as we may want to use it later on for some analysis.
<<hospitalist flag, fig.align='center', fig.height=4, fig.width=6>>=
  losNew$HospFlagFactor <- as.factor(losNew$Hospitalist.Flag)

ggplot(losNew, aes(x = Days.Stay, fill = HospFlagFactor)) + 
  geom_histogram(binwidth = newLOSbinsize,
                 position = "identity", alpha = 0.315) +
  blankPanel +
  xlab("Length of Stay") +
  ggtitle("Histogram of LOS: Hospitalist v. Community")

@
  
  At immediate glance it seems that there is really not much difference in the length of stay data for hospitalist and community physicians. So lets see what the mean of length of stay is for each.
<<mean los by hospflagfactor>>=
  aggregate(Days.Stay ~ HospFlagFactor, data = losNew, FUN = mean)

@
  
  So we can see from here that the mean length of stay for Hospitalists is lower than that of the community physicians, but is this significant? This data does not follow a normal distribution, therefore we will use a non-parametric test, the \textbf{\texttt{wilcox.test}}. Before we do this we will need to make a vector of the length of stay for both hospitalists and non-hospitalists.
<<wilcox.test vector creation>>=
  hosp_los <- losNew$Days.Stay[losNew$HospFlagFactor == "1"]
comm_los <- losNew$Days.Stay[losNew$HospFlagFactor == "0"]

@
  
  Now that we have the vectors created we can go ahead and start the \textbf{\texttt{wilcox.test}}. We will be specifically testing to see if the mean length of stay for each group is equal to each other. We will be testing this at the $\alpha = 0.05$ level.
<<wilcox.test>>=
  wilcox.test(comm_los, hosp_los, paired = FALSE, 
              conf.level = 0.95, alternative = "greater",
              exact = FALSE)

wilcox.test(hosp_los, comm_los, paired = FALSE,
            conf.level = 0.95, alternative = "greater",
            exact = FALSE)
@
  
  The above test shows that the means of each group are not equal. The first set of results confirms that the mean length of stay is greater for patients seen by a community physician with a p-value far below 0.05 and the second test again confirms that the patients seen by a hospitalist have a lower mean length of stay by giving a p-value of 1 when asking if the mean of the length of stay for hospitalists is greater than community physicians.

SQL Code used to fetch data


SET ANSI_NULLS OFF 
GO 

-- Variable declaration 
DECLARE @IP_START_DATE DATE; 
DECLARE @IP_END_DATE DATE; 

SET @IP_START_DATE = '2013-10-01'; 
SET @IP_END_DATE = '2015-10-01'; 

DECLARE @INIT_POP TABLE ( 
  ID INT IDENTITY(1, 1) PRIMARY KEY 
  , [Vist ID]           VARCHAR(MAX) 
  , Pt_Sex              VARCHAR(MAX) 
  , Pt_Race             VARCHAR(MAX) 
  , dsch_disp           VARCHAR(MAX) 
  , hosp_svc            VARCHAR(MAX) 
  , Pt_Age              INT 
  , Pt_Zip_Cd           VARCHAR(MAX) 
  , drg_no              VARCHAR(MAX) 
  , drg_cost_weight     FLOAT 
  , [Adm Date Time]     DATETIME 
  , [Dsch Date Time]    DATETIME 
  , [Days Stay]         VARCHAR(MAX) 
  , [Readmitted in 30?] VARCHAR(MAX) 
  , [Discharge Month]   VARCHAR(MAX) 
  , [Discharge Year]    VARCHAR(MAX) 
  , [Discharge YYYY-M]  VARCHAR(MAX) 
  , [Hospitalist Flag]  VARCHAR(MAX) 
);

WITH CTE1 AS ( 
  SELECT 
  A.PtNo_Num  
  , A.Pt_Sex 
  , A.Pt_Race 
  , A.dsch_disp 
  , A.hosp_svc 
  , A.Pt_Age 
  , A.Pt_Zip_Cd 
  , A.drg_no 
  , A.drg_cost_weight 
  , A.vst_start_dtime               AS [Adm Date Time] 
  , A.vst_end_dtime                 AS [Dsch Date Time] 
  , CONVERT(INT, A.Days_Stay)       AS [Days Stay] 
  , CASE 
  WHEN B.[READMIT] IS NULL 
  THEN 0 
  ELSE 1 
  END AS [Readmitted in 30?] 
  , DATEPART(MONTH, A.DSCH_DATE)    AS [Discharge Month] 
  , DATEPART(YEAR, A.Dsch_Date)     AS [Discharge Year] 
  , ( 
    CAST(DATEPART(YEAR, A.DSCh_DATE)  AS VARCHAR(MAX)) + '-' + 
      CAST(DATEPART(MONTH, A.DSCH_DATE) AS VARCHAR(MAX)) 
  ) AS [Discharge YYYY-M] 
  , CASE 
  WHEN C.src_spclty_cd = 'HOSIM' 
  THEN 1 
  ELSE 0 
  END AS [Hospitalist Flag] 
  
  FROM smsdss.BMH_PLM_PtAcct_V     A 
  LEFT JOIN smsdss.vReadmits   B 
  ON A.PtNo_Num = B.[INDEX] 
  AND B.INTERIM <= 30 -- This ensures that we only get 
  -- the accounts that are 30 Day 
  -- RA's 
  LEFT JOIN smsdss.pract_dim_v C 
  ON A.Atn_Dr_No = C.src_pract_no 
  
  WHERE Dsch_Date >= @IP_START_DATE 
  AND Dsch_Date < @IP_END_DATE 
  AND Plm_Pt_Acct_Type = 'I' 
  AND PtNo_Num < '20000000' 
  AND Days_Stay > 1 
  AND C.orgz_cd = 'S0X0' 
) 
  
  INSERT INTO @INIT_POP 
  SELECT 
  C1.PtNo_Num 
  , C1.Pt_Sex 
  , C1.Pt_Race 
  , C1.dsch_disp 
  , C1.hosp_svc 
  , C1.Pt_Age 
  , C1.Pt_Zip_Cd 
  , C1.drg_no 
  , C1.drg_cost_weight 
  , C1.[Adm Date Time] 
  , C1.[Dsch Date Time] 
  , ROUND(C1.[Days Stay], 1) 
  , C1.[Readmitted in 30?] 
  , C1.[Discharge Month] 
  , C1.[Discharge Year] 
  , C1.[Discharge YYYY-M] 
  , C1.[Hospitalist Flag] 
  
  FROM CTE1 C1
  
  /* 
  This query will pull together if the patient is poly-pharmacy or not 
  */ 
  DECLARE @PLYPHARM TABLE( 
  ID INT IDENTITY(1, 1) PRIMARY KEY 
  , [Patient Name]       VARCHAR(MAX) 
  , [Admit Date Time]    DATETIME 
  , [Med List Type]      VARCHAR(MAX) 
  , [Last Status Update] DATETIME 
  , [Visit ID]           VARCHAR(MAX) 
  , [Home Med Count]     INT 
  ); 
  
  WITH CTE2 AS ( 
  SELECT  
  B.rpt_name                        AS [Patient Name] 
  , B.vst_start_dtime               AS [Admit Date Time] 
  , A.med_lst_type                  AS [Med List Type] 
  , B.last_cng_dtime                AS [Last Status Update] 
  , B.episode_no                    AS [Visit ID] 
  , CONVERT(INT, COUNT(A.med_name)) AS [Home Med Count] 
  
  FROM smsdss.qoc_med A 
  JOIN smsdss.QOC_vst_summ B 
  ON A.pref_vst_pms_id_col = B.pref_vst_pms_id_col 
  JOIN smsdss.BMH_PLM_PtAcct_V C 
  ON C.PtNo_Num = B.episode_no 
  
  WHERE A.med_lst_type = 'HML' 
  AND C.Plm_Pt_Acct_Type = 'I' 
  AND C.PtNo_Num < '20000000' 
  AND C.Dsch_Date >= @IP_START_DATE 
  AND C.Dsch_Date < @IP_END_DATE 
  
  GROUP BY  
  B.rpt_name 
  , B.vst_start_dtime 
  , A.med_lst_type 
  , B.last_cng_dtime 
  , B.episode_no 
  
  HAVING COUNT(A.MED_NAME) >= 6 
  ) 
  
  INSERT INTO @PLYPHARM 
  SELECT 
  C2.[Patient Name] 
  , C2.[Admit Date Time] 
  , C2.[Med List Type] 
  , C2.[Last Status Update] 
  , C2.[Visit ID] 
  , C2.[Home Med Count] 
  
  FROM CTE2 C2
  
  /* 
  Get the LIHN Service line data, we only want to columns from the data 
  */ 
  DECLARE @LIHNSVCLINE TABLE ( 
  [Visit ID]            VARCHAR(MAX) 
  , [LIHN Service Line] VARCHAR(MAX) 
  ); 
  
  WITH CTE3 AS ( 
  SELECT  
  SUBSTRING(pt_id, PATINDEX('%[^0]%', pt_id), 9) AS pt_id 
  , LIHN_Svc_Line 
  
  FROM  
  smsdss.c_LIHN_Svc_Lines_Rpt_v 
  ) 
  
  INSERT INTO @LIHNSVCLINE 
  SELECT 
  C3.pt_id 
  , C3.LIHN_Svc_Line 
  
  FROM CTE3 C3 
  
  
  /* 
  Does the patient have some sort of ICU stay during their visit? 
  */ 
  DECLARE @ICUVISIT TABLE( 
  [Visit ID]   VARCHAR(MAX) 
  , [ICU Flag] VARCHAR(MAX) 
  ); 
  
  WITH CTE4 AS ( 
  SELECT DISTINCT PVFV.pt_no 
  , MAX(CASE 
  WHEN TXFR.NURS_STA IN ('SICU', 'MICU', 'CCU') 
  THEN 1 
  ELSE 0 
  END) 
  OVER (PARTITION BY PVFV.PT_NO) AS [Has ICU Visit] 
  
  FROM smsdss.pms_vst_fct_v PVFV 
  JOIN smsdss.pms_xfer_actv_fct_v TXFR 
  ON PVFV.pms_vst_key = TXFR.pms_vst_key 
  ) 
  
  INSERT INTO @ICUVISIT 
  SELECT  
  CTE4.pt_no 
  , CTE4.[Has ICU Visit] 
  
  FROM CTE4
  
  /* 
  ####################################################################### 
  PULL IT ALL TOGETHER HERE 
  ####################################################################### 
  */ 
  SELECT  
  IP.* 
  , ISNULL(PP.[Med List Type], 'No HML') AS [Home Med List] 
  , CASE 
  WHEN PP.[Home Med Count] IS NULL 
  THEN 0 
  ELSE 1 
  END                                     AS [Poly Pharmacy] 
  , CASE 
  WHEN IP.drg_cost_weight < 1 THEN 0 
  WHEN IP.drg_cost_weight >= 1 
  AND IP.drg_cost_weight < 2 THEN 1 
  WHEN IP.drg_cost_weight >= 2 
  AND IP.drg_cost_weight < 3 THEN 2 
  WHEN IP.drg_cost_weight >= 3 
  AND IP.drg_cost_weight < 4 THEN 3 
  WHEN IP.drg_cost_weight >= 4 THEN 4 
  END                                   AS [DRG Weight Bin] 
  , ROUND( 
  CONVERT(FLOAT,VR.drg_std_days_stay) 
  , 1)                                    AS [DRG Std Days Stay] 
  , ROUND( 
  CONVERT( 
  FLOAT,DATEDIFF( 
  HOUR,  
  IP.[Adm Date Time],  
  IP.[Dsch Date Time] 
  )/24.0 
  ) 
  , 1)                                    AS [True Days Stay] 
  , ROUND( 
  ( 
  ROUND( 
  CONVERT( 
  FLOAT,DATEDIFF( 
  HOUR 
  , IP.[Adm Date Time] 
  , IP.[Dsch Date Time] 
  )/24.0 
  ) 
  , 1) 
  )  
  - 
  VR.drg_std_days_stay  
  ,1)                                     AS [DRG Opportunity] 
  , CASE 
  WHEN IP.Pt_Age >= 65 THEN 1 
  ELSE 0 
  END                                   AS [Senior Citizen Flag] 
  , LIHN.[LIHN Service Line] 
  , ICUV.[ICU Flag] 
  , DATEPART(WEEKDAY, IP.[ADM DATE TIME]) AS [Adm DOW] 
  , DATEPART(MONTH, IP.[ADM DATE TIME])   AS [Adm Month] 
  , DATEPART(YEAR, IP.[ADM DATE TIME])    AS [Adm Year] 
  , DATEPART(HOUR, IP.[ADM DATE TIME])    AS [Adm Hour] 
  , DATEPART(WEEKDAY, IP.[Dsch Date Time])AS [Dsch DOW] 
  , DATEPART(MONTH, IP.[DSCH DATE TIME])  AS [Dsch Month] 
  , DATEPART(YEAR, IP.[DSCH DATE TIME])   AS [Dsch Year] 
  , DATEPART(HOUR, IP.[DSCH DATE TIME])   AS [Dsch Hour] 
  
  FROM @INIT_POP IP 
  LEFT MERGE JOIN @PLYPHARM PP 
  ON IP.[Vist ID] = PP.[Visit ID] 
  LEFT MERGE JOIN smsmir.vst_rpt VR 
  ON IP.[Vist ID] = SUBSTRING(PT_ID, PATINDEX('%[^0]%', pt_id), 9) 
  LEFT MERGE JOIN @LIHNSVCLINE LIHN 
  ON IP.[Vist ID] = LIHN.[Visit ID] 
  LEFT MERGE JOIN @ICUVISIT ICUV 
  ON IP.[Vist ID] = ICUV.[Visit ID] 
  
  WHERE IP.drg_cost_weight IS NOT NULL 
  AND ICUV.[ICU Flag] IS NOT NULL 
  
  ORDER BY IP.[Dsch Date Time] ASC 
  
  
