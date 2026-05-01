data <- "data/raw"
jags <- "analysis/models"
out <- "analysis/output"

out_v5 <- readRDS(here("out_v5.rds"))


## -------------------------------------------------------
## 10.  SURVIVAL PLOT
## -------------------------------------------------------

pdf("survival.pdf", width = 10, height = 5)

par(mfrow = c(1, 2))
cols <- c("black", "grey25", "grey50", "grey75")
sex_names <- c("Male", "Female")
age_x <- 0:7
lines <- c("solid", "dashed", "dotted", "dotdash")

for (sx in 1:2) {
    plot(NA,
        xlim = c(0, 7), ylim = c(0.1, 1.0),
        xlab = "Age class", ylab = "Survival probability",
        main = sex_names[sx],
        xaxt = "n", cex.lab = 1.2, cex.main = 1.4
    )
    axis(1, at = c(0, 1, 2, 3, 4, 5, 6, 7), labels = c("1", "2", "3", "4", "5", "6", "7", "7+"))

    abline(h = 0.5, lty = , col = "grey81")

    for (r in 1:4) {
        i <- (r - 1) * 2 + sx
        p_mn <- out_v5$mean$p[i, ]
        p_lo <- out_v5$q2.5$p[i, ]
        p_hi <- out_v5$q97.5$p[i, ]
        lines(age_x, p_mn, col = cols[r], lty = lines[r], lwd = 2)
        points(age_x, p_mn, col = cols[r], pch = r, cex = 1.2)
        segments(age_x, p_lo, age_x, p_hi, col = cols[r], lwd = 0.8)
    }
    if (sx == 1) {
        legend("topright",
            bty = "n",
            legend = c("N", "NC", "SC", "S"),
            col = cols, pch = 1:4, lwd = 2, cex = 0.9
        )
    }
}


dev.off()
cat("Survival plot saved to survival.pdf\n")
