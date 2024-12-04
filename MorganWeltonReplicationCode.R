#Frontmatter
{
rm(list = ls())
library(foreign)
library(haven)
library(tidyverse)
library(stargazer)

setwd("~/ECON582/intermediate_datasets/intermediate_datasets")
df <- as.data.frame(haven::read_dta("canada_pcs.dta"))
df2 <- as.data.frame(haven::read_dta("women_pcs.dta"))

df <- zap_labels(df)
df2 <- zap_labels(df2)
}

#Year of Arrival Density
{
ggplot(data = df[df$yrimmig != 0,]) +
  geom_density(mapping = aes(x = yrimmig), fill = "gray") +
  xlab("Year of Immigration") +
  ylab("") +
  ggtitle("Density of Reported Immigration Years - Canadians") +
  theme_bw()
ggplot(data = df2[df2$yrimmig != 0,]) +
  geom_density(mapping = aes(x = yrimmig), fill = "gray") +
  xlab("Year of Immigration") +
  ylab("") +
  ggtitle("Density of Reported Immigration Years - Women") +
  theme_bw()
}

#Summary Tables for Canadian Sample
{
dfnative <- df[df$yrimmig == 0,]
dfimmigrant <- df[df$yrimmig != 0,]

stargazer(dfimmigrant[,c(7,11,26)], omit.summary.stat = "N")
stargazer(dfnative[,c(7,11,26)], omit.summary.stat = "N")
}

#Summary Tables for Women Sample
{
df2 <- as.data.frame(df2)
df2native <- df2[df2$yrimmig == 0,]
df2immigrant <- df2[df2$yrimmig != 0,]

stargazer(df2immigrant[,c(7,11,26)], omit.summary.stat = "N")
stargazer(df2native[,c(7,11,26)], omit.summary.stat = "N")
}

setwd("~/ECON582")
df3 <-readxl::read_xlsx("tables.xlsx")
df3$`Link Rate` <- paste0(round(df3$`Link Rate`*100, 2), "%")
stargazer(df3, summary = F, digits = 2, rownames = F)

#Manually entering regression coefficients from regressions
CanadianCSCoef <- c(837.51, 1458.48, 1117.72, 761.70, 679.09)
CanadianCSSE <- c(40.65, 45.71, 40.29, 36.05, 25.49)
CanadianPanelCoef <- c(766.36, 1545.04, 1326.06, 1144.51, 1423.66)
CanadianPanelSE <- c(145.13, 131.21, 101.7, 88.46, 55.41)

scle <- factor(c("0-5 Years", "6-10 Years", "11-15 Years", "16-20 Years", "21+ Years"), levels = c("0-5 Years", "6-10 Years", "11-15 Years", "16-20 Years", "21+ Years"))
canadianPlotDF <- rbind(data.frame(coefs = CanadianCSCoef, SEs = CanadianCSSE, scle, type = rep("Cross-Sectional", 5)),
      data.frame(coefs = CanadianPanelCoef, SEs = CanadianPanelSE, scle, type = rep("Panel", 5)))
canadianPlotDF$minimum <- canadianPlotDF$coefs - 1.96*canadianPlotDF$SEs
canadianPlotDF$maximum <- canadianPlotDF$coefs + 1.96*canadianPlotDF$SEs

ggplot(data = canadianPlotDF, mapping = aes(x = scle)) +
  geom_ribbon(mapping = aes( ymin = minimum, ymax = maximum, group = type, fill = type), alpha = 0.25) +
  geom_line(mapping = aes(y = coefs, group = type, linetype = type)) +
  xlab("Time Spent in united States") +
  ylab("Coefficent Estimate") +
  ggtitle("Divergence of Canadian Mens' Coefficients in Panel & Cross-Section Samples") +
  scale_fill_discrete(name = "Sample") +
  scale_linetype_discrete(name = "Sample") +
  theme_bw()

WomenCSCoef <- c(-254.99, -927.3, -1056.51, -865.79, -1086.51)
WomenCSSE <- c(18.3, 16.56, 15.9, 15.29, 14.31)
WomenPanelCoef <- c(-2856.08, -2899.86, -2635.40, -2314.5, -2175.83)
WomenPanelSE <- c(28.47, 23.28, 20.68, 20.59, 16.1)

WomenPlotDF <- rbind(data.frame(coefs = WomenCSCoef, SEs = WomenCSSE, scle, type = rep("Cross-Sectional", 5)),
                     data.frame(coefs = WomenPanelCoef, SEs = WomenPanelSE, scle, type = rep("Panel", 5)))
WomenPlotDF$minimum <- WomenPlotDF$coefs - 1.96*WomenPlotDF$SEs
WomenPlotDF$maximum <- WomenPlotDF$coefs + 1.96*WomenPlotDF$SEs

ggplot(data = WomenPlotDF, mapping = aes(x = scle)) +
  geom_ribbon(mapping = aes( ymin = minimum, ymax = maximum, group = type, fill = type), alpha = 0.25) +
  geom_line(mapping = aes(y = coefs, group = type, linetype = type)) +
  xlab("Time Spent in united States") +
  ylab("Coefficent Estimate") +
  ggtitle("Divergence of Women's Coefficients in Panel & Cross-Section Samples") +
  scale_fill_discrete(name = "Sample") +
  scale_linetype_discrete(name = "Sample") +
  theme_bw()

