## weight_analysis.R
##
## Carcass weight analysis for Red fox with sex x region interaction
## Separate models for adults (age >= 1) and sub-adults (age == 0)
##
## For each age class:
##   Model 1 (additive):    weight ~ age* + region + sex
##   Model 2 (interaction): weight ~ age* + region * sex
##   (* age only in adult model)
##
## Models compared by AIC. If interaction model is preferred
## (delta AIC > 2), report interaction coefficients and plot
## region-specific sex differences.

library(data.table)
library(DHARMa)

data <- "data/raw"
jags <- "analysis/models"
out <- "analysis/output"
## -------------------------------------------------------
## 1.  LOAD & FILTER
## -------------------------------------------------------

dat <- fread(here::here(data, "work_file_NEW.csv"))

## -------------------------------------------------------
## 1.  LOAD & PREPARE DATA
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

df <- dat[YEAR > 1966 & YEAR < 1972 & Age >= 0 & AREA > 0 & !is.na(Vikt1)]
df[AREA == 1L, AREA := 2L]

## Recode
df[, Region := factor(fcase(
  AREA == 2, "N",
  AREA == 3, "NC",
  AREA == 4, "SC",
  AREA == 5, "S"
), levels = c("N", "NC", "SC", "S"))]

df[, Sex_f := factor(fifelse(Sex %in% c(1, 3, 5, 7), "Male", "Female"),
  levels = c("Male", "Female")
)]

df[, Weight := Vikt1 / 10] # hectograms -> kg

## Split adults (age >= 1) and sub-adults (age == 0)
adults <- df[Age >= 1 & Age <= 12]
subadults <- df[Age == 0]

cat(sprintf("Adults:    n = %d\n", nrow(adults)))
cat(sprintf("Sub-adults: n = %d\n", nrow(subadults)))

## -------------------------------------------------------
## 2.  ADULT MODELS
## -------------------------------------------------------

cat("\n=== ADULT MODELS ===\n")

## Additive
m_ad_add <- glm(Weight ~ Age + Region + Sex_f,
  data   = adults,
  family = gaussian(link = "identity")
)

## Interaction
m_ad_int <- glm(Weight ~ Age + Region * Sex_f,
  data   = adults,
  family = gaussian(link = "identity")
)

cat("\nAdult AIC comparison:\n")
cat(sprintf("  Additive:    AIC = %.1f\n", AIC(m_ad_add)))
cat(sprintf("  Interaction: AIC = %.1f\n", AIC(m_ad_int)))
cat(sprintf("  Delta AIC (add - int) = %.2f\n", AIC(m_ad_add) - AIC(m_ad_int)))

cat("\nAdult additive model summary:\n")
print(summary(m_ad_add)$coefficients)

if (AIC(m_ad_add) - AIC(m_ad_int) > 2) {
  cat("\nInteraction model preferred (delta AIC > 2):\n")
  print(summary(m_ad_int)$coefficients)
} else {
  cat("\nAdditive model adequate (delta AIC <= 2) - no meaningful interaction\n")
}

## DHARMa diagnostics
cat("\nDHARMa diagnostics - adult additive model:\n")
sim_ad <- simulateResiduals(m_ad_add, n = 500, plot = FALSE)
test_ad <- testResiduals(sim_ad, plot = FALSE)
cat(sprintf("  KS test p-value:         %.3f\n", test_ad$uniformity$p.value))
cat(sprintf("  Dispersion test p-value: %.3f\n", test_ad$dispersion$p.value))
cat(sprintf("  Outlier test p-value:    %.3f\n", test_ad$outliers$p.value))

## -------------------------------------------------------
## 3.  SUB-ADULT MODELS
## -------------------------------------------------------

cat("\n=== SUB-ADULT MODELS ===\n")

m_juv_add <- glm(Weight ~ Region + Sex_f,
  data   = subadults,
  family = gaussian(link = "identity")
)

m_juv_int <- glm(Weight ~ Region * Sex_f,
  data   = subadults,
  family = gaussian(link = "identity")
)

cat("\nSub-adult AIC comparison:\n")
cat(sprintf("  Additive:    AIC = %.1f\n", AIC(m_juv_add)))
cat(sprintf("  Interaction: AIC = %.1f\n", AIC(m_juv_int)))
cat(sprintf("  Delta AIC (add - int) = %.2f\n", AIC(m_juv_add) - AIC(m_juv_int)))

cat("\nSub-adult additive model summary:\n")
print(summary(m_juv_add)$coefficients)

