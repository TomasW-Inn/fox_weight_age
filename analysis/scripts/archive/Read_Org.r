library(data.table)
library(here)
library(flexplot)
library(ggplot2)
library(GGally)
library(readxl)

script <- "SCRIPT"
data <- "DATA"
fig <- "LATEX/figures"

df_org <- data.table(read_excel(here(data,"Kt11allt82_TW_Work3.xlsx")))

summary(df_org)
df_org2 <- df_org[Age>0]
plot(Vikt~ Krm22, data=df_org2)
plot(Vikt~ VHulnaL, data=df_org2)

names(df_org2)
pairs(df_org2[,c(19,29:39)])

## Verkar inte so om någon av skelettlängderna ger särskilt mycket mer än vikt 

Add_Cranial <- data.table(Nr=df_org2$Nr, Krm22=df_org2$Krm22)
head(Add_Cranial)
dim(Add_Cranial)
dim(df_restrict1)
summary(df_restrict1$Nr)
df_restrict2 <- merge(df_restrict1, Add_Cranial, by="Nr", all.x=TRUE)
dim(df_restrict2)


names(df_restrict2)
flexplot((Vikt1/10) ~ AREA | Sex, data = df_restrict2)
flexplot(Krm22 ~ AREA | Sex, data = df_restrict2[Age2==1])
m1b <- glm(Krm22 ~ as.factor(AREA) + as.factor(Sex), data = df_restrict2[Age2==1])
summary(m1b)
library(stargazer)
stargazer(m1)




ggsave(here(fig, "WeightAreaSex.pdf"))
m0 <- lm((Vikt1/10) ~ as.factor(AREA) + as.factor(Sex), data = df_restrict2[Age2==1])
summary(m0)
m1 <- glm((Vikt1/10) ~ as.factor(AREA) + as.factor(Sex), data = df_restrict2[Age2==1])
summary(m1)
library(stargazer)
stargazer(m1)
                                                                                          
m2 <- glm((Vikt1/10) ~ as.factor(AREA) + as.factor(Sex), data = df_restrict2[Age2==0])
summary(m2)
library(stargazer)
stargazer(m2)


###################### Pick out a few ages #####################

age2 <- ggplot(df_plot[Age==2], aes(x=as.factor(AREA), y=Vikt1)) + geom_violin() + facet_wrap(~as.factor(Sex))+ geom_jitter(shape = 21, fill = "lightgray", color = "gray", size = 1, position=position_jitter(0.2)) + stat_summary(fun.data=mean_sdl,  fun.args = list(mult=1), geom="pointrange", color="black") + labs(y= "Weight (kg)", x = "Area")+ggtitle("Two year old")+ylim(3,12)

age4 <- ggplot(df_plot[Age==4], aes(x=as.factor(AREA), y=Vikt1)) + geom_violin() + facet_wrap(~as.factor(Sex))+ geom_jitter(shape = 21, fill = "lightgray", color = "gray", size = 1, position=position_jitter(0.2)) + stat_summary(fun.data=mean_sdl,  fun.args = list(mult=1), geom="pointrange", color="black") + labs(y= "Weight (kg)", x = "Area")+ggtitle("Four year old")+ylim(3,12)
age3 <- ggplot(df_plot[Age==3], aes(x=as.factor(AREA), y=Vikt1)) + geom_violin() + facet_wrap(~as.factor(Sex))+ geom_jitter(shape = 21, fill = "lightgray", color = "gray", size = 1, position=position_jitter(0.2)) + stat_summary(fun.data=mean_sdl,  fun.args = list(mult=1), geom="pointrange", color="black") + labs(y= "Weight (kg)", x = "Area")+ggtitle("Three year old")+ylim(3,12)
age1 <- ggplot(df_plot[Age==1], aes(x=as.factor(AREA), y=Vikt1)) + geom_violin() + facet_wrap(~as.factor(Sex))+ geom_jitter(shape = 21, fill = "lightgray", color = "gray", size = 1, position=position_jitter(0.2)) + stat_summary(fun.data=mean_sdl,  fun.args = list(mult=1), geom="pointrange", color="black") + labs(y= "Weight (kg)", x = "Area")+ggtitle("One year old")+ylim(3,12)
library(patchwork)
(age1 + age2) / (age3 + age4)

ggsave(here(fig, "AGEComp_WeightAreaSex.pdf"))

mcheck <- glm((Vikt1/10) ~ Age + as.factor(AREA) + as.factor(Sex), data = df_restrict2[Age2==1])
summary(mcheck)
stargazer(mcheck)

############ The same with skull size ####################################


df_plotskull <- df_restrict2[!is.na(Sex)]
df_plotskull$Sex <- factor(df_plotskull$Sex, levels = c(1, 2),
                  labels = c("Males", "Females")
                  )
df_plotskull$AREA <- factor(df_plotskull$AREA, levels = c(2,3,4,5),
                  labels = c("N","NC", "SC", "S")
                  )

skullage2 <- ggplot(df_plotskull[Age==2], aes(x=as.factor(AREA), y=Krm22)) + geom_violin() + facet_wrap(~as.factor(Sex))+ geom_jitter(shape = 21, fill = "lightgray", color = "gray", size = 1, position=position_jitter(0.2)) + stat_summary(fun.data=mean_sdl,  fun.args = list(mult=1), geom="pointrange", color="red") + labs(y= "Length (mm)", x = "Area")+ggtitle("Two year old")

skullage4 <- ggplot(df_plotskull[Age==4], aes(x=as.factor(AREA), y=Krm22)) + geom_violin() + facet_wrap(~as.factor(Sex))+ geom_jitter(shape = 21, fill = "lightgray", color = "gray", size = 1, position=position_jitter(0.2)) + stat_summary(fun.data=mean_sdl,  fun.args = list(mult=1), geom="pointrange", color="red") + labs(y= "Length (mm)", x = "Area")+ggtitle("Four year old")
skullage3 <- ggplot(df_plotskull[Age==3], aes(x=as.factor(AREA), y=Krm22)) + geom_violin() + facet_wrap(~as.factor(Sex))+ geom_jitter(shape = 21, fill = "lightgray", color = "gray", size = 1, position=position_jitter(0.2)) + stat_summary(fun.data=mean_sdl,  fun.args = list(mult=1), geom="pointrange", color="red") + labs(y= "Length (mm)", x = "Area")+ggtitle("Three year old")
skullage1 <- ggplot(df_plotskull[Age==1], aes(x=as.factor(AREA), y=Krm22)) + geom_violin() + facet_wrap(~as.factor(Sex))+ geom_jitter(shape = 21, fill = "lightgray", color = "gray", size = 1, position=position_jitter(0.2)) + stat_summary(fun.data=mean_sdl,  fun.args = list(mult=1), geom="pointrange", color="red") + labs(y= "Length (mm)", x = "Area")+ggtitle("One year old")
library(patchwork)
(skullage1 + skullage2) / (skullage3 + skullage4)


ggsave(here(fig, "AGEComp_SkullAreaSex.pdf"))


mcheck2 <- glm(Krm22 ~ Age + as.factor(AREA) + as.factor(Sex), data = df_restrict2[Age2==1])
summary(mcheck2)
stargazer(mcheck2)

