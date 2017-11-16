# Histograms of Lace Failures, non-failures and faceted
lace <- read.csv("lace for R.csv")

# Required libraries
library(ggplot2)

qplot(TOTAL.LACE, 
      data = lace, 
      colour = SEX,
      geom = "density",
      size = I(1.25),
      main = "Density Graphs for Total Lace Score by Sex")

qplot(TOTAL.LACE, 
      data = lace,  
      colour = factor(FAILURE),
      geom = "density",
      size = I(1.25),
      main = "Density Graphs for Total Lace Score by Failure")

qplot(TOTAL.LACE, LACE.ER.SCORE, 
      data = lace, 
      facets = SEX ~ .,
      geom = "smooth",
      main = "Total Lace Score by Lace ER Visits Grouped by Sex")

# Breaking data into failure = F and non Failure = N
f <- data.frame(lace[lace$FAILURE == 1,])
n <- data.frame(lace[lace$FAILURE == 0,])

qplot(TOTAL.LACE, 
      data = f, 
      facets = SEX ~ .,
      geom = "density", 
      main = "Density Graph for Readmits")

qplot(TOTAL.LACE, 
      data = n, 
      facets = SEX ~ .,
      geom = "density", 
      main = "Density Graph for Patients Not Readmitted")

qplot(TOTAL.LACE, 
      data = lace, 
      colour = SEX,
      facets = FAILURE ~ .,
      geom = "density",
      size = I(1.25),
      main = "Density Graphs: Total Lace Grouped by Failure; Color = Failure")

qplot(TOTAL.LACE,
      data = lace,
      colour = factor(FAILURE),
      facets = SEX ~ .,
      geom = "density",
      size = I(1.25),
      main = "Density Graphs: Total lace Grouped by Sex; Color = Failure")

qplot(TOTAL.LACE, FAILURE, 
      data = lace, 
      geom = "smooth",
      main = "Total Lace Score by Failure")