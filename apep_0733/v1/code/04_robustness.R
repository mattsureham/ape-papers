## 04_robustness.R — Robustness checks
## Paper: The Fortress Premium (apep_0733)

source("code/00_packages.R")

hesta <- fread("data/hesta_clean.csv")
hesta_main <- hesta[year <= 2019]

# Aggregate to canton × exposure × month
hesta_di <- hesta_main[exposure %in% c("swiss", "eurozone")]
agg <- hesta_di[, .(nights = sum(nights, na.rm = TRUE)),
  by = .(canton, canton_name, exposure, year, month, post, event_time, euro_share_2014)]
agg[, log_nights := log(pmax(nights, 1))]
agg[, ym := year * 100 + month]
agg[, ce := paste0(canton, "_", exposure)]
agg[, euro := as.integer(exposure == "eurozone")]

cat("=== ROBUSTNESS CHECKS ===\n")

# ============================================================
# R1: Placebo test — Non-European visitors (should show no effect)
# ============================================================
cat("\n--- R1: Placebo (non-European visitors) ---\n")

hesta_placebo <- hesta_main[exposure %in% c("swiss", "non_european")]
agg_placebo <- hesta_placebo[, .(nights = sum(nights, na.rm = TRUE)),
  by = .(canton, exposure, year, month, post)]
agg_placebo[, log_nights := log(pmax(nights, 1))]
agg_placebo[, ym := year * 100 + month]
agg_placebo[, ce := paste0(canton, "_", exposure)]
agg_placebo[, non_eur := as.integer(exposure == "non_european")]

r1 <- feols(log_nights ~ post:non_eur | ce + ym,
            data = agg_placebo, vcov = ~canton)
cat(sprintf("Placebo (non-European vs Swiss): %.3f (SE: %.3f, p=%.3f)\n",
    coef(r1)[1], se(r1)[1], pvalue(r1)[1]))

# ============================================================
# R2: Donut — exclude 2015 (transition year)
# ============================================================
cat("\n--- R2: Donut (exclude 2015) ---\n")

agg_donut <- agg[year != 2015]
r2 <- feols(log_nights ~ post:euro | ce + ym,
            data = agg_donut, vcov = ~canton)
cat(sprintf("Donut (excl 2015): %.3f (SE: %.3f)\n", coef(r2)[1], se(r2)[1]))

# ============================================================
# R3: Placebo shock timing — false treatment in 2012
# ============================================================
cat("\n--- R3: Placebo timing (fake shock 2012) ---\n")

agg_pre <- agg[year <= 2014]
agg_pre[, fake_post := as.integer(year >= 2012)]
r3 <- feols(log_nights ~ fake_post:euro | ce + ym,
            data = agg_pre, vcov = ~canton)
cat(sprintf("Placebo timing (2012): %.3f (SE: %.3f, p=%.3f)\n",
    coef(r3)[1], se(r3)[1], pvalue(r3)[1]))

# ============================================================
# R4: Non-euro European visitors (partial treatment)
# ============================================================
cat("\n--- R4: Non-euro Europeans (GBP, SEK, etc.) ---\n")

hesta_nee <- hesta_main[exposure %in% c("swiss", "non_euro_europe")]
agg_nee <- hesta_nee[, .(nights = sum(nights, na.rm = TRUE)),
  by = .(canton, exposure, year, month, post)]
agg_nee[, log_nights := log(pmax(nights, 1))]
agg_nee[, ym := year * 100 + month]
agg_nee[, ce := paste0(canton, "_", exposure)]
agg_nee[, nee := as.integer(exposure == "non_euro_europe")]

r4 <- feols(log_nights ~ post:nee | ce + ym,
            data = agg_nee, vcov = ~canton)
cat(sprintf("Non-euro Europe vs Swiss: %.3f (SE: %.3f)\n", coef(r4)[1], se(r4)[1]))

# ============================================================
# R5: Include COVID period (2005-2025) with COVID dummy
# ============================================================
cat("\n--- R5: Full sample with COVID interaction ---\n")

hesta_full_di <- hesta[year <= 2025 & exposure %in% c("swiss", "eurozone")]
agg_full <- hesta_full_di[, .(nights = sum(nights, na.rm = TRUE)),
  by = .(canton, exposure, year, month, post)]
agg_full[, log_nights := log(pmax(nights, 1))]
agg_full[, ym := year * 100 + month]
agg_full[, ce := paste0(canton, "_", exposure)]
agg_full[, euro := as.integer(exposure == "eurozone")]
agg_full[, covid := as.integer(year %in% 2020:2021)]

r5 <- feols(log_nights ~ post:euro + covid:euro | ce + ym,
            data = agg_full, vcov = ~canton)
cat(sprintf("Full sample: post×euro=%.3f (SE: %.3f), covid×euro=%.3f (SE: %.3f)\n",
    coef(r5)[1], se(r5)[1], coef(r5)[2], se(r5)[2]))

# ============================================================
# R6: Randomization inference — permute shock year
# ============================================================
cat("\n--- R6: Randomization Inference ---\n")

set.seed(42)
n_perms <- 500
beta_main <- coef(feols(log_nights ~ post:euro | ce + ym,
                        data = agg, vcov = ~canton))[1]
perm_betas <- numeric(n_perms)

for (i in seq_len(n_perms)) {
  fake_year <- sample(2007:2017, 1)
  agg[, fake_post := as.integer(year >= fake_year)]
  m_perm <- feols(log_nights ~ fake_post:euro | ce + ym,
                  data = agg, vcov = ~canton)
  perm_betas[i] <- coef(m_perm)[1]
}

ri_p <- mean(abs(perm_betas) >= abs(beta_main))
cat(sprintf("RI p-value (500 permutations): %.3f\n", ri_p))
cat(sprintf("True beta: %.3f, 5th/95th permutation: [%.3f, %.3f]\n",
    beta_main, quantile(perm_betas, 0.05), quantile(perm_betas, 0.95)))

# ============================================================
# Save all robustness results
# ============================================================
robustness <- list(
  r1_placebo_origin = r1,
  r2_donut = r2,
  r3_placebo_timing = r3,
  r4_non_euro_europe = r4,
  r5_full_covid = r5,
  ri_p = ri_p,
  ri_beta = beta_main,
  ri_perms = perm_betas
)
saveRDS(robustness, "data/robustness_results.rds")

cat("\n=== ROBUSTNESS SUMMARY ===\n")
cat(sprintf("Main effect:          %.3f***\n", beta_main))
cat(sprintf("Placebo (non-Euro):   %.3f  (should be ~0)\n", coef(r1)[1]))
cat(sprintf("Donut (excl 2015):    %.3f\n", coef(r2)[1]))
cat(sprintf("Placebo timing:       %.3f  (should be ~0)\n", coef(r3)[1]))
cat(sprintf("Non-euro Europe:      %.3f  (should be smaller)\n", coef(r4)[1]))
cat(sprintf("Full w/ COVID:        %.3f\n", coef(r5)[1]))
cat(sprintf("RI p-value:           %.3f\n", ri_p))
