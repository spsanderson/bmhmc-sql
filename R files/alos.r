library(ggplot2)
discdata <- read.csv("discharge_data.csv")

summary(discdata)

hist(discdata$Actual.Measure.Performance.Case)
hist(discdata$Expected.Measure.Performance.Case)

qplot(Actual.Measure.Performance.Case,
      geom = "density",
      color = Discharge.Year,
      fill = Discharge.Year,
      facets = Discharge.Year ~ .,
      size = I(1.25),
      data = discdata)

dens_act <- density(discdata$Actual.Measure.Performance.Case)
dens_exp <- density(discdata$Expected.Measure.Performance.Case)

xlim <- range(dens_act$x, dens_exp$x)
ylim <- range(0, dens_act$y, dens_exp$y)

actcolor <- rgb(1,0,0,0.2)
expcolor <- rgb(0,0,1,0.2)

plot(dens_act, 
     xlim = xlim, 
     ylim = ylim, 
     xlab="LOS",
     main = "Actual vs. Expected LOS 2010q1 - 2013q2",
     panel.first = grid())

polygon(dens_act, density = -1, col = actcolor)
polygon(dens_exp, density = -1, col = expcolor)

legend('topright', 
       c('Actual','Expected'),
       fill = c(actcolor,expcolor), 
       bty = 'n',
       border = NA)

ggplot(discdata,
       aes(x=Actual.Measure.Performance.Case, 
           y=..density.., 
           group=Severity.of.Illness.Code)) + 
  geom_histogram(alpha=0.5, 
                 aes(colour=Severity.of.Illness.Code,
                     fill=Severity.of.Illness.Code)) + 
  geom_freqpoly(linetype="dotdash",
                alpha=1, 
                aes(colour=Severity.of.Illness.Code)) + 
  facet_wrap(~Severity.of.Illness.Code) + 
  labs(title = "Density and Histogram of ALOS Grouped by Severity
       of Illness: 2010q1 - 2013q2");

ggplot(discdata,
       aes(x=Expected.Measure.Performance.Case, 
           y=..density.., 
           group=Severity.of.Illness.Code)) + 
  geom_histogram(alpha=0.5, 
                 aes(colour=Severity.of.Illness.Code,
                     fill=Severity.of.Illness.Code)) + 
  geom_freqpoly(linetype="dotdash",
                alpha=1, 
                aes(colour=Severity.of.Illness.Code)) + 
  facet_wrap(~Severity.of.Illness.Code) + 
  labs(title = "Density and Histogram of ELOS Grouped by Severity
       of Illness: 2010q1 - 2013q2");
