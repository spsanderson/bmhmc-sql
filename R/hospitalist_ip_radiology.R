# Load Librarys
library(tidyverse)

# pull in data
rad_data <- readxl::read_xlsx("radiology.xlsx")

# properly structure the data before working with it.
glimpse(rad_data)
rad_data$MRN <- parse_character(rad_data$MRN)
rad_data$Encounter <- parse_character(rad_data$Encounter)
rad_data$LOS <- parse_integer(rad_data$LOS)
rad_data$Dsch_Year <- as.factor(rad_data$Dsch_Year)
rad_data$Dsch_Qtr <- as.factor(rad_data$Dsch_Qtr)
rad_data$Dsch_Mo <- as.factor(rad_data$Dsch_Mo)
rad_data$Dsch_Hr <- as.factor(rad_data$Dsch_Hr)
rad_data$ED_IP_FLAG <- NULL
rad_data$Ord_Pty_Spclty <- NULL
rad_data$Ord_Loc <- NULL
rad_data$Performing_Dept <- NULL
rad_data$Svc_Dept_Desc <- NULL
rad_data$Atn_Dr <- parse_character(rad_data$Atn_Dr)
rad_data$LIHN_Svc_Line <- as.factor(rad_data$LIHN_Svc_Line)
rad_data$ROM <- as.factor(rad_data$ROM)
rad_data$SOI <- as.factor(rad_data$SOI)
rad_data$APR_DRG <- parse_character(rad_data$APR_DRG)
rad_data$Ord_Pty_Number <- parse_character(rad_data$Ord_Pty_Number)
rad_data$Ordering_Party <- parse_character(rad_data$Ordering_Party)
rad_data$Ord_Set_ID <- parse_character(rad_data$Ord_Set_ID)
rad_data$Svc_Cd <- parse_character(rad_data$Svc_Cd)
rad_data$Svc_Desc <- parse_character(rad_data$Svc_Desc)
rad_data$Svc_Sub_Dept <- as.factor(rad_data$Svc_Sub_Dept)
rad_data$Svc_Sub_Dept_Desc <- as.factor(rad_data$Svc_Sub_Dept_Desc)
rad_data$Ord_Ent_Yr <- as.factor(rad_data$Ord_Ent_Yr)
rad_data$Ord_Ent_Qtr <- as.factor(rad_data$Ord_Ent_Qtr)
rad_data$Ord_Ent_Mo <- as.factor(rad_data$Ord_Ent_Mo)
rad_data$Ord_Ent_Hr <- as.factor(rad_data$Ord_Ent_Hr)
rad_data$Ord_Start_Yr <- as.factor(rad_data$Ord_Start_Yr)
rad_data$Ord_Start_Qtr <- as.factor(rad_data$Ord_Start_Qtr)
rad_data$Ord_Start_Mo <- as.factor(rad_data$Ord_Start_Mo)
rad_data$Ord_Start_Hr <- as.factor(rad_data$Ord_Start_Hr)
rad_data$Ord_Stop_Yr <- as.factor(rad_data$Ord_Stop_Yr)
rad_data$Ord_Stop_Qtr <- as.factor(rad_data$Ord_Stop_Qtr)
rad_data$Ord_Stop_Mo <- as.factor(rad_data$Ord_Stop_Mo)
rad_data$Ord_Stop_Hr <- as.factor(rad_data$Ord_Stop_Hr)
rad_data$Order_Status <- parse_character(rad_data$Order_Status)
rad_data$Order_Occ_Status <- parse_character(rad_data$Order_Occ_Status)
rad_data$Dup_Order <- parse_logical(rad_data$Dup_Order)
rad_data$Performance <- parse_double(rad_data$Performance)
rad_data$Opportunity <- parse_double(rad_data$LOS - rad_data$Performance)
glimpse(rad_data)

#######################################################################
# Add some data like pt_count, order_count, ord_per_pt
# This is by orering party and then by Ord_Pty & Svc_Line
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Total Order_Count and Total Patient_Count by Ordering_Party
# Order_Count per encounter
tblPerf <- rad_data %>%
  group_by(Ord_Pty_Number) %>%
  # How many orders did the ordering party place
  mutate(ordpty_order_count = n_distinct(Order_No)) %>%
  # How many patients did the ordering party place orders on
  mutate(ordpty_pt_count = n_distinct(Encounter)) %>%
  group_by(Encounter) %>%
  # How many orders did the patient get
  mutate(enc_order_count = n_distinct(Order_No)) %>%
  mutate(enc_pt_count = 1) 
