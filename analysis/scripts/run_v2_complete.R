## run_v2_complete.R
##
## Self-contained script:
##   1. Reads work_file_NEW.csv
##   2. Applies the same filters / recoding as StartData1.r
##   3. Builds the y matrix for modelAgeSexArea_v2.jags
##   4. Runs the model via jagsUI
##   5. Produces diagnostics and a posterior-predictive-check plot
##
## Area coding (following StartData1.r, area 1 pooled into 2):
##   2 = N   (Lappland, Norrbotten, Västerbotten)
##   3 = NC  (Jämtland, Härjedalen, Medelpad)
##   4 = SC  (Dalarna, Värmland, Hälsingland)
##   5 = S   (Gästrikland, Uppland, Närke, Sörmland, Västmanland,
##             Skåne, Blekinge, Halland, Småland, Västergötland,
##             Östergötland)
##
## In the JAGS model these are re-indexed 1:4 (area_idx).

library(data.table)
library(jagsUI)

## -------------------------------------------------------
## 1.  LOAD & FILTER
## -------------------------------------------------------

dat <- fread("work_file_NEW.csv")

## Year variable
dat[, YEAR := fifelse(Y > 50, Y + 1900, Y + 2000)]

## Area assignment (matches StartData1.r)
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

## Restrict: years 1967-1971, age >= 0, known area
df <- dat[YEAR > 1966 & YEAR < 1972 & Age >= 0 & AREA > 0]

## Pool area 1 into area 2 (sparse northern counties)
df[AREA == 1L, AREA := 2L]

## Pool ages > 8 into age class 8  (0-indexed, as in original)
df[, Age_pool := pmin(as.integer(Age), 8L)]

## Sex recode: original codes 1,3,5,7 = male; 2,4,6,8 = female
df[, Sex_rc := fifelse(Sex %in% c(1,3,5,7), 1L, 2L)]

cat(sprintf("Records after filtering: %d\n", nrow(df)))
cat("Area x Sex totals:\n")
print(with(df, table(AREA, Sex_rc)))

## -------------------------------------------------------
## 2.  BUILD COUNT MATRIX  y[G, S]
## -------------------------------------------------------
##
## Group ordering (G = 8, row order):
##   g=1: area 2, male   (N,    male)
##   g=2: area 2, female (N,    female)
##   g=3: area 3, male   (NC,   male)
##   g=4: area 3, female (NC,   female)
##   g=5: area 4, male   (SC,   male)
##   g=6: area 4, female (SC,   female)
##   g=7: area 5, male   (S,    male)
##   g=8: area 5, female (S,    female)
##
## Stage classes S = 9  (age 0 .. 8, where 8 = "8+")

area_levels <- c(2, 3, 4, 5)  # original area codes
sex_levels  <- c(1, 2)        # 1=male, 2=female
S       <- 9
regions <- length(area_levels)
sexes   <- length(sex_levels)
G       <- regions * sexes

y      <- matrix(0L,      nrow = G, ncol = S)
area   <- integer(G)     # area index 1:4 for JAGS
sex_v  <- integer(G)     # 0=male 1=female for JAGS

g <- 0
for (r in seq_along(area_levels)) {
  for (sx in seq_along(sex_levels)) {
    g <- g + 1
    area[g]  <- r                  # re-indexed 1:4 for JAGS
    sex_v[g] <- sex_levels[sx] - 1 # 0=male, 1=female

    sub <- df[AREA == area_levels[r] & Sex_rc == sex_levels[sx]]
    for (s in 1:S) {
      y[g, s] <- sum(sub$Age_pool == (s - 1))  # age class s-1
    }
  }
}

N <- rowSums(y)

cat("\nCount matrix y[G, S]  (rows=groups, cols=age classes 0..8):\n")
rownames(y) <- paste0(rep(c("N","NC","SC","S"), each=2),
                      "_", rep(c("M","F"), times=4))
print(y)
cat("\nGroup totals N:\n"); print(N)

## -------------------------------------------------------
## 3.  JAGS DATA LIST
## -------------------------------------------------------

## C_zeros must exceed max(-dm_ll); 1e4 is safe for these data sizes
C_zeros    <- 1e4
zeros_data <- rep(0, G)

jags_data <- list(
  y        = y,
  N        = N,
  S        = S,
  G        = G,
  sex      = sex_v,
  area     = area,
  zeros    = zeros_data,
  C_zeros  = C_zeros
)

## -------------------------------------------------------
## 4.  INITIAL VALUES
## -------------------------------------------------------

inits <- function() {
  list(
    b_intercept = 0,
    b_sex       = 0,
    b_region    = c(NA, 0, 0, 0),          # NA = reference (fixed in model)
    b_age       = c(NA, 0, rep(0, S - 2)), # NA = age[1] fixed at 0
    tau_age     = 1,
    log_phi     = 3,
    lambda      = c(1.0, 1.0, 1.0, 1.0)
  )
}

## -------------------------------------------------------
## 5.  PARAMETERS TO MONITOR
## -------------------------------------------------------

