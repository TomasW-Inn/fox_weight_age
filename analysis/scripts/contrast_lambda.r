## -------------------------------------------------------
## LAMBDA: POSTERIOR COMPARISON ACROSS REGIONS
## -------------------------------------------------------

lambda_sims <- out_v5$sims.list$lambda
colnames(lambda_sims) <- c("N", "NC", "SC", "S")

## --- 1. Full posterior summaries ---
lambda_summary <- data.frame(
    Region = c("N", "NC", "SC", "S"),
    Mean   = round(apply(lambda_sims, 2, mean), 3),
    Median = round(apply(lambda_sims, 2, median), 3),
    SD     = round(apply(lambda_sims, 2, sd), 3),
    Lower  = round(apply(lambda_sims, 2, quantile, 0.025), 3),
    Upper  = round(apply(lambda_sims, 2, quantile, 0.975), 3),
    P_gt1  = round(apply(lambda_sims, 2, function(x) mean(x > 1)), 3)
)
cat("Lambda posterior summaries:\n")
print(lambda_summary)

## --- 2. Pairwise contrasts (all region combinations) ---
cat("\nPairwise contrasts (posterior mean difference, 95% CrI, P(a > b)):\n")
regions <- c("N", "NC", "SC", "S")
for (i in 1:3) {
    for (j in (i + 1):4) {
        diff <- lambda_sims[, i] - lambda_sims[, j]
        cat(sprintf(
            "  %s - %s:  mean=%.3f  95%%CrI [%.3f, %.3f]  P(%s>%s)=%.3f\n",
            regions[i], regions[j],
            mean(diff), quantile(diff, 0.025), quantile(diff, 0.975),
            regions[i], regions[j], mean(diff > 0)
        ))
    }
}

## --- 3. Probability each region has the highest lambda ---
cat("\nP(region has highest lambda):\n")
for (i in 1:4) {
    p_best <- mean(apply(lambda_sims, 1, which.max) == i)
    cat(sprintf("  %s: %.3f\n", regions[i], p_best))
}

## --- 4. Probability lambda > 1 (growing population) ---
cat("\nP(lambda > 1) per region:\n")
print(setNames(lambda_summary$P_gt1, regions))
