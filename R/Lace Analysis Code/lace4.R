# Interpretation of Fitted Proportional Hazard Regression Models
lace <- read.csv("lace for R.csv")
library(survival)
library(car)

attach(lace)

# We will use the recode function to create a categorical version
# of age and define it to be a factor variable.
agecat <- recode(AGE, "19:29='A'; 30:39='B'; 40:49='C';
                 50:59='D'; 60:69='E'; 70:79='F';
                 80:89='G'; 90:120='H'")
agecat.ph <- coxph(Surv(DAYS.TO.FAILURE, FAILURE) ~ agecat, 
                   method="breslow")
summary(agecat.ph)
names(agecat.ph)

agecat.ph$var

# We will use the recode function to create a categorical version
# of TOTAL.LACE and define it to be a factor variable.
tlcat <- recode(TOTAL.LACE, "3:4='A'; 5:6='B'; 7:8='C';
                9:10='D'; 11:12='E'; 13:14='F';
                15:16='G'; 17:18='H'")
tlcat.ph <- coxph(Surv(DAYS.TO.FAILURE, FAILURE) ~ tlcat,
                  method="breslow")
summary(tlcat.ph)
names(tlcat.ph)

tlcat.ph$var

