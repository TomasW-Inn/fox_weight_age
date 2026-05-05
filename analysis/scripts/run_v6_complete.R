## run_v5_complete.R
##
## Self-contained script:
##   1. Reads work_file_NEW.csv
##   2. Filters to 1967-1971, recodes area and sex
##   3. Builds count matrix with S=8 (age 0..6 + "7+")
##   4. Runs modelAgeSexArea_v5.jags via jagsUI
##   5. Diagnostics and plots
##
## Key change from v2-v4: Dirichlet-multinomial dropped in favour
## of standard multinomial. phi >> 500 in all previous runs,
## confirming negligible overdispersion, so the multinomial is
## appropriate. This eliminates all loggam/dgamma instability.
##
## Area coding (area 1 pooled into 2):
##   1 = N   (Lp, Nb, Vb)
##   2 = NC  (Jä, Hr, Me, Ja)
##   3 = SC  (Dr, Vr, Hs)
##   4 = S   (Gä, Up, Na, Sö, So, Vs, Ga, Sk, Bl, Ha, Vg, Ög, Sm, Og)

library(data.table)
library(jagsUI)
library(here)

data <- "data/raw"
jags <- "analysis/models"
out <- "analysis/output"
## -------------------------------------------------------
## 1.  LOAD & FILTER
## -------------------------------------------------------

dat <- fread(here::here(data, "work_file_NEW.csv"))

## -------------------------------------------------------
## 1.  LOAD & FILTER
## -------------------------------------------------------


dat[, YEAR := fifelse(Y > 50, Y + 1900, Y + 2000)]

a1 <- c("Lp", "Nb", "Vb")
a2 <- c("Jä", "Hr", "Me", "Ja")
a3 <- c("Dr", "Vr", "Hs")
a4 <- c("Gä", "Up", "Na", "Sö", "So", "Vs", "Ga")
a5 <- c("Sk", "Bl", "Ha", "Vg", "Ög", "Sm", "Og")

dat[, AREA := 0L]
dat[LSkp %in% a1, AREA := 1L]
dat[LSkp %in% a2, AREA := 2L]
dat[LSkp %in% a3, AREA := 3L]
dat[LSkp %in% a4, AREA := 4L]
dat[LSkp %in% a5, AREA := 5L]
summary(dat)
with(dat, table(AREA))
df <- dat[YEAR > 1966 & YEAR < 1972 & Age >= 0 & AREA > 0]
df[AREA == 1L, AREA := 2L]
with(df, table(AREA))

## Pool ages >= 7 into "7+" terminal class -> S = 8
df[, Age_pool := pmin(as.integer(Age), 7L)]

## Sex recode: 1,3,5,7 = male; 2,4,6,8 = female
df[, Sex_rc := fifelse(Sex %in% c(1, 3, 5, 7), 1L, 2L)]

cat(sprintf("Records after filtering: %d\n", nrow(df)))
cat("Area x Sex totals:\n")
print(with(df, table(AREA, Sex_rc)))

## -------------------------------------------------------
## 2.  BUILD COUNT MATRIX  y[G, S]
## -------------------------------------------------------
##
## S = 8  (age classes 0..6 + "7+")
## G = 8  (4 regions x 2 sexes)
## Group order: N_M, N_F, NC_M, NC_F, SC_M, SC_F, S_M, S_F

area_levels <- c(2, 3, 4, 5)
sex_levels <- c(1, 2)
S <- 8
regions <- length(area_levels)
sexes <- length(sex_levels)
G <- regions * sexes

y <- matrix(0L, nrow = G, ncol = S)
area <- integer(G)
sex_v <- integer(G)

g <- 0
for (r in seq_along(area_levels)) {
  for (sx in seq_along(sex_levels)) {
    g <- g + 1
    area[g] <- r
    sex_v[g] <- sex_levels[sx] - 1 # 0=male, 1=female
    sub <- df[AREA == area_levels[r] & Sex_rc == sex_levels[sx]]
    for (s in 1:S) {
      y[g, s] <- sum(sub$Age_pool == (s - 1))
    }
  }
}

N <- rowSums(y)

group_names <- paste0(
  rep(c("N", "NC", "SC", "S"), each = 2),
  "_", rep(c("M", "F"), times = 4)
)
rownames(y) <- group_names
colnames(y) <- c(paste0("age", 0:6), "age7+")

cat("\nCount matrix y[G, S]:\n")
print(y)
cat("\nGroup totals N:\n")
print(setNames(N, group_names))

## -------------------------------------------------------
## 3.  JAGS DATA LIST
## -------------------------------------------------------

jags_data <- list(
  y    = y,
  N    = N,
  S    = S,
  G    = G,
  sex  = sex_v,
  area = area
)

## -------------------------------------------------------
## 4.  INITIAL VALUES
## -------------------------------------------------------

inits <- function() {
  list(
    b_intercept = 0,
    b_sex       = 0,
    b_region    = c(NA, 0, 0, 0),
    b_age       = c(NA, rep(0, S - 1)),
    lambda      = c(1.0, 1.0, 1.0, 1.0)
  )
}

## -------------------------------------------------------
## 5.  PARAMETERS TO MONITOR
## -------------------------------------------------------

params <- c(
  "b_intercept", "b_sex", "b_region", "b_age",
  "lambda", "p", "C",
  "bp", "cs_obs", "cs_new"
)

## -------------------------------------------------------
## 6.  RUN MODEL
## -------------------------------------------------------

cat("\nRunning modelAgeSexArea_v6.jags ...\n")
out_v6 <- jags(
  data               = jags_data,
  inits              = inits,
  parameters.to.save = params,
  model.file         = here::here(jags, "modelAgeSexArea_v6.jags"),
  n.chains           = 3,
  n.iter             = 30000,
  n.burnin           = 10000,
  n.thin             = 2,
  parallel           = TRUE
)

