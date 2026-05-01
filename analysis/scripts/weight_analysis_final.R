## weight_analysis_final.R
##
## Carcass weight analysis for Red fox - FINAL VERSION
##
## Both adult and sub-adult models use Gamma(link="log"), chosen
## because:
##   1. Weight is a continuous positive variable
##   2. Variance increases with predicted weight (confirmed by Levene
##      test on Gaussian residuals)
##   3. Gamma(log) resolves heteroscedasticity and improves AIC by
##      >100 units (adults) and >32 units (sub-adults) vs Gaussian
##
## Model structure:
##   Adults:     Weight ~ Age + Region + Sex  [Gamma, log link]
##   Sub-adults: Weight ~ Region + Sex        [Gamma, log link]
##
## Sex x Region interaction tested by AIC in both models and found
## not meaningful (delta AIC = -1.1 adults; 0.16 sub-adults under
## Gamma), so additive models are reported.
##
## Coefficients are on the log scale; back-transform with exp()
## for multiplicative effects on weight in kg.

library(data.table)
library(DHARMa)

data <- "data/raw"
jags <- "analysis/models"
out <- "analysis/output"
## -------------------------------------------------------
## 1.  LOAD & FILTER
## -------------------------------------------------------

dat <- fread(here::here(data, "work_file_NEW.csv"))

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

adults <- df[Age >= 1 & Age <= 12]
subadults <- df[Age == 0]

cat(sprintf("Adults:     n = %d\n", nrow(adults)))
cat(sprintf("Sub-adults: n = %d\n", nrow(subadults)))

## -------------------------------------------------------
## 2.  FIT FINAL GAMMA MODELS
## -------------------------------------------------------

## Adults: additive Gamma
m_ad <- glm(Weight ~ Age + Region + Sex_f,
  data   = adults,
  family = Gamma(link = "log")
)

# ## Sub-adults: additive Gamma
# m_juv <- glm(Weight ~ Region + Sex_f,
#   data   = subadults,
#   family = Gamma(link = "log")
# )


## Gamma with log link - the natural choice for weight data
m_juv_int_gamma <- glm(Weight ~ Region * Sex_f,
  data   = subadults,
  family = Gamma(link = "log")
)

## -------------------------------------------------------
## 3.  MODEL SUMMARIES
## -------------------------------------------------------

cat("\n=== ADULT MODEL (Gamma, log link) ===\n")
print(summary(m_ad)$coefficients)
cat(sprintf("\nAIC: %.1f\n", AIC(m_ad)))

## Back-transformed coefficients (multiplicative effects on weight)
cat("\nMultiplicative effects (exp of coefficients):\n")
print(round(exp(coef(m_ad)), 3))

cat("\n=== SUB-ADULT MODEL (Gamma, log link) ===\n")
print(summary(m_juv)$coefficients)
cat(sprintf("\nAIC: %.1f\n", AIC(m_juv)))

cat("\nMultiplicative effects (exp of coefficients):\n")
print(round(exp(coef(m_juv)), 3))

## -------------------------------------------------------
## 4.  DHARMA DIAGNOSTICS
## -------------------------------------------------------

cat("\n=== DHARMA DIAGNOSTICS ===\n")

sim_ad <- simulateResiduals(m_ad, n = 500, plot = FALSE)
sim_juv <- simulateResiduals(m_juv_int_gamma, n = 500, plot = FALSE)

test_ad <- testResiduals(sim_ad, plot = FALSE)
test_juv <- testResiduals(m_juv_int_gamma, plot = FALSE)

cat("\nAdults:\n")
cat(sprintf("  KS test p-value:         %.3f\n", test_ad$uniformity$p.value))
cat(sprintf("  Dispersion test p-value: %.3f\n", test_ad$dispersion$p.value))
cat(sprintf("  Outlier test p-value:    %.3f\n", test_ad$outliers$p.value))

cat("\nSub-adults:\n")
cat(sprintf("  KS test p-value:         %.3f\n", test_juv$uniformity$p.value))
cat(sprintf("  Dispersion test p-value: %.3f\n", test_juv$dispersion$p.value))
cat(sprintf("  Outlier test p-value:    %.3f\n", test_juv$outliers$p.value))

pdf("dharma_adults_gamma.pdf", width = 10, height = 5)
plot(sim_ad, main = "Adults - Gamma(log)")
dev.off()

pdf("dharma_subadults_gamma.pdf", width = 10, height = 5)
plot(sim_juv, main = "Sub-adults - Gamma(log)")
dev.off()
cat("\nDHARMa plots saved.\n")

## -------------------------------------------------------
## 5.  PREDICTED MEANS AND SEX DIFFERENCES
## -------------------------------------------------------

regions <- c("N", "NC", "SC", "S")
sexes <- c("Male", "Female")
age_adult <- mean(adults$Age)

## Adults
pred_ad <- expand.grid(
  Region = factor(regions, levels = regions),
  Sex_f = factor(sexes, levels = sexes),
  Age = age_adult
)
pred_ad_r <- predict(m_ad, newdata = pred_ad, se.fit = TRUE)
pred_ad$fit <- exp(pred_ad_r$fit)
pred_ad$lo <- exp(pred_ad_r$fit - 1.96 * pred_ad_r$se.fit)
pred_ad$hi <- exp(pred_ad_r$fit + 1.96 * pred_ad_r$se.fit)

## Sub-adults
pred_juv <- expand.grid(
  Region = factor(regions, levels = regions),
  Sex_f = factor(sexes, levels = sexes)
)
pred_juv_r <- predict(m_juv, newdata = pred_juv, se.fit = TRUE)
pred_juv$fit <- exp(pred_juv_r$fit)
pred_juv$lo <- exp(pred_juv_r$fit - 1.96 * pred_juv_r$se.fit)
pred_juv$hi <- exp(pred_juv_r$fit + 1.96 * pred_juv_r$se.fit)

## Sex differences (kg) and ratios
cat("\nPredicted sex difference (Male - Female, kg):\n")
cat(sprintf("  %-6s  %-12s  %-12s\n", "Region", "Adults", "Sub-adults"))
for (r in regions) {
  m_a <- pred_ad$fit[pred_ad$Region == r & pred_ad$Sex_f == "Male"]
  f_a <- pred_ad$fit[pred_ad$Region == r & pred_ad$Sex_f == "Female"]
  m_j <- pred_juv$fit[pred_juv$Region == r & pred_juv$Sex_f == "Male"]
  f_j <- pred_juv$fit[pred_juv$Region == r & pred_juv$Sex_f == "Female"]
  cat(sprintf("  %-6s  %-12.3f  %-12.3f\n", r, m_a - f_a, m_j - f_j))
}

## -------------------------------------------------------
## 6.  PREDICTED MEANS PLOT
## -------------------------------------------------------

pdf("weight_predicted_gamma.pdf", width = 10, height = 5)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
cols <- c("steelblue", "tomato")
x <- 1:4
off <- 0.15

panels <- list(
  list(
    data = pred_ad,
    title = sprintf("Adults (at mean age %.1f yr)", age_adult)
  ),
  list(
    data = pred_juv,
    title = "Sub-adults"
  )
)

for (panel in panels) {
  dat_p <- panel$data
  plot(NA,
    xlim = c(0.5, 4.5), ylim = c(4.5, 8.5),
    xaxt = "n", xlab = "Region", ylab = "Predicted weight (kg)",
    main = panel$title
  )
  axis(1, at = x, labels = regions)
  abline(h = seq(5, 8, 0.5), col = "grey90")
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
cat("Predicted means plot saved to weight_predicted_gamma.pdf\n")

cat("\nDone.\n")
