library(data.table)
library(here)
library(ggplot2)
library(GGally)


data <- "data/raw"
jags <- "analysis/models"
out <- "analysis/output"

readRDS(out_v5, "out_v5.rds")



OutC <- fit8$mean$C

CAdMale2 <- data.table(Prop = OutC[1, ], Sex = "Male", Area = "North", Age = c(1:9))
CAdMale3 <- data.table(Prop = OutC[3, ], Sex = "Male", Area = "North Centr", Age = c(1:9))
CAdMale4 <- data.table(Prop = OutC[5, ], Sex = "Male", Area = "South Centr", Age = c(1:9))
CAdMale5 <- data.table(Prop = OutC[7, ], Sex = "Male", Area = "South", Age = c(1:9))
CAdFeMale2 <- data.table(Prop = OutC[2, ], Sex = "Female", Area = "North", Age = c(1:9))
CAdFeMale3 <- data.table(Prop = OutC[4, ], Sex = "Female", Area = "North Centr", Age = c(1:9))
CAdFeMale4 <- data.table(Prop = OutC[6, ], Sex = "Female", Area = "South Centr", Age = c(1:9))
CAdFeMale5 <- data.table(Prop = OutC[8, ], Sex = "Female", Area = "South", Age = c(1:9))
AgeD <- rbind(CAdMale2, CAdMale3, CAdMale4, CAdMale5, CAdFeMale2, CAdFeMale3, CAdFeMale4, CAdFeMale5)
head(AgeD)
fwrite(AgeD, here(data, "AgeD.csv"))

## Example
# Create data
# Grouped barplot

distM <- matrix(rep(NA, 36), nrow = 4)
distM[1, ] <- unlist(CAdMale2[, 1])
distM[2, ] <- unlist(CAdMale3[, 1])
distM[3, ] <- unlist(CAdMale4[, 1])
distM[4, ] <- unlist(CAdMale5[, 1])
colnames(distM) <- c(1:9)
rownames(distM) <- c("North", "North Centr", "South Centr", "South")
distM


distF <- matrix(rep(NA, 36), nrow = 4)
distF[1, ] <- unlist(CAdFeMale2[, 1])
distF[2, ] <- unlist(CAdFeMale3[, 1])
distF[3, ] <- unlist(CAdFeMale4[, 1])
distF[4, ] <- unlist(CAdFeMale5[, 1])
colnames(distF) <- c(1:9)
rownames(distF) <- c("North", "North Centr", "South Centr", "South")
distF


pdf(here(fig, "Age_Dist.pdf"), width = 18, height = 9)

par(mfrow = c(1, 2))

barplot(distM,
  ylim = c(0, 0.6),
  border = "black",
  font.axis = 1,
  beside = T,
  xlab = "Age class",
  ylab = "Age distribution",
  font.lab = 1,
  col = c("black", "darkgray", "lightgray", "white")
)
text(22, 0.55, "a) males")
# legend("topright",fill=c("black","darkgray", "lightgray", "white"),title="AREA", c("North", "North Central", "South Central","South"), bty="n" )

barplot(distF,
  ylim = c(0, 0.6),
  border = "black",
  font.axis = 1,
  beside = T,
  xlab = "Age class",
  # ylab="Age distribution",
  font.lab = 1,
  col = c("black", "darkgray", "lightgray", "white")
)
text(22, 0.55, "b) females")
legend("topright", fill = c("black", "darkgray", "lightgray", "white"), title = "AREA", c("North", "North Central", "South Central", "South"), bty = "n")

dev.off()


wp <- ggplot(AgeD[Sex == "Female"], aes(x = as.factor(Age), y = Prop, fill = Area)) +
  geom_bar(position = "dodge", stat = "identity") +
  scale_fill_grey()
wp2 <- wp + labs(y = "Relative proportion of population", x = "Age class") + ggtitle("Age distribubtion in females") + ylim(0, 1.1)
wpp <- ggplot(AgeD[Sex == "Male"], aes(x = as.factor(Age), y = Prop, fill = Area)) +
  geom_bar(position = "dodge", stat = "identity") +
  scale_fill_grey()
wpp2 <- wpp + labs(y = "Relative proportion of population", x = "Age class") + ggtitle("Age distribubtion in males") + ylim(0, 1.1)
figure2 <- wpp2 + wp2
ggsave(here(fig, "AgeDistributionSexArea.pdf"))


######################################## Compare #################################


dic_tab <- data.table(
  mod_name = mod_name,
  bp = round(bp, 3),
  dic = round(dic, 3)
)


tab1 <- dic_tab[order(dic, bp)]

fwrite(tab1, here(latex, "table1.csv"))


mean(unlist((Surv[c(2:7, 11:16), 1])))

mean(unlist((Surv[c(38:43, 47:52), 1])))

# 0.6005184
# 0.6490214