if (AIC(m_juv_add) - AIC(m_juv_int) > 2) {
  cat("\nInteraction model preferred (delta AIC > 2):\n")
  print(summary(m_juv_int)$coefficients)
} else {
  cat("\nAdditive model adequate (delta AIC <= 2) - no meaningful interaction\n")
}

## DHARMa diagnostics
cat("\nDHARMa diagnostics - sub-adult additive model:\n")
sim_juv <- simulateResiduals(m_juv_add, n = 500, plot = FALSE)
test_juv <- testResiduals(sim_juv, plot = FALSE)
cat(sprintf("  KS test p-value:         %.3f\n", test_juv$uniformity$p.value))
cat(sprintf("  Dispersion test p-value: %.3f\n", test_juv$dispersion$p.value))
cat(sprintf("  Outlier test p-value:    %.3f\n", test_juv$outliers$p.value))

## -------------------------------------------------------
## 4.  PREDICTED MEANS PLOT (interaction if preferred,
##     otherwise additive)
## -------------------------------------------------------

## Choose best model for each age class
best_ad <- if (AIC(m_ad_add) - AIC(m_ad_int) > 2) m_ad_int else m_ad_add
best_juv <- if (AIC(m_juv_add) - AIC(m_juv_int) > 2) m_juv_int else m_juv_add

regions <- c("N", "NC", "SC", "S")
sexes <- c("Male", "Female")
age_adult <- mean(adults$Age) # predict at mean age for adults

## Predicted means - adults
pred_ad <- expand.grid(
  Region = factor(regions, levels = regions),
  Sex_f = factor(sexes, levels = sexes),
  Age = age_adult
)
pred_ad$fit <- predict(best_ad, newdata = pred_ad)
pred_ad_se <- predict(best_ad, newdata = pred_ad, se.fit = TRUE)
pred_ad$lo <- pred_ad_se$fit - 1.96 * pred_ad_se$se.fit
pred_ad$hi <- pred_ad_se$fit + 1.96 * pred_ad_se$se.fit

## Predicted means - sub-adults
pred_juv <- expand.grid(
  Region = factor(regions, levels = regions),
  Sex_f = factor(sexes, levels = sexes)
)
pred_juv$fit <- predict(best_juv, newdata = pred_juv)
pred_juv_se <- predict(best_juv, newdata = pred_juv, se.fit = TRUE)
pred_juv$lo <- pred_juv_se$fit - 1.96 * pred_juv_se$se.fit
pred_juv$hi <- pred_juv_se$fit + 1.96 * pred_juv_se$se.fit

pdf("weight_interaction_plot.pdf", width = 10, height = 5)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
cols <- c("steelblue", "tomato") # male, female
x <- 1:4
off <- 0.15

for (panel in 1:2) {
  dat_p <- if (panel == 1) pred_ad else pred_juv
  title <- if (panel == 1) sprintf("Adults (at mean age %.1f yr)", age_adult) else "Sub-adults"

  plot(NA,
    xlim = c(0.5, 4.5), ylim = c(4.5, 8.5),
    xaxt = "n", xlab = "Region", ylab = "Predicted weight (kg)",
    main = title
  )
  axis(1, at = x, labels = regions)
  abline(h = seq(5, 8, 0.5), col = "grey90", lty = 1)

  for (si in 1:2) {
    sub <- dat_p[dat_p$Sex_f == sexes[si], ]
    xpos <- x + (si - 1.5) * off
    points(xpos, sub$fit, col = cols[si], pch = 16, cex = 1.3)
    segments(xpos, sub$lo, xpos, sub$hi, col = cols[si], lwd = 1.5)
    lines(xpos, sub$fit, col = cols[si], lty = si, lwd = 1.2)
  }
  legend("topleft",
    legend = sexes, col = cols,
    pch = 16, lty = 1:2, lwd = 1.5, bty = "n", cex = 0.9
  )
}
dev.off()
cat("\nPredicted means plot saved to weight_interaction_plot.pdf\n")

## -------------------------------------------------------
## 5.  PRINT PREDICTED SEX DIFFERENCES PER REGION
## -------------------------------------------------------