# Total Orders per Ordering Party divided by Total Encounters by 
# ordering party, gives average orders per
# encounter by ordering party
tblPerf <- tblPerf %>%
  group_by(Ord_Pty_Number) %>%
  mutate(avg_ordperenc_ord_pty = ordpty_order_count / ordpty_pt_count) %>%
# Order_Count and Patient_Count/Ordering_party/svc_line
  group_by(Ord_Pty_Number, LIHN_Svc_Line) %>%
  mutate(ordpty_svcline_ord_count = n_distinct(Order_No)) %>%
  mutate(ordpty_svcline_pt_count = n_distinct(Encounter))
# Orders/Patient by Ordering_Party & Svc_Line
tblPerf <- tblPerf %>%
  mutate(svcline_ord_per_pt = 
           ordpty_svcline_ord_count / ordpty_svcline_pt_count)
# Get ALOS, ELOS and Avg_Opportunity per Ordering_Party
tblPerf <- tblPerf %>%
  group_by(Ord_Pty_Number) %>%
  mutate(ord_pty_alos = round(mean(LOS), 4)) %>%
  mutate(ord_pty_elos = round(mean(Performance), 4)) %>%
  mutate(ord_pty_aopp = round(mean(Opportunity), 4)) %>%
  group_by(Ord_Pty_Number, LIHN_Svc_Line) %>%
  mutate(ord_pty_svc_alos = round(mean(LOS), 4)) %>%
  mutate(ord_pty_svc_elos = round(mean(Performance), 4)) %>%
  mutate(ord_pty_svc_aopp = round(mean(Opportunity), 4))

# # Make a test table to look over variables
# tblTest <- filter(tblPerf, Ord_Pty_Number == 12039)
# tblTest <- tblTest %>%
#   mutate(ord_per_pt_elos =
#            round((enc_order_count/Performance), 4)) %>%
#   mutate(ord_pty_svcline_ord_elos =
#            round((svcline_ord_per_pt/ord_pty_svc_elos), 4)) %>%
#   mutate(avg_ord_per_pt_elos = round(avg_ordperenc_ord_pty/ord_pty_elos, 4))
# # After review, drop tblTest
# rm(tblTest)

# Create a performance table that will get used to create a table for 
# reporting and visualizations without Svc Sub Dept (MRI, CatScan information)
# Just aggregates of both order types.
tblPerf <- tblPerf %>%
  mutate(ord_per_pt_elos = 
           round((enc_order_count/Performance), 4)) %>%
  mutate(ord_pty_svcline_ord_elos = 
           round((svcline_ord_per_pt/ord_pty_svc_elos), 4)) %>%
  mutate(avg_ord_per_pt_elos = round(avg_ordperenc_ord_pty/ord_pty_elos, 4))

# create rpt_tbl from tbl_Performance, we want only the performance per
# encounter for right now
tblPerf <- ungroup(tblPerf) # in order to get a distinct ungrouped table
rptTblOrdPtyEncPerf <- distinct(
  select(
    .data = tblPerf
    , Ord_Pty_Number
    , Ordering_Party
    , Encounter
    , LOS
    , Performance
    , Opportunity
    , enc_order_count
    , ord_per_pt_elos
  )
)
rptTblOrdPtyEncPerf <- arrange(.data = rptTblOrdPtyEncPerf
                               , Ord_Pty_Number, Encounter)

rptTblOrdPtyLIHNPerf <- distinct(
  select(
    .data = tblPerf
    , Ord_Pty_Number
    , Ordering_Party
    , LIHN_Svc_Line
    , ordpty_svcline_ord_count
    , ordpty_svcline_pt_count
    , ord_pty_svc_alos
    , ord_pty_svc_elos
    , ord_pty_svcline_ord_elos
  )
)
rptTblOrdPtyLIHNPerf <- arrange(.data = rptTblOrdPtyLIHNPerf
  , Ord_Pty_Number, LIHN_Svc_Line)

rptTblOrdPtyEncPerf <- rptTblOrdPtyEncPerf %>%
  group_by(Ord_Pty_Number) %>%
  mutate(agg_per = round(mean(ord_per_pt_elos), 4))

