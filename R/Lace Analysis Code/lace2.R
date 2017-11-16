# Here we will need to load in survial and KMsurv libraries
lace <- read.csv("lace for R.csv")
library(survival)
library(KMsurv)
library(nlme)
library(km.ci)

attach(lace)
lace.survival <- survfit(Surv(DAYS.TO.FAILURE, FAILURE) ~ 1,
                         conf.type="none")
summary(lace.survival)
plot(lace.survival, xlab="Days To Failure", ylab="Survival Probability",
     main = "Survival Curve by Days To Failure")

total.lace.survival <- survfit(Surv(TOTAL.LACE, FAILURE) ~ 1,
                               conf.type="none")
summary(total.lace.survival)
plot(total.lace.survival, xlab="Total Lace Score",
     ylab="Survival Probability", 
     main = "Survival Curve by Total Lace Score")

age.lace.survival <- survfit(Surv(AGE, FAILURE) ~ 1,
                             conf.type="none")
summary(age.lace.survival)
plot(age.lace.survival, xlab="Age",
     ylab="Survival Probability",
     main = "Survival Curve by Age")
detach(lace)

# This is going to get certain items necessary for suvival curves for
# DAYS.TO.FAILURE, it should then be repeated for TOTAL.LACE
attach(lace)
lace.survival <- survfit(Surv(DAYS.TO.FAILURE, FAILURE) ~ 1)
a <- km.ci(lace.survival, conf.level=0.95, tl=NA, tu=NA
           , method="loghall")

par(cex=0.8)
plot(a, lty=2, lwd=2, xlab="Days To Failure",
     ylab="Survial Probability", 
     main = "Survival Curve for Days To Failure")
time.conf <- survfit(Surv(DAYS.TO.FAILURE, FAILURE) ~ 1)
lines(time.conf, lwd=2, lty=1)
lines(time.conf, lwd=1, lty=4, conf.int=T)
linetype <- c(1, 2, 4)
detach(lace)
legend(20, .9, c("Kaplan-Meier", "Hall-Wellner", "Pointwise"),
       lty=(linetype))

# Survival Curves for TOTAL.LACE below
attach(lace)
total.lace.survival <- survfit(Surv(TOTAL.LACE, FAILURE) ~ 1)
atl <- km.ci(total.lace.survival, conf.level=0.95, tl=NA, tu=NA
             , method="loghall")

par(cex=0.8)
plot(atl, lty=2, lwd=2, xlab="Total Lace Score",
     ylab = "Survival Probability",
     main = "Survival Curve for Total Lace Score")
time.conftl <- survfit(Surv(TOTAL.LACE, FAILURE) ~ 1)
lines(time.conftl, lwd=2, lty=1)
lines(time.conftl, lwd=1, lty=4, conf.int=T)
linetypeatl <- c(1, 2, 4)
detach(lace)
legend(5, 0.4, c("Kaplan-Meier", "Hall-Wellner", "Pointwise"),
       lty=(linetypeatl))

# Now we will do the same thing for Age
attach(lace)
age.lace.survival <- survfit(Surv(AGE, FAILURE) ~ 1)
aage <- km.ci(age.lace.survival, conf.level=0.95, tl=NA, tu=NA
              , method="loghall")

par(cex=0.8)
plot(aage, lty=2, lwd=2, xlab="Age",
     ylab="Survial Probability", 
     main = "Survival Curve for Age")
time.conf.age <- survfit(Surv(AGE, FAILURE) ~ 1)
lines(time.conf.age, lwd=2, lty=1)
lines(time.conf.age, lwd=1, lty=4, conf.int=T)
linetype <- c(1, 2, 4)
detach(lace)
legend(50, .6, c("Kaplan-Meier", "Hall-Wellner", "Pointwise"),
       lty=(linetype))