params <- c(
  "b_intercept", "b_sex", "b_region", "b_age",
  "sigma_age", "lambda", "phi",
  "p", "C",
  "bp", "cs_obs", "cs_new"
)

## -------------------------------------------------------
## 6.  RUN MODEL
## -------------------------------------------------------

cat("\nRunning modelAgeSexArea_v2.jags ...\n")
out_v2 <- jags(
  data               = jags_data,
  inits              = inits,
  parameters.to.save = params,
  model.file         = "modelAgeSexArea_v2.jags",
  n.chains           = 3,
  n.iter             = 30000,
  n.burnin           = 10000,
  n.thin             = 2,
  parallel           = TRUE
)

## -------------------------------------------------------
## 7.  DIAGNOSTICS
## -------------------------------------------------------

## Convergence
rhat_vec  <- unlist(out_v2$Rhat)
high_rhat <- which(rhat_vec > 1.05)
if (length(high_rhat) > 0) {
  cat("\nWARNING: Parameters with Rhat > 1.05:\n")
  print(sort(rhat_vec[high_rhat], decreasing = TRUE))
} else {
  cat("\nConvergence OK: all Rhat < 1.05\n")
}

## Bayesian p-value
bp_mean <- out_v2$mean$bp
cat(sprintf("\nBayesian p-value: %.3f\n", bp_mean))
cat("  Ideal: 0.4-0.6 | Original model: 0.712\n")

## Overdispersion
cat(sprintf("\nphi (DM concentration): %.1f  95%% CrI [%.1f, %.1f]\n",
    out_v2$mean$phi, out_v2$q2.5$phi, out_v2$q97.5$phi))
cat("  phi >> 1 -> overdispersion present\n")
cat("  phi > 500 -> negligible extra-multinomial variation\n")

## Region-specific lambda
region_names <- c("N", "NC", "SC", "S")
cat("\nRegion-specific lambda (population growth rates):\n")
lambda_df <- data.frame(
  Region = region_names,
  Mean   = round(out_v2$mean$lambda,  3),
  Lower  = round(out_v2$q2.5$lambda,  3),
  Upper  = round(out_v2$q97.5$lambda, 3)
)
print(lambda_df)

## RW2 smoothing
cat(sprintf("\nRW2 sigma_age: %.3f  95%% CrI [%.3f, %.3f]\n",
    out_v2$mean$sigma_age,
    out_v2$q2.5$sigma_age,
    out_v2$q97.5$sigma_age))
cat("  Large sigma -> flexible; small sigma -> smoother age curve\n")

## Survival probability summary
cat("\nPosterior mean survival p[group, age]:\n")
p_mat <- round(out_v2$mean$p, 3)
rownames(p_mat) <- rownames(y)
colnames(p_mat) <- paste0("age", 0:8)
print(p_mat)

## -------------------------------------------------------
## 8.  POSTERIOR PREDICTIVE CHECK PLOT
## -------------------------------------------------------

pdf("ppc_plot_v2.pdf", width = 6, height = 6)
plot(out_v2$sims.list$cs_obs, out_v2$sims.list$cs_new,
     pch = 16, cex = 0.3, col = rgb(0, 0, 0, 0.1),
     xlab = "G-statistic (observed data)",
     ylab = "G-statistic (replicated data)",
     main = sprintf("Posterior predictive check\nBayesian p = %.3f", bp_mean))
abline(0, 1, col = "red", lwd = 2)
dev.off()
cat("\nPPC plot saved to ppc_plot_v2.pdf\n")

## -------------------------------------------------------
## 9.  SURVIVAL PLOT BY REGION AND SEX
## -------------------------------------------------------

sex_names   <- c("Male", "Female")

pdf("survival_v2.pdf", width = 10, height = 5)
par(mfrow = c(1, 2))
cols <- c("black", "blue", "red", "darkgreen")

for (sx in 1:2) {
  plot(NA, xlim = c(0, 8), ylim = c(0.1, 1.0),
       xlab = "Age class", ylab = "Survival probability",
       main = paste(sex_names[sx], "- v2 model"))
  abline(h = 0.5, lty = 2, col = "grey70")

  for (r in 1:4) {
    g <- (r - 1) * 2 + sx
    p_mean <- out_v2$mean$p[g, ]
    p_lo   <- out_v2$q2.5$p[g, ]
    p_hi   <- out_v2$q97.5$p[g, ]
    lines(0:8, p_mean, col = cols[r], lwd = 2)
    points(0:8, p_mean, col = cols[r], pch = r, cex = 1.2)
    segments(0:8, p_lo, 0:8, p_hi, col = cols[r], lwd = 0.8)
  }
  if (sx == 1)
    legend("topright", legend = c("N","NC","SC","S"),
           col = cols, pch = 1:4, lwd = 2, cex = 0.9)
}
dev.off()
cat("Survival plot saved to survival_v2.pdf\n")

## Save model output
saveRDS(out_v2, "out_v2.rds")
cat("\nModel output saved to out_v2.rds\n")
cat("\nDone.\n")