rptTblLIHNCounts <- tblPerf %>%
  group_by(LIHN_Svc_Line) %>%
  mutate(svcline_order_count = n_distinct(Order_No)) %>%
  mutate(svcline_pt_count = n_distinct(Encounter)) %>%
  group_by(LIHN_Svc_Line, Svc_Sub_Dept_Desc) %>%
  mutate(svcDesc_order_count = n_distinct(Order_No)) %>%
  mutate(svcDesc_pt_count = n_distinct(Encounter))

rptTblLIHNCounts <- ungroup(rptTblLIHNCounts) 
rptTblLIHNCounts_a <- distinct(
  select(
    .data = rptTblLIHNCounts
    , LIHN_Svc_Line
    , svcline_order_count
    , svcline_pt_count
  )
)
rptTblLIHNCounts_b <- filter(
  .data = rptTblLIHNCounts
  , Svc_Sub_Dept_Desc == "MRI"
  )
rptTblLIHNCounts_b <- distinct(
  select(
    .data = rptTblLIHNCounts_b
    , LIHN_Svc_Line
    , mri_order_count = svcDesc_order_count
    , mri_pt_count = svcDesc_pt_count
  )
)

rptTblLIHNCounts_c <- filter(
  .data = rptTblLIHNCounts
  , Svc_Sub_Dept_Desc == "Cat Scan"
)
rptTblLIHNCounts_c <- distinct(
  select (
    .data = rptTblLIHNCounts_c
    , LIHN_Svc_Line
    , ctscan_order_count = svcDesc_order_count
    , ctscan_pt_count = svcDesc_pt_count
  )
)
  
test <- full_join(
  rptTblLIHNCounts_a, rptTblLIHNCounts_b, by = "LIHN_Svc_Line"
)
test <- full_join(
  test, rptTblLIHNCounts_c, by = "LIHN_Svc_Line"
)
# pick up here, need to rename columns
rptTblLIHNCounts <- select(
  .data = test
  , LIHN_Svc_Line
  , svcline_order_count
  , svcline_pt_count
  , mri_order_count
  , mri_pt_count
  , ctscan_order_count
  , ctscan_pt_count
) %>%
  mutate_all(funs(ifelse(is.na(.), 0, .)))

rm(test
   , rptTblLIHNCounts_a
   , rptTblLIHNCounts_b
   , rptTblLIHNCounts_c
   )

rptTblEncPerf <- rad_data %>%
  group_by(Encounter) %>%
  mutate(order_count = n_distinct(Order_No)) %>%
  mutate(order_per_elos = order_count / Performance)

rptTblEncPerf <- rptTblEncPerf %>%
  distinct(Encounter
           , order_per_elos
           , Ord_Ent_Mo
  ) %>%
  filter(
      Ord_Ent_Mo == 1 | 
      Ord_Ent_Mo == 2 |
      Ord_Ent_Mo == 3 |
      Ord_Ent_Mo == 4 |
      Ord_Ent_Mo == 5 |
      Ord_Ent_Mo == 6 |
      Ord_Ent_Mo == 7 |
      Ord_Ent_Mo == 8 |
      Ord_Ent_Mo == 9 |
      Ord_Ent_Mo == 10
    )


# Create functions for histograms and optimal binsize 
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# 2006 Author Hideaki Shimazaki
# Department of Physics, Kyoto University
# shimazaki at ton.scphys.kyoto-u.ac.jp
# Please feel free to use/modify/distribute this program.
sshist <- function(x){
  
  N <- 2: 100
  C <- numeric(length(N))
  D <- C
  
  for (i in 1:length(N)) {
    D[i] <- diff(range(x))/N[i]
    
    edges = seq(min(x),max(x),length=N[i])
    hp <- hist(x, breaks = edges, plot=FALSE )
    ki <- hp$counts
    
    k <- mean(ki)
    v <- sum((ki-k)^2)/N[i]
    
    C[i] <- (2*k-v)/D[i]^2	#Cost Function
  }
  
  idx <- which.min(C)
  optD <- D[idx]
  
  edges <- seq(min(x),max(x),length=N[idx])
  h = hist(x, breaks = edges)
  rug(x)
  
  return(h)
}