## -------------------------------------------------------
## 7.  DIAGNOSTICS
## -------------------------------------------------------

rhat_vec <- unlist(out_v6$Rhat)
high_rhat <- which(rhat_vec > 1.05)
if (length(high_rhat) > 0) {
  cat("\nWARNING: Parameters with Rhat > 1.05:\n")
  print(sort(rhat_vec[high_rhat], decreasing = TRUE))
} else {
  cat("\nConvergence OK: all Rhat < 1.05\n")
}

bp_mean <- out_v6$mean$bp
cat(sprintf("\nBayesian p-value: %.3f\n", bp_mean))
cat("  Ideal: 0.4-0.6 | Original model (shared lambda): 0.712\n")

region_names <- c("N", "NC", "SC", "S")
cat("\nRegion-specific lambda:\n")
print(data.frame(
  Region = region_names,
  Mean   = round(out_v6$mean$lambda, 3),
  Lower  = round(out_v6$q2.5$lambda, 3),
  Upper  = round(out_v6$q97.5$lambda, 3)
))

cat("\nPosterior mean survival p[group, age]:\n")
p_mat <- round(out_v6$mean$p, 3)
rownames(p_mat) <- group_names
colnames(p_mat) <- c(paste0("age", 0:6), "age7+")
print(p_mat)


## Quick check - raw observed proportions by age collapsed across groups
round(colSums(y) / sum(colSums(y)), 3)
## -------------------------------------------------------
## 8.  POSTERIOR PREDICTIVE CHECK PLOT
## -------------------------------------------------------

pdf("ppc_plot_v6.pdf", width = 6, height = 6)
plot(out_v6$sims.list$cs_obs, out_v6$sims.list$cs_new,
  pch = 16, cex = 0.3, col = rgb(0, 0, 0, 0.1),
  xlab = "G-statistic (observed)",
  ylab = "G-statistic (replicated)",
  main = sprintf("Posterior predictive check  |  bp = %.3f", bp_mean)
)
abline(0, 1, col = "red", lwd = 2)
dev.off()
cat("\nPPC plot saved to ppc_plot_v6.pdf\n")

## -------------------------------------------------------
## 9.  OBSERVED VS EXPECTED COUNTS
## -------------------------------------------------------

## Posterior mean expected proportions from ey/sum(ey)
theta_hat <- matrix(NA, nrow = G, ncol = S)
for (i in 1:G) {
  p_g <- out_v6$mean$p[i, ]
  w_g <- out_v6$mean$C[i, ]
  ey <- numeric(S)
  for (s in 2:(S - 1)) ey[s] <- p_g[s - 1] * w_g[s - 1]
  ey[S] <- p_g[S - 1] * w_g[S - 1] + p_g[S] * w_g[S]
  ey[1] <- out_v6$mean$lambda[area[i]] - sum(ey[2:S])
  theta_hat[i, ] <- ey / sum(ey)
}

pdf("obs_vs_exp_v6.pdf", width = 12, height = 6)
par(mfrow = c(2, 4), mar = c(3, 3, 2, 1))
age_labels <- c(paste0("a", 0:6), "7+")
for (i in 1:G) {
  expected <- N[i] * theta_hat[i, ]
  barplot(rbind(y[i, ], expected),
    beside    = TRUE,
    names.arg = age_labels,
    col       = c("steelblue", "tomato"),
    main      = group_names[i],
    cex.names = 0.7
  )
  if (i == 1) {
    legend("topright", c("Obs", "Exp"),
      fill = c("steelblue", "tomato"), cex = 0.8
    )
  }
}
dev.off()
cat("Observed vs expected plot saved to obs_vs_exp_v6.pdf\n")

## -------------------------------------------------------
## 10.  SURVIVAL PLOT
## -------------------------------------------------------

pdf("survival_v6.pdf", width = 10, height = 5)
par(mfrow = c(1, 2))
cols <- c("black", "blue", "red", "darkgreen")
sex_names <- c("Male", "Female")
age_x <- 0:7

for (sx in 1:2) {
  plot(NA,
    xlim = c(0, 7), ylim = c(0.1, 1.0),
    xlab = "Age class", ylab = "Survival probability",
    main = paste(sex_names[sx], "- v6 model")
  )
  abline(h = 0.5, lty = 2, col = "grey70")
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
      legend = c("N", "NC", "SC", "S"),
      col = cols, pch = 1:4, lwd = 2, cex = 0.9
    )
  }
}
dev.off()
cat("Survival plot saved to survival_v6.pdf\n")

saveRDS(out_v6, "out_v6.rds")
cat("\nModel output saved to out_v6.rds\n")
cat("Done.\n")

## Full parameter table for v6
params_summary <- data.frame(
  Parameter = c(
    "Intercept",
    paste0("Age ", 1:7), "Age 7+",
    "Region NC", "Region SC", "Region S",
    "Sex (female)"
  ),
  Mean = round(c(
    out_v6$mean$b_intercept,
    out_v6$mean$b_age,
    out_v6$mean$b_region[2:4],
    out_v6$mean$b_sex
  ), 3),
  Lower = round(c(
    out_v6$q2.5$b_intercept,
    out_v6$q2.5$b_age,
    out_v6$q2.5$b_region[2:4],
    out_v6$q2.5$b_sex
  ), 3),
  Upper = round(c(
    out_v6$q97.5$b_intercept,
    out_v6$q97.5$b_age,
    out_v6$q97.5$b_region[2:4],
    out_v6$q97.5$b_sex
  ), 3)
)
print(params_summary)

out_v6$mean$b_region[1:4]
print(out_v6, dec = 3)