# # Not to sure about this block of code, meaning is it necessary
# # because we are not testing for interventions
# stci = function(qn, y)
# {
#   temp <- data.frame(time=y$time, surv=y$surv, std.err=y$std.err)
#   temp$std.err <- temp$std.err*temp$surv
#   attach(temp)
#   q.lp <- temp[surv <= qn/100 - 0.05,][1,]
#   q <- temp[surv <= qn/100,][1,]
#   q.u <- temp[surv >= qn/100 + 0.05,]
#   rnm <- nrow(q.u)
#   q.up <- q.u[rnm, ]
#   fp = (q.up$surv - q.lp$surv)/(q.lp$time - q.up$time)
#   std = (q$std.err)/fp
#   lower = q$time - 1.96*std
#   upper = q$time + 1.96*std
#   print(rbind(c(quantile=qn, time=q$time, std.err=std,
#                 cie.lower=lower, cie.upper=upper)))
# }
# 
# 
# lace <- read.csv("lace for R.csv")
# library(survival)
# attach(lace)
# l.surv <- survfit(Surv(DAYS.TO.FAILURE, FAILURE) ~ 1,
#                   conf.type="log-log")
# stci(75, l.surv)
# stci(50, l.surv)
# stci(25, l.surv)
# summary(l.surv)
# print(l.surv, show.rmean=T)
# 
# timestrata.surv <- survfit(Surv(DAYS.TO.FAILURE
#                                 , FAILURE) ~ strata(SEX),
#                            lace, conf.type="log-log")
# 
# plot(timestrata.surv, lty=c(1,2),
#      , xlab="Days To Failure",
#      ylab="Survival Probability")
# legend(0, 0.4, c("Sex=F", "Sex=M"), lty=c(1,2))
# detach(lace)

# Testing differences between age categories, we will also do this for 
# TOTAL.LACE categories
attach(lace)
age.cat <- cut(AGE, c(18.0, 39, 59, 79, 99))
age.surv <- survfit(Surv(DAYS.TO.FAILURE, FAILURE) ~ strata(age.cat)
                    , conf.type="log-log")
print(age.surv)

plot(age.surv, lty=c(1, 2, 3, 4),
     xlab="Days To Failure",
     ylab="Survival Probability",
     main="Survival Curve by Age Category")
legend(20, 1.0,
       c("Group 1", "Group 2", "Group 3",
         "Group 4"),
       lty=c(1, 2, 3, 4, 5))
detach(lace)

# Now by TOTAL.LACE
attach(lace)
totlace.cat <- cut(TOTAL.LACE, c(3,6,9,12,15))
totlace.surv <- survfit(Surv(DAYS.TO.FAILURE, 
                             FAILURE) ~ strata(totlace.cat),
                        conf.type="log-log")
print(totlace.surv)

plot(totlace.surv, lty=c(1, 2, 3, 4),
     xlab="Days To Failure",
     ylab="Survival Probability",
     main="Survival Curve by Total Lace Category")
legend(20, 1.0,
       c("Group 1", "Group 2", "Group 3",
         "Group 4"),
       lty=c(1, 2, 3, 4, 5))
detach(lace)
#######################################################################
# Survival Differences for AGE and TOTAL.LACE Categories
attach(lace)
survdiff(Surv(DAYS.TO.FAILURE, FAILURE) ~ age.cat, rho=0)
survdiff(Surv(DAYS.TO.FAILURE, FAILURE) ~ age.cat, rho=1)

# Caclulating the Nelson-Aalen estimator of the survivorship
# function for lace data.
ana <- survfit(coxph(Surv(DAYS.TO.FAILURE, FAILURE) ~ 1),
               type="aalen")
summary(ana)

l.aalen <- (-log(ana$surv))
aalen.est <- cbind(time=ana$time, d=ana$n.event, n=ana$n.risk,
                   l.aalen, s1=ana$surv)
b <- survfit(Surv(DAYS.TO.FAILURE, FAILURE) ~ 1)
km.est <- cbind(time=b$time, s2=b$surv)
all <- merge(data.frame(aalen.est), data.frame(km.est), by="time")
all

plot(all$time, all$s1, type="s", xlab="Survival Time (Days)",
     ylab="Survival Probability")
points(all$time, all$s1, pch=1)
lines(all$time, all$s2, type="s")
points(all$time, all$s2, pch=3)
legend(20, 1, c("Nelson-Aalen", "Kaplan-Meier"), pch=c(1,3))

ana2 <- all$d/all$n
plot.new()
plot(all$time, ana2, type="p", pch=20, xlab="Survial Time (Days)",
     ylab="Hazard Ratio")
lines(lowess(all$time, ana2, f=0.75, iter=5))
detach(lace)