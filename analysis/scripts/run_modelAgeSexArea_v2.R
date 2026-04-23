## run_modelAgeSexArea_v2.R
##
## Companion R script for modelAgeSexArea_v2.jags
## Prepares data, sets initial values, runs the model via jagsUI,
## and produces basic diagnostic output.
##
## Assumes your data object is named 'fox_data' with columns:
##   age    - integer 1:9 (9 = pooled 8+)
##   sex    - factor or integer (1=male, 2=female)
##   region - factor with levels "N", "NC", "SC", "S"
##   n      - count of foxes in that age/sex/region cell
##
## Adjust the data preparation section to match your actual
## data structure.

library(jagsUI)

## -------------------------------------------------------
## 1. DATA PREPARATION
## -------------------------------------------------------

## Region coding: N=1, NC=2, SC=3, S=4
region_levels <- c("N", "NC", "SC", "S")

## Build the count matrix y[G, S]
## G = number of groups (4 regions x 2 sexes = 8)
## S = number of stage classes (9)
S <- 9
regions <- 4
sexes   <- 2
G       <- regions * sexes

## Construct group index: rows = groups, cols = stage classes
## Group ordering: (N male, N female, NC male, NC female,
##                  SC male, SC female, S male, S female)
## Adjust this section to match your data structure

y     <- matrix(0, nrow = G, ncol = S)
area  <- integer(G)
sex_v <- integer(G)

g <- 0
for (r in 1:regions) {
  for (sx in 1:sexes) {
    g <- g + 1
    area[g]  <- r
    sex_v[g] <- sx - 1   # 0 = male, 1 = female

    ## Replace this with your actual count extraction
    ## Example: subset fox_data and fill y[g, ]
    ## sub <- fox_data[fox_data$region == region_levels[r] &
    ##                 fox_data$sex    == sx, ]
    ## for (s in 1:S) {
    ##   y[g, s] <- sum(sub$n[sub$age == s])
    ## }
  }
}

N <- rowSums(y)   # total harvest per group

## The zeros trick requires a vector of zeros and a constant
## C_zeros must exceed the maximum possible -dm_ll value.
## A conservative value of 1000 is usually sufficient;
## increase if JAGS reports negative Poisson means.
C_zeros <- 1000
zeros_data <- rep(0, G)

## Bundle data for JAGS
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
## 2. INITIAL VALUES
## -------------------------------------------------------

## Provide initial values for the three chains.
## The RW2 random walk needs reasonable starting values
## to avoid bad initial log-likelihood contributions.

inits <- function() {
  list(
    b_intercept = 0,
    b_sex       = 0,
    b_region    = c(NA, 0, 0, 0),   # NA for reference (fixed at 0)
    b_age       = c(NA, 0, rep(0, S - 2)),  # NA for b_age[1] (fixed)
    tau_age     = 1,
    log_phi     = 3,
    lambda      = c(1.0, 1.0, 1.0, 1.0)
  )
}


## -------------------------------------------------------
## 3. PARAMETERS TO MONITOR
## -------------------------------------------------------

params <- c(
  "b_intercept",
  "b_sex",
  "b_region",
  "b_age",
  "sigma_age",     # SD of RW2 increments (interpretable)
  "lambda",        # region-specific growth rates
  "phi",           # DM concentration (overdispersion)
  "p",             # survival probabilities [G, S]
  "C",             # stable stage distribution [G, S]
  "bp",            # Bayesian p-value
  "cs_obs",
  "cs_new"
)


## -------------------------------------------------------
## 4. RUN MODEL
## -------------------------------------------------------

## Start with a shorter run to check convergence,
## then extend if needed.

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
## 5. DIAGNOSTICS
## -------------------------------------------------------

## Check convergence: all Rhat should be < 1.05
rhat_vals <- out_v2$Rhat
high_rhat  <- which(unlist(rhat_vals) > 1.05)
if (length(high_rhat) > 0) {
  cat("WARNING: Parameters with Rhat > 1.05:\n")
  print(unlist(rhat_vals)[high_rhat])
} else {
  cat("Convergence OK: all Rhat < 1.05\n")
}

## Bayesian p-value
bp_mean <- out_v2$mean$bp
cat(sprintf("Bayesian p-value: %.3f\n", bp_mean))
cat("(Ideal: 0.4 - 0.6; original model: 0.712)\n")

