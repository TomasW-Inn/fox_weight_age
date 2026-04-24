## --- 1. PPC scatter plot ---
plot(out_v2$sims.list$cs_obs, out_v2$sims.list$cs_new,
    pch = 16, cex = 0.3, col = rgb(0, 0, 0, 0.1),
    xlab = "G-statistic (observed)",
    ylab = "G-statistic (replicated)",
    main = sprintf("PPC  |  Bayesian p = %.3f", out_v2$mean$bp)
)
abline(0, 1, col = "red", lwd = 2)

## --- 2. Observed vs expected counts per group ---
## Expected count = N[g] * theta[g,s]
## theta = C * p (already captured in ey in the model,
## but we can approximate from posterior mean p and C)

theta_hat <- matrix(NA, nrow = G, ncol = S)
for (g in 1:G) {
    w_g <- out_v2$mean$C[g, ] # stable stage distribution
    p_g <- out_v2$mean$p[g, ] # survival probs
    # reconstruct expected proportions (ey) from posterior means
    ey <- numeric(S)
    ey[2] <- p_g[1] * w_g[1]
    for (s in 3:S) ey[s] <- p_g[s - 1] * w_g[s - 1]
    ey[S] <- p_g[S - 1] * w_g[S - 1] + p_g[S] * w_g[S]
    ey[1] <- out_v2$mean$lambda[area[g]] - sum(ey[2:S])
    theta_hat[g, ] <- ey / sum(ey)
}

## Plot observed vs expected for each group
group_names <- rownames(y)
par(mfrow = c(2, 4), mar = c(3, 3, 2, 1))
for (g in 1:G) {
    expected <- N[g] * theta_hat[g, ]
    barplot(rbind(y[g, ], expected),
        beside = TRUE,
        names.arg = paste0("a", 0:8),
        col = c("steelblue", "tomato"),
        main = group_names[g],
        cex.names = 0.7
    )
    if (g == 1) {
        legend("topright", c("Obs", "Exp"),
            fill = c("steelblue", "tomato"), cex = 0.8
        )
    }
}
