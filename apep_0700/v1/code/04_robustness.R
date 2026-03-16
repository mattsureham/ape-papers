## 04_robustness.R — Robustness checks and placebo tests for apep_0700
## UK LHA Freeze and Homelessness

source("00_packages.R")
setwd("../data")

panel <- fread("analysis_panel.csv")
mapped <- panel[brma_name != "UNMAPPED"]
mapped[, gap_10pp := gap_pct / 10]
mapped[, high_gap := as.integer(gap_pct > median(gap_pct))]
mapped[, log_accept := log(acceptances + 1)]
mapped[, log_decisions := log(total_decisions + 1)]
mapped[, claimant_rate := claimant_count / (households_000 * 1000) * 100]

cat("=== Robustness Checks ===\n")
cat("Sample:", nrow(mapped), "obs,", uniqueN(mapped$la_code), "LAs\n")

## -----------------------------------------------------------------------
## 1. Binary treatment (above/below median gap)
## -----------------------------------------------------------------------
cat("\n--- Binary treatment specification ---\n")
r1_accept <- feols(accept_rate_per1000 ~ high_gap:post | la_code + yq,
                   data = mapped, cluster = ~la_code)
r1_ta <- feols(ta_rate_per1000 ~ high_gap:post | la_code + yq,
               data = mapped, cluster = ~la_code)
cat("Binary DiD — Acceptance rate:\n")
print(summary(r1_accept))
cat("Binary DiD — TA rate:\n")
print(summary(r1_ta))

## -----------------------------------------------------------------------
## 2. Alternative treatment: 1-bed and 3-bed LHA gaps
## -----------------------------------------------------------------------
cat("\n--- Alternative room category gaps ---\n")
lha <- fread("lha_rates_all_years.csv")

# 1-bed gap
gap_1bed <- data.table(
  brma_name = lha[["BRMA name"]],
  gap_1bed = (as.numeric(lha[["2020-21 1 bed weekly rate"]]) -
              as.numeric(lha[["2015-16 1 bed weekly rate"]])) /
             as.numeric(lha[["2015-16 1 bed weekly rate"]]) * 100
)

brma_la <- fread("brma_la_mapping_combined.csv")
brma_la <- merge(brma_la, gap_1bed, by = "brma_name", all.x = TRUE)
# Deduplicate: keep one BRMA per LA (first match)
brma_la <- unique(brma_la, by = "la_code")

mapped2 <- merge(mapped, brma_la[, .(la_code, gap_1bed)], by = "la_code", all.x = TRUE)
mapped2[, gap_1bed_10pp := gap_1bed / 10]

r2 <- feols(ta_rate_per1000 ~ gap_1bed_10pp:post | la_code + yq,
            data = mapped2, cluster = ~la_code)
cat("TA rate with 1-bed gap:\n")
print(summary(r2))

## -----------------------------------------------------------------------
## 3. Leave-one-out (exclude each region in turn)
## -----------------------------------------------------------------------
cat("\n--- Leave-one-out by region ---\n")
regions <- unique(mapped$region)
regions <- regions[!is.na(regions) & regions != ""]
loo_results <- list()
for (reg in regions) {
  loo_data <- mapped[region != reg]
  loo_fit <- feols(ta_rate_per1000 ~ gap_10pp:post | la_code + yq,
                   data = loo_data, cluster = ~la_code)
  loo_results[[reg]] <- data.table(
    excluded_region = reg,
    estimate = coef(loo_fit)["gap_10pp:post"],
    se = se(loo_fit)["gap_10pp:post"],
    n_la = uniqueN(loo_data$la_code)
  )
}
loo_dt <- rbindlist(loo_results)
cat("Leave-one-out estimates (TA rate):\n")
print(loo_dt)
cat(sprintf("Range: [%.3f, %.3f]\n", min(loo_dt$estimate), max(loo_dt$estimate)))

## -----------------------------------------------------------------------
## 4. Excluding London
## -----------------------------------------------------------------------
cat("\n--- Excluding London ---\n")
no_london <- mapped[region != "L"]
r4 <- feols(ta_rate_per1000 ~ gap_10pp:post | la_code + yq,
            data = no_london, cluster = ~la_code)
cat("TA rate excluding London:\n")
print(summary(r4))

## -----------------------------------------------------------------------
## 5. Pre-trend test (interaction with linear trend)
## -----------------------------------------------------------------------
cat("\n--- Pre-trend test ---\n")
pre_data <- mapped[post == 0]
pre_data[, time_trend := relative_q]
r5 <- feols(accept_rate_per1000 ~ gap_10pp:time_trend | la_code + yq,
            data = pre_data, cluster = ~la_code)
cat("Pre-period gap × trend:\n")
print(summary(r5))

r5_ta <- feols(ta_rate_per1000 ~ gap_10pp:time_trend | la_code + yq,
               data = pre_data, cluster = ~la_code)
cat("Pre-period TA × trend:\n")
print(summary(r5_ta))

## -----------------------------------------------------------------------
## 6. Full sample (including median-imputed LAs)
## -----------------------------------------------------------------------
cat("\n--- Full sample including imputed LAs ---\n")
panel[, gap_10pp := gap_pct / 10]
r6 <- feols(ta_rate_per1000 ~ gap_10pp:post | la_code + yq,
            data = panel, cluster = ~la_code)
cat("Full sample TA rate:\n")
print(summary(r6))

## -----------------------------------------------------------------------
## Save robustness results
## -----------------------------------------------------------------------
saveRDS(list(
  r1_accept = r1_accept, r1_ta = r1_ta, r2 = r2,
  loo = loo_dt, r4 = r4, r5 = r5, r5_ta = r5_ta, r6 = r6
), file = "robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")

setwd("../code")
