# Possible Probit Regression
lace <- read.csv("lace for R.csv")
require(aod)
require(ggplot2)

# Convert TOTAL.LACE to a factor (categorical variable)
lace$TOTAL.LACE <- factor(lace$TOTAL.LACE)

head(lace)
summary(lace)
xtabs(~TOTAL.LACE + FAILURE, data=lace)

myprobit <- glm(FAILURE ~ AGE + TOTAL.LACE
                , family = binomial(link="probit"),
                data = lace)
# Model summary
summary(myprobit)
confint(myprobit)

newdata <- data.frame(AGE = rep(seq(from = 200, to = 800, length.out = 100),
                                4 * 4),
                      DAYS.TO.FAILURE = rep(c(7,14,21,30), each = 100 * 4),
                      TOTAL.LACE = factor(rep(rep(7:10, each = 100),
                                              4)))
head(newdata)

newdata[, c("p", "se")] <- predict(myprobit, newdata, type = "response",
                                   se.fit = TRUE)[-3]
ggplot(newdata,
       aes(x = AGE, y = p, colour = TOTAL.LACE)) + geom_line() + facet_wrap(
         ~DAYS.TO.FAILURE)