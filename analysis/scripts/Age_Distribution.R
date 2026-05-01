library(data.table)
library(here)
library(ggplot2)
library(GGally)


data <- "data/raw"
jags <- "analysis/models"
out <- "analysis/output"

fit8 <- readRDS(here(out, "out_v5.rds"))



OutC <- fit8$mean$C

CAdMale2 <- data.table(Prop = OutC[1, ], Sex = "Male", Area = "North", Age = c(1:8))
CAdMale3 <- data.table(Prop = OutC[3, ], Sex = "Male", Area = "North Centr", Age = c(1:8))
CAdMale4 <- data.table(Prop = OutC[5, ], Sex = "Male", Area = "South Centr", Age = c(1:8))
CAdMale5 <- data.table(Prop = OutC[7, ], Sex = "Male", Area = "South", Age = c(1:8))
CAdFeMale2 <- data.table(Prop = OutC[2, ], Sex = "Female", Area = "North", Age = c(1:8))
CAdFeMale3 <- data.table(Prop = OutC[4, ], Sex = "Female", Area = "North Centr", Age = c(1:8))
CAdFeMale4 <- data.table(Prop = OutC[6, ], Sex = "Female", Area = "South Centr", Age = c(1:8))
CAdFeMale5 <- data.table(Prop = OutC[8, ], Sex = "Female", Area = "South", Age = c(1:8))
AgeD <- rbind(CAdMale2, CAdMale3, CAdMale4, CAdMale5, CAdFeMale2, CAdFeMale3, CAdFeMale4, CAdFeMale5)
head(AgeD)
fwrite(AgeD, here(out, "AgeD.csv"))

## Example
# Create data
# Grouped barplot

distM <- matrix(rep(NA, 32), nrow = 4)
distM[1, ] <- unlist(CAdMale2[, 1])
distM[2, ] <- unlist(CAdMale3[, 1])
distM[3, ] <- unlist(CAdMale4[, 1])
distM[4, ] <- unlist(CAdMale5[, 1])
colnames(distM) <- c(1:8)
rownames(distM) <- c("North", "North Centr", "South Centr", "South")
distM


distF <- matrix(rep(NA, 32), nrow = 4)
distF[1, ] <- unlist(CAdFeMale2[, 1])
distF[2, ] <- unlist(CAdFeMale3[, 1])
distF[3, ] <- unlist(CAdFeMale4[, 1])
distF[4, ] <- unlist(CAdFeMale5[, 1])
colnames(distF) <- c(1:8)
rownames(distF) <- c("North", "North Centr", "South Centr", "South")
distF


pdf(here(out, "Age_Dist.pdf"), width = 18, height = 9)

par(mfrow = c(1, 2))

barplot(distM,
  ylim = c(0, 1),
  border = "black",
  font.axis = 1,
  beside = T,
  xlab = "Age class",
  ylab = "Age distribution",
  font.lab = 1,
  col = c("black", "darkgray", "lightgray", "white"),
    names.arg=c("1", "2", "3", "4", "5", "6", "7", "7+")
)
text(22, 0.95, "a) males")
# legend("topright",fill=c("black","darkgray", "lightgray", "white"),title="AREA", c("North", "North Central", "South Central","South"), bty="n" )
# legend(12,0.9,fill=c("black","darkgray", "lightgray", "white"),title="Region", c("North", "North Central", "South Central","South"), bty="n" )

barplot(distF,
  ylim = c(0, 1),
  border = "black",
  font.axis = 1,
  beside = T,
  xlab = "Age class",
  # ylab="Age distribution",
  font.lab = 1,
  col = c("black", "darkgray", "lightgray", "white"),
  names.arg=c("1", "2", "3", "4", "5", "6", "7", "7+")
)
text(22, 0.95, "b) females")
# legend(1,0.9,fill=c("black","darkgray", "lightgray", "white"),title="Region", c("North", "North Central", "South Central","South"), bty="n" )
legend("topright", fill = c("black", "darkgray", "lightgray", "white"), title = "AREA", c("North", "North Central", "South Central", "South"), bty = "n")


dev.off()