optBin <- function(x){
  
  N <- 2: 100
  C <- numeric(length(N))
  D <- C
  
  for (i in 1:length(N)) {
    D[i] <- diff(range(x))/N[i]
    
    edges = seq(min(x),max(x),length=N[i])
    hp <- hist(x, breaks = edges, plot=FALSE )
    ki <- hp$counts
    
    k <- mean(ki)
    v <- sum((ki-k)^2)/N[i]
    
    C[i] <- (2*k-v)/D[i]^2	#Cost Function
  }
  
  idx <- which.min(C)
  optD <- D[idx]
  
  edges <- seq(min(x),max(x),length=N[idx])
  
  return(edges)
}
#################

# create some visualizations
# sshist(tbl_Performance$ord_per_pt_elos)
# sshist(tbl_Ord_Perf$ord_per_pt_elos_lihnsvcline)

bw <- optBin(rptTblOrdPtyEncPerf$LOS)
ggplot(data = rptTblOrdPtyEncPerf) +
  geom_histogram(mapping = aes(x = LOS)
                 , breaks = bw
                 , color = "black"
                 , fill = "lightblue") +
  xlab("Length of Stay") +
  ylab("Count") +
  ggtitle("LOS Distribution by Ordering Provider",
          subtitle = "Source: DSS")

bw <- optBin(rptTblOrdPtyEncPerf$ord_per_pt_elos)
ggplot(data = rptTblOrdPtyEncPerf) +
  geom_histogram(mapping = aes(x = ord_per_pt_elos)
                , breaks = bw
                , color = "black"
                , fill = "lightblue") +
  xlab("Orders Per Patient Per ELOS") +
  ylab("Count") +
  ggtitle("Average Orders Per Patient Per ELOS"
          , subtitle = "Source: DSS")

stats <- boxplot.stats(rptTblOrdPtyLIHNPerf$ord_pty_svcline_ord_elos)$stats
ggplot(data = rptTblOrdPtyLIHNPerf
       , mapping = aes(x = reorder(LIHN_Svc_Line,
                                  ord_pty_svcline_ord_elos)
                       ,y = ord_pty_svcline_ord_elos)) +
  geom_boxplot(fill = "lightblue",
               outlier.shape = NA) +
  scale_y_continuous(limits = c(stats[1], stats[5])) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.major.x = element_line(color = "grey60",
                                          linetype = "dashed")) +
  xlab("LIHN Service Line") +
  ylab("Average Orders Per Patient Per ELOS") +
  ggtitle("Average Orders per Patient per ELOS by LIHN Service Line",
          subtitle = "Source: DSS")
  

boxplot(tblPerf$avg_ord_per_pt_elos
    , col = "lightblue"
    , main = "Average Orders Per Patient per ELOS"
    , sub = "Source: DSS"
    , ylab = "Average Orders Per Patient Per ELOS"
  )

ggplot(data = rptTblOrdPtyEncPerf,
       mapping = aes(x = agg_per,
                     y = reorder(Ordering_Party, agg_per)
                     )
       ) +
  geom_segment(aes(yend = Ordering_Party), 
               xend = 0, color = "grey50") +
  geom_point(size = 3) +
  theme_bw() +
  theme(panel.grid.major.y = element_blank()) +
  ylab("Ordering Provider") +
  xlab("Aggregate Performance of Order Per Pt ELOS") +
  ggtitle("Aggregate Performance of Orders Per PT Elos by Ordering Provider",
          subtitle = "Source: DSS")

ggplot(data = rptTblOrdPtyLIHNPerf,
       mapping = aes(x = ord_pty_svcline_ord_elos,
                     y = reorder(Ordering_Party, ord_pty_svcline_ord_elos)
                     )
       ) +
  geom_segment(aes(yend = Ordering_Party),
               xend = 0, color = "grey50") +
  geom_point(size = 3, aes(color = LIHN_Svc_Line)) +
  theme_bw() +
  theme(panel.grid.major.y = element_blank()) +
  ylab("Ordering Provider") +
  xlab("Orders Per LIHN Svc Line Per Pt ELOS") +
  ggtitle("Orders per Pt ELOS by LIHN Service Line",
          subtitle = "Source: DSS")

ggplot(data = rptTblEncPerf, 
       mapping = aes(x = Ord_Ent_Mo,
                     y = order_per_elos)) +
  geom_boxplot(outlier.shape = NA)