cat("\nPredicted sex difference (Male - Female) per region:\n")
cat("  Adults (at mean age):\n")
for (r in regions) {
  m <- pred_ad$fit[pred_ad$Region == r & pred_ad$Sex_f == "Male"]
  f <- pred_ad$fit[pred_ad$Region == r & pred_ad$Sex_f == "Female"]
  cat(sprintf("    %s: %.3f kg\n", r, m - f))
}
cat("  Sub-adults:\n")
for (r in regions) {
  m <- pred_juv$fit[pred_juv$Region == r & pred_juv$Sex_f == "Male"]
  f <- pred_juv$fit[pred_juv$Region == r & pred_juv$Sex_f == "Female"]
  cat(sprintf("    %s: %.3f kg\n", r, m - f))
}

cat("\nDone.\n")

par(mfrow = c(1, 1), mar = c(5.1, 4.1, 4.1, 2.1))
plot(simulateResiduals(m_juv_int))


## -------------------------------------------------------
## 6.  REFIT SUB-ADULT INTERACTION MODEL WITH LOG LINK
##     to address heteroscedasticity
## -------------------------------------------------------

cat("\n=== SUB-ADULT INTERACTION MODEL - LOG LINK ===\n")

m_juv_int_log <- glm(Weight ~ Region * Sex_f,
  data   = subadults,
  family = gaussian(link = "log")
)

cat("\nSub-adult interaction model (log link) summary:\n")
print(summary(m_juv_int_log)$coefficients)

cat(sprintf("\nAIC comparison (interaction models):\n"))
cat(sprintf("  Identity link: AIC = %.1f\n", AIC(m_juv_int)))
cat(sprintf("  Log link:      AIC = %.1f\n", AIC(m_juv_int_log)))

## DHARMa diagnostics on log-link model
cat("\nDHARMa diagnostics - sub-adult interaction model (log link):\n")
sim_juv_log <- simulateResiduals(m_juv_int_log, n = 500, plot = FALSE)
test_juv_log <- testResiduals(sim_juv_log, plot = FALSE)
cat(sprintf("  KS test p-value:         %.3f\n", test_juv_log$uniformity$p.value))
cat(sprintf("  Dispersion test p-value: %.3f\n", test_juv_log$dispersion$p.value))
cat(sprintf("  Outlier test p-value:    %.3f\n", test_juv_log$outliers$p.value))

## Full DHARMa plot for visual inspection
pdf("dharma_juv_log.pdf", width = 10, height = 5)
plot(sim_juv_log, main = "Sub-adult interaction model - log link")
dev.off()
cat("DHARMa plot saved to dharma_juv_log.pdf\n")

## Predicted means on original kg scale (back-transformed)
pred_juv_log <- expand.grid(
  Region = factor(regions, levels = regions),
  Sex_f = factor(sexes, levels = sexes)
)
pred_raw <- predict(m_juv_int_log,
  newdata = pred_juv_log,
  se.fit = TRUE
)
pred_juv_log$fit <- exp(pred_raw$fit)
pred_juv_log$lo <- exp(pred_raw$fit - 1.96 * pred_raw$se.fit)
pred_juv_log$hi <- exp(pred_raw$fit + 1.96 * pred_raw$se.fit)

## Sex differences on kg scale per region
cat("\nPredicted sex difference (Male - Female, kg) per region - log link model:\n")
for (r in regions) {
  m <- pred_juv_log$fit[pred_juv_log$Region == r & pred_juv_log$Sex_f == "Male"]
  f <- pred_juv_log$fit[pred_juv_log$Region == r & pred_juv_log$Sex_f == "Female"]
  cat(sprintf("  %s: %.3f kg\n", r, m - f))
}

## Sex ratio (Male/Female) per region - natural output of log-link model
cat("\nMale/Female weight ratio per region - log link model:\n")
for (r in regions) {
  m <- pred_juv_log$fit[pred_juv_log$Region == r & pred_juv_log$Sex_f == "Male"]
  f <- pred_juv_log$fit[pred_juv_log$Region == r & pred_juv_log$Sex_f == "Female"]
  cat(sprintf("  %s: %.3f\n", r, m / f))
}

## Updated interaction plot comparing identity vs log link
pdf("weight_interaction_log.pdf", width = 10, height = 5)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
cols <- c("steelblue", "tomato")
x <- 1:4
off <- 0.15

