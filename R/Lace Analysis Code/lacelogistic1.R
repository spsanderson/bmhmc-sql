# Logistic regression in R for LACE Data
library(aod)
library(ggplot2)

lace <- read.csv("lace for R.csv")
head(lace)
summary(lace)

# Our dataset has a dichotomoous variable FAILURE, this is the interesting
# variable and we are trying to predict FAILURE, which in our case
# is readmission or deth within 30 days of initial discharge.
sapply(lace, sd)

# We are now going to make a couple of two contingency tables
xtabs(~FAILURE + TOTAL.LACE, data=lace)

# Here we are going to use logistic regression specifically the glm
# or generalized linear model, first we have to convert TOTAL.LACE to a
# factor so it is treated as a categorical variable
lace$TOTAL.LACE <- factor(lace$TOTAL.LACE)

# The LACE.ACUTE.IP.SCORE was omitted as it is always a 3
lace.logit <- glm(FAILURE ~ TOTAL.LACE
                  , data=lace, family="binomial")
summary(lace.logit)

## Confidence Intervals useing profiled log-likelihood
confint(lace.logit)
# Using standard errors
confint.default(lace.logit)

# We are now going to exponentiate the coefficients and turn them into 
# odds ratios
exp(coef(lace.logit))
# Odds ratio and CI
exp(cbind(OR = coef(lace.logit), confint(lace.logit)))