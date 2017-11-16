# Some Regression models for Survival Data
update.packages()
rm(list=ls()) # <-- this line will clear out all objects
lace <- read.csv("lace for R.csv")
library(survival)
attach(lace)
age.coxph <- coxph(Surv(DAYS.TO.FAILURE, FAILURE) ~ AGE,
                   method="breslow")
summary(age.coxph)

total.lace.coxph <- coxph(Surv(DAYS.TO.FAILURE, FAILURE) ~ TOTAL.LACE,
                          method="breslow")
summary(total.lace.coxph)
detach(lace)