## Overdispersion parameter
cat(sprintf("phi (DM concentration): %.1f (95%% CrI: %.1f - %.1f)\n",
    out_v2$mean$phi,
    out_v2$q2.5$phi,
    out_v2$q97.5$phi))
cat("phi >> 1 indicates overdispersion is present\n")

## Region-specific lambda
cat("\nRegion-specific lambda (population growth rates):\n")
lambda_summary <- data.frame(
  Region = c("N", "NC", "SC", "S"),
  Mean   = round(out_v2$mean$lambda, 3),
  Lower  = round(out_v2$q2.5$lambda, 3),
  Upper  = round(out_v2$q97.5$lambda, 3)
)
print(lambda_summary)

## RW2 age effect smoothness
cat(sprintf("\nRW2 sigma_age: %.3f (95%% CrI: %.3f - %.3f)\n",
    out_v2$mean$sigma_age,
    out_v2$q2.5$sigma_age,
    out_v2$q97.5$sigma_age))
cat("Large sigma_age -> more flexible age curve\n")
cat("Small sigma_age -> smoother age curve\n")


## -------------------------------------------------------
## 6. EXTRACT SURVIVAL ESTIMATES FOR PLOTTING
## -------------------------------------------------------

## Extract posterior mean survival p[group, stage]
## and reshape for plotting (mirrors Figure 2 in manuscript)

region_names <- c("North", "North Central", "South Central", "South")
sex_names    <- c("Male", "Female")

surv_df <- data.frame()
g <- 0
for (r in 1:regions) {
  for (sx in 1:sexes) {
    g <- g + 1
    surv_df <- rbind(surv_df, data.frame(
      group  = g,
      region = region_names[r],
      sex    = sex_names[sx],
      age    = 1:S,
      p_mean = out_v2$mean$p[g, ],
      p_lo   = out_v2$q2.5$p[g, ],
      p_hi   = out_v2$q97.5$p[g, ]
    ))
  }
}

## Basic plot (replace with ggplot2 as needed)
par(mfrow = c(1, 2))
for (sx in 1:sexes) {
  sub <- surv_df[surv_df$sex == sex_names[sx], ]
  plot(NA, xlim = c(0, 10), ylim = c(0.2, 0.9),
       xlab = "Age", ylab = "Survival probability",
       main = paste(sex_names[sx], "- v2 model"))
  abline(h = 0.5, lty = 2, col = "grey70")
  cols <- c("black", "blue", "red", "darkgreen")
  for (r in 1:regions) {
    sub_r <- sub[sub$region == region_names[r], ]
    lines(sub_r$age, sub_r$p_mean, col = cols[r], lwd = 2)
    points(sub_r$age, sub_r$p_mean, col = cols[r], pch = r)
  }
  if (sx == 1) legend("topright", legend = region_names,
                      col = cols, pch = 1:4, lwd = 2, cex = 0.8)
}


## -------------------------------------------------------
## 7. COMPARE WITH ORIGINAL MODEL (if available)
## -------------------------------------------------------

## If you have the original model output saved as 'out_orig',
## you can compare DIC and Bayesian p-values:
##
## cat(sprintf("Original model - DIC: %.1f, bp: %.3f\n",
##     out_orig$DIC, out_orig$mean$bp))
## cat(sprintf("Revised model  - DIC: %.1f, bp: %.3f\n",
##     out_v2$DIC, out_v2$mean$bp))


## -------------------------------------------------------
## 8. NOTES ON FURTHER DEVELOPMENT
## -------------------------------------------------------

## If the Bayesian p-value is still not close to 0.5 after
## these changes, consider:
##
## a) Year effects: pooling 1967-1971 ignores annual variation.
##    Adding a year random effect on the intercept (if you have
##    the data disaggregated by year) would absorb this.
##
## b) Sex x region interaction: allow b_region to vary by sex
##    if the latitudinal survival gradient differs between sexes.
##
## c) Age x region interaction: allow the age curve shape to
##    differ by region if northern foxes show a qualitatively
##    different senescence pattern.
##
## d) If phi from the DM model is very large (e.g. > 500),
##    overdispersion is negligible and the standard multinomial
##    was appropriate; in that case focus on the RW2 smoothing
##    and region-specific lambda as the main improvements.
