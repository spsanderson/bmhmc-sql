require("lattice")
library("scatterplot3d")

columns <- c("Age", "Sex", "Days_Score", "Acute_IP_Score",
             "ER_Score","Comorbid_Score", "Total_Lace", "Failure", 
             "LOS", "Days_To_Failure")
lace <- read.csv("lace for R.csv", 
                 header=TRUE,
                 col.names=columns)

x <- lace$Age
y <- lace$"Total_Lace"
z <- lace$"Days_Score"

scatterplot3d(x,y,z, highlight.3d=T, angle=75)

library(rgl)
plot3d(x,y,z)