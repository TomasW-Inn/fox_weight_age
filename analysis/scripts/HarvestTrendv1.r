library(data.table)
library(here)
library(ggplot2)
library(GGally)
library(readxl)

data <- "data/raw"
jags <- "analysis/models"
out <- "analysis/output"

##################################################### Använd jaktstatistik för att beräkna lambda ############

df_jakt <- fread(here(data, "Fox_Bag_2.csv"))
lan <- unique(df_jakt$Lan)
unique(df_jakt$Species)

a1 <- c("AC", "BD")
a2 <- c("Z", "Y")
a3 <- c("W", "S", "X", "U")
a4 <- c("AB", "C", "D", "T")
a5 <- c("M", "K", "N", "O", "F", "E", "N", "G", "H")

df_jakt[, AREA := 0L]
df_jakt[Lan %in% a1, AREA := 2L]
df_jakt[Lan %in% a2, AREA := 2L]
df_jakt[Lan %in% a3, AREA := 3L]
df_jakt[Lan %in% a4, AREA := 4L]
df_jakt[Lan %in% a5, AREA := 5L]
head(df_jakt)
df_jakt[AREA == 0]

library(dplyr)
Sum_jakt <- df_jakt %>%
  group_by(Year, AREA) %>%
  summarise(Numbers = sum(Bag))
head(Sum_jakt)

p <- ggplot(Sum_jakt, aes(x = Year, y = Numbers, color = factor(AREA), group = AREA)) +
  geom_line() +
  geom_point() +
  labs(
    x = "Year",
    y = "Bag",
    color = "Area"
  ) +
  theme_bw()

p
ggsave(here(out, "FoxBagByArea.pdf"))

tmp <- Sum_jakt %>% filter(AREA == 3)
a <- lm(log(Numbers) ~ Year, data = tmp)
exp(coef(a)[2])

Lambda <- numeric()
x <- 0
for (i in lan) {
  print(lan)
  x <- x + 1
  tmp <- df_jakt[Lan == i]
  Lambda <- append(Lambda, as.numeric(unlist(tmp[2:6, 4] / tmp[1:5, 4])))
}
head(Lambda)
summary(Lambda)
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
# 0.5087  0.8153  0.9900  0.9561  1.1000  1.5714

hist(Lambda)
hist(log(Lambda))
library("fitdistrplus")
plotdist(Lambda, histo = TRUE, demp = TRUE)
descdist(Lambda, boot = 1000)

# summary statistics
# min:  0.5086667   max:  1.571429
# median:  0.99
# mean:  0.9561061
# estimated sd:  0.2524159
# estimated skewness:  0.2671821
# estimated kurtosis:  2.896101


##################### ***** Load data  ******* #################

df_start1 <- fread(here(data, "work_file_NEW.csv"))
summary(df_start1)
names(df_start1)
dim(df_start1)
# 12229

## Check to pool regions
with(df_start1, table(LSkp))

# Lappland LP 380
# Norrbotten NB 46
# Västerbotten 110
# 380+46+110 = 536

# Dalarna DR 255
# Hälsingland HS 2705
# Värmland VR 1029
# 255+2705+1029 = 3989

# Jämtland JÄ 2179
# Härjedalen HR 371
# Medelpad ME 8
# 2179+371+8 = 2558

# Gästrikland GÄ 740
# Uppland UP 704
# Närke NÄ 87
# Sörmland 1379
# Västmanland 384
# 740+704+87+1379+384 = 3294


# Skåne SK 652
# Bleking Bl 63
# Halland HA 2
# Småland 3
# Västergötland VG 16
# Östergötland ÖG 274
# 652+63+2+3+16+274 = 1010

df_start1$AREA <- 0
a1 <- c("Lp", "Nb", "Vb")
a2 <- c("Jä", "Hr", "Me", "Ja")
a3 <- c("Dr", "Vr", "Hs")
a4 <- c("Gä", "Up", "Na", "Sö", "So", "Vs", "Ga")
a5 <- c("Sk", "Bl", "Ha", "Vg", "Ög", "Sm", "Og")
df_start1[, AREA := fifelse(LSkp %in% a1, 1, AREA)]
df_start1[, AREA := fifelse(LSkp %in% a2, 2, AREA)]
df_start1[, AREA := fifelse(LSkp %in% a3, 3, AREA)]
df_start1[, AREA := fifelse(LSkp %in% a4, 4, AREA)]
df_start1[, AREA := fifelse(LSkp %in% a5, 5, AREA)]

with(df_start1, table(AREA))

df_start1[, YEAR := fifelse(Y > 50, Y + 1900, Y + 2000)]
with(df_start1, table(AREA, YEAR))


with(df_start1, table(Age))
tmp <- df_start1[Age < 2]
with(tmp, table(YEAR, Age))


##################################################### Subset data 1966 - 1971 for first analysis #######
##################################################### Pool AREA 1 with AREA2 ###########################

df_restrict1 <- df_start1[(YEAR > 1966 & YEAR < 1972) & Age > -1 & AREA > 0]
summary(df_restrict1)
dim(df_restrict1)
df_restrict1[, AREA := fifelse(AREA == 1, 2, AREA)]
names(df_restrict1)
with(df_restrict1, table(Age))
ggplot(data = df_restrict1, aes(x = Age)) +
  geom_bar()
flexplot(Age ~ 1, data = df_restrict1)
ggsave(here(fig, "AgeDist6771.pdf"))

with(df_restrict1, table(AREA, Age))
df_restrict1$AREA <- as.factor(df_restrict1$AREA)
flexplot(Age ~ 1 | AREA, data = df_restrict1)
ggsave(here(fig, "AgeDist6771AREA.pdf"))
# Pool age >8 with 8
df_restrict1[, Age := fifelse(Age > 8, 8, Age)]

df_restrict1[, Sex := fifelse(Sex == 3, 1, Sex)]
df_restrict1[, Sex := fifelse(Sex == 4, 2, Sex)]
df_restrict1[, Sex := fifelse(Sex == 5, 1, Sex)]
df_restrict1[, Sex := fifelse(Sex == 6, 2, Sex)]
df_restrict1[, Sex := fifelse(Sex == 7, 1, Sex)]
df_restrict1[, Sex := fifelse(Sex == 8, 2, Sex)]

## save data
# fwrite(df_restrict1, here(data, "df_restrict1.csv"))

with(df_restrict1, table(AREA, Sex))
with(df_restrict1, table(Sex, Age))
#     Sex
# AREA    1    2
#    2 1461 1128
#    3  553  437
#    4  929  809
#    5  374  289

################################################# First run with intercept only, all data  #########
df_restrict1 <- fread(here(data, "df_restrict1.csv"))
Numbers <- with(df_restrict1, table(Sex, Age))
y2 <- matrix(Numbers, ncol = ncol(Numbers))

library(jagsUI)
library(MCMCvis)
################################################## Interceept only ###################
dInt <- list(
  K = 1, # number of parameters
  G = nrow(y2), # number of groups
  S = ncol(y2), # number of stage classes
  y = y2, # age-at-harvest data matrix
  N = apply(y2, 1, sum) # number harvested by group
)

params <- c("lambda", "p", "w", "b", "bp")

intcpt <- autojags(dInt,
  parameters.to.save = params, model.file = here(script, "InterceptOnly.jags"),
  n.chains = 3, iter.increment = 10000, n.burnin = 1000,
  save.all.iter = T
)

print(intcpt, dec = 3)
# deviance 289.009
# bp 0.000

############### All data separated by age ###########################################################


dAge <- list(
  K = 9 - 1, # number of parameters
  G = nrow(y2), # number of groups
  S = ncol(y2), # number of stage classes
  y = y2, # age-at-harvest data matrix
  N = apply(y2, 1, sum) # number harvested by group
)

mAge <- autojags(dAge,
  parameters.to.save = params, model.file = here(script, "modelAge.jags"),
  n.chains = 3, iter.increment = 10000, n.burnin = 1000,
  save.all.iter = T
)
print(mAge, dec = 3)
# (deviance 149.354)
# (bp         0.000)

############### All data separated by sex, age ###########################################################
params <- c("lambda", "p", "w", "b", "bp", "cs_obs", "cs_new")
sex <- c(0, 1)
dSexAge <- list(
  K = 9 - 1 + 2 - 1, # number of parameters
  G = nrow(y2), # number of groups
  sex = sex,
  S = ncol(y2), # number of stage classes
  y = y2, # age-at-harvest data matrix
  N = apply(y2, 1, sum) # number harvested by group
)

