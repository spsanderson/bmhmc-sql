# Load in Data, the data only contains those of AGE >= 18
lace <- read.csv("lace for R.csv")
summary(lace)

# Since we used attach, make sure that this is detached quickly
attach(lace)
plot(AGE, DAYS.TO.FAILURE, pch=unique(FAILURE + 2))
detach(lace)

attach(lace)
age1 <- 1000/AGE
plot(age1, DAYS.TO.FAILURE, pch=unique(FAILURE + 2))
legend(48, 32, c("Fail=1", "Fail=0"), pch=unique(FAILURE + 2))
detach(lace)

# Here we need to load the survival library
library(survival)

# This is going to create a tets dataset
attach(lace)
test <- survreg(Surv(DAYS.TO.FAILURE, FAILURE) ~ AGE, dist="logistic")
summary(test)

pred <- predict(test, type="response")
ord <- order(AGE)
age_ord <- AGE[ord]
pred_ord <- pred[ord]
plot(AGE, DAYS.TO.FAILURE, pch=unique(FAILURE + 2))
lines(age_ord, pred_ord)
detach(lace)