## Left panel: identity link (original)
plot(NA,
  xlim = c(0.5, 4.5), ylim = c(4.5, 8.5),
  xaxt = "n", xlab = "Region", ylab = "Predicted weight (kg)",
  main = "Sub-adults - identity link"
)
axis(1, at = x, labels = regions)
abline(h = seq(5, 8, 0.5), col = "grey90")
for (si in 1:2) {
  sub <- pred_juv[pred_juv$Sex_f == sexes[si], ]
  xpos <- x + (si - 1.5) * off
  points(xpos, sub$fit, col = cols[si], pch = 16, cex = 1.3)
  segments(xpos, sub$lo, xpos, sub$hi, col = cols[si], lwd = 1.5)
  lines(xpos, sub$fit, col = cols[si], lty = si, lwd = 1.2)
}
legend("topleft",
  legend = sexes, col = cols,
  pch = 16, lty = 1:2, lwd = 1.5, bty = "n", cex = 0.9
)

## Right panel: log link
plot(NA,
  xlim = c(0.5, 4.5), ylim = c(4.5, 8.5),
  xaxt = "n", xlab = "Region", ylab = "Predicted weight (kg)",
  main = "Sub-adults - log link"
)
axis(1, at = x, labels = regions)
abline(h = seq(5, 8, 0.5), col = "grey90")
for (si in 1:2) {
  sub <- pred_juv_log[pred_juv_log$Sex_f == sexes[si], ]
  xpos <- x + (si - 1.5) * off
  points(xpos, sub$fit, col = cols[si], pch = 16, cex = 1.3)
  segments(xpos, sub$lo, xpos, sub$hi, col = cols[si], lwd = 1.5)
  lines(xpos, sub$fit, col = cols[si], lty = si, lwd = 1.2)
}
legend("topleft",
  legend = sexes, col = cols,
  pch = 16, lty = 1:2, lwd = 1.5, bty = "n", cex = 0.9
)
dev.off()
cat("Comparison plot saved to weight_interaction_log.pdf\n")

cat("\nDone.\n")

## ===================================================================
# Gamma distribution for both adults and young
# ===================================================================

m_ad_add_gamma <- glm(Weight ~ Age + Region + Sex_f,
  data   = adults,
  family = Gamma(link = "log")
)

sim_ad_gamma <- simulateResiduals(m_ad_add_gamma, n = 500, plot = FALSE)
test_ad_gamma <- testResiduals(sim_ad_gamma, plot = FALSE)
cat(sprintf("  KS:         %.3f\n", test_ad_gamma$uniformity$p.value))
cat(sprintf("  Dispersion: %.3f\n", test_ad_gamma$dispersion$p.value))
cat(sprintf("  Outliers:   %.3f\n", test_ad_gamma$outliers$p.value))

pdf("dharma_ad_gamma.pdf", width = 10, height = 5)
plot(sim_ad_gamma)
dev.off()

cat(sprintf("\nAIC - Gaussian: %.1f\n", AIC(m_ad_add)))
cat(sprintf("AIC - Gamma:    %.1f\n", AIC(m_ad_add_gamma)))

print(summary(m_ad_add_gamma)$coefficients)

## Gamma with log link - the natural choice for weight data
m_juv_int_gamma <- glm(Weight ~ Region * Sex_f,
  data   = subadults,
  family = Gamma(link = "log")
)

## Check diagnostics
sim_gamma <- simulateResiduals(m_juv_int_gamma, n = 500, plot = FALSE)
test_gamma <- testResiduals(sim_gamma, plot = FALSE)
cat(sprintf("  KS test p-value:         %.3f\n", test_gamma$uniformity$p.value))
cat(sprintf("  Dispersion test p-value: %.3f\n", test_gamma$dispersion$p.value))
cat(sprintf("  Outlier test p-value:    %.3f\n", test_gamma$outliers$p.value))

## Save DHARMa plot
pdf("dharma_juv_gamma.pdf", width = 10, height = 5)
plot(sim_gamma)
dev.off()

## Compare AIC with Gaussian
cat(sprintf("\nAIC - Gaussian identity: %.1f\n", AIC(m_juv_int)))
cat(sprintf("AIC - Gamma log:         %.1f\n", AIC(m_juv_int_gamma)))

## Summary
print(summary(m_juv_int_gamma)$coefficients)

## Additive Gamma for sub-adults
m_juv_add_gamma <- glm(Weight ~ Region + Sex_f,
  data   = subadults,
  family = Gamma(link = "log")
)

cat(sprintf("AIC - Gamma additive:    %.1f\n", AIC(m_juv_add_gamma)))
cat(sprintf("AIC - Gamma interaction: %.1f\n", AIC(m_juv_int_gamma)))
cat(sprintf("Delta AIC: %.2f\n", AIC(m_juv_add_gamma) - AIC(m_juv_int_gamma)))