mSexAge <- autojags(dSexAge,
  parameters.to.save = params, model.file = here(script, "modelSexAge.jags"),
  n.chains = 3, iter.increment = 10000, n.burnin = 1000,
  save.all.iter = T
)
print(mSexAge, dec = 3)
# (deviance 117.172)
# (bp         0.407)
pdf(here(fig, "testmSeaAgeAll.pdf"))
plot(mSexAge$sims.list$cs_obs, mSexAge$sims.list$cs_new)
abline(0, 1)
dev.off()

pdf(here(fig, "mSexAgeparameters.pdf"))
MCMCplot(mSexAge, params = c("b"), rank = TRUE, horiz = FALSE)
dev.off()

mSexAge$mean$p[1, ]
mSexAgeOUT <- MCMCsummary(mSexAge, params = "p", Rhat = FALSE, n.eff = FALSE, HPD = TRUE, hpd_prob = 0.8, round = 3)
head(mSexAgeOUT)
colnames(mSexAgeOUT) <- c("mean", "sd", "HPDL", "HPDU")
mSexAgeOUT$Age <- c(0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8)
mSexAgeOUT$Sex <- as.factor(c(0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1))

## Plot population time series
pd <- position_dodge(0.1)
PmSexAgeOUT <- ggplot(mSexAgeOUT, aes(x = Age, y = mean, color = Sex)) +
  geom_point() +
  geom_smooth(se = FALSE)
ggsave(here(fig, "PmSexAgeOUt.pdf"))


################################

names(df_restrict1)
with(df_restrict1, table(Age))
df_restrict1[, Age2 := fifelse(Age > 0, 1, 0)]
boxplot(Vikt1 ~ AREA, data = df_restrict1)
flexplot(Vikt1 ~ AREA, data = df_restrict1)
flexplot((Vikt1 / 10) ~ AREA | Sex, data = df_restrict1)
ggsave(here(fig, "WeightAreaSex.pdf"))
m0 <- lm((Vikt1 / 10) ~ as.factor(AREA) + as.factor(Sex), data = df_restrict1[Age2 == 1])
summary(m0)
m1 <- glm((Vikt1 / 10) ~ as.factor(AREA) + as.factor(Sex), data = df_restrict1[Age2 == 1])
summary(m1)
library(stargazer)
stargazer(m1)

m2 <- glm((Vikt1 / 10) ~ as.factor(AREA) + as.factor(Sex), data = df_restrict1[Age2 == 0])
summary(m2)
library(stargazer)
stargazer(m2)


df_plot <- df_restrict1[(!is.na(Vikt1) & !is.na(Sex) & Age2 == 1)]
df_plot$Vikt1 <- df_plot$Vikt1 / 10

df_plot$Sex <- factor(df_plot$Sex,
  levels = c(1, 2),
  labels = c("Males", "Females")
)
df_plot$AREA <- factor(df_plot$AREA,
  levels = c(2, 3, 4, 5),
  labels = c("N", "NC", "SC", "S")
)

p1 <- ggplot(df_plot, aes(x = as.factor(AREA), y = Vikt1)) +
  geom_violin() +
  facet_wrap(~ as.factor(Sex)) +
  geom_jitter(shape = 21, fill = "lightgray", color = "gray", size = 1, position = position_jitter(0.2)) +
  stat_summary(fun.data = mean_sdl, fun.args = list(mult = 1), geom = "pointrange", color = "red") +
  labs(y = "Weight (kg)", x = "Area")

p1
#  One standard deviation
ggsave(here(fig, "AdWeightAreaSexFinal.pdf"))


df_plot2 <- df_restrict1[(!is.na(Vikt1) & !is.na(Sex) & Age2 == 0)]
df_plot2$Vikt1 <- df_plot2$Vikt1 / 10

df_plot2$Sex <- factor(df_plot2$Sex,
  levels = c(1, 2),
  labels = c("Males", "Females")
)
df_plot2$AREA <- factor(df_plot2$AREA,
  levels = c(2, 3, 4, 5),
  labels = c("N", "NC", "SC", "S")
)

p2 <- ggplot(df_plot2, aes(x = as.factor(AREA), y = Vikt1)) +
  geom_violin() +
  facet_wrap(~ as.factor(Sex)) +
  geom_jitter(shape = 21, fill = "lightgray", color = "gray", size = 1, position = position_jitter(0.2)) +
  stat_summary(fun.data = mean_sdl, fun.args = list(mult = 1), geom = "pointrange", color = "red") +
  labs(y = "Weight (kg)", x = "Area")

p2
#  One standard deviation
ggsave(here(fig, "JuvWeightAreaSexFinal.pdf"))
