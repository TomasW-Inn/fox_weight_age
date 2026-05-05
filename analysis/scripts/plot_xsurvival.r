## -------------------------------------------------------
## 10.  SURVIVAL PLOT
## -------------------------------------------------------

out_v6 <- readRDS(here(out, "out_v6.rds"))


pdf("survivalv6.pdf", width = 10, height = 5)

par(mfrow = c(1, 2))
cols <- c("black", "grey25", "grey50", "grey75")
sex_names <- c("a) males", "b) females")
age_x <- 0:7

for (sx in 1:2) {
    plot(NA,
        bty = "n",
        xlim = c(0, 7), ylim = c(0.1, 1.0),
        xlab = "Age class", ylab = "Survival probability",
        # main = sex_names[sx]
    )

    text(3, 0.95, sex_names[sx], cex = 1)
    abline(h = 0.5, lty = 2, col = "grey81")

    for (r in 1:4) {
        i <- (r - 1) * 2 + sx
        p_mn <- out_v6$mean$p[i, ]
        p_lo <- out_v6$q2.5$p[i, ]
        p_hi <- out_v6$q97.5$p[i, ]
        lines(age_x, p_mn, col = cols[r], lwd = 2)
        points(age_x, p_mn, col = cols[r], pch = r, cex = 1.2)
        segments(age_x, p_lo, age_x, p_hi, col = cols[r], lwd = 0.8)
    }
    if (sx == 1) {
        legend("topright",
            legend = c("North", "North Central", "South Central", "South"),
            col = cols, pch = 1:4, lwd = 2, cex = 0.7, bty = "n", title = "AREA"
        )
    }
}


dev.off()
cat("Survival plot saved to survival.pdf\n")
