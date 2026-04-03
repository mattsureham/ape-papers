## 04_robustness.R — Robustness checks and refined bunching estimates
## APEP-1349: Dutch BPM Multi-Cutoff Bunching

source("00_packages.R")

nl_pooled <- readRDS("../data/nl_pooled.rds")
de_pooled <- readRDS("../data/de_pooled.rds")
kinks <- readRDS("../data/kinks.rds")
fuel_near79 <- readRDS("../data/fuel_near79.rds")

# ============================================================
# REFINED BUNCHING ESTIMATOR
# ============================================================
# Improved version: handles edge cases, reports more diagnostics
bunching_est <- function(data, kink, bw_below = 5, bw_above = 5,
                         poly = 7, window = 25, n_boot = 500) {
  d <- data %>%
    filter(co2 >= kink - window, co2 <= kink + window) %>%
    mutate(
      z = co2 - kink,
      excluded = (co2 >= kink - bw_below & co2 <= kink + bw_above)
    )

  fit_d <- d %>% filter(!excluded)
  if (nrow(fit_d) < poly + 2) return(NULL)

  fml <- as.formula(paste0("count ~ ", paste0("I(z^", 1:poly, ")", collapse = " + ")))
  m <- lm(fml, data = fit_d)
  d$cf <- pmax(predict(m, newdata = d), 1)  # floor at 1, not 0

  # Excess mass below kink
  below <- d %>% filter(co2 >= kink - bw_below, co2 <= kink)
  excess <- sum(below$count - below$cf)

  # Missing mass above kink
  above <- d %>% filter(co2 > kink, co2 <= kink + bw_above)
  missing <- sum(above$cf - above$count)

  # Counterfactual at kink
  cf_kink <- d$cf[d$co2 == kink]

  # Normalized bunching
  b <- excess / cf_kink

  # Bootstrap
  set.seed(42)
  b_boots <- replicate(n_boot, {
    bd <- d
    bd$count <- rpois(nrow(bd), pmax(bd$count, 1))
    bfit <- tryCatch(lm(fml, data = bd %>% filter(!excluded)), error = function(e) NULL)
    if (is.null(bfit)) return(NA)
    bd$cf <- pmax(predict(bfit, newdata = bd), 1)
    bb <- bd %>% filter(co2 >= kink - bw_below, co2 <= kink)
    bex <- sum(bb$count - bb$cf)
    bcf <- bd$cf[bd$co2 == kink]
    bex / bcf
  })

  se <- sd(b_boots, na.rm = TRUE)

  list(
    kink = kink, excess = excess, missing = missing,
    b = b, se = se, cf_kink = cf_kink,
    n_obs = sum(d$count), data = d
  )
}

# ============================================================
# 1. ROBUSTNESS: VARY POLYNOMIAL DEGREE
# ============================================================
cat("=== Robustness 1: Polynomial Degree Sensitivity ===\n\n")

poly_robust <- list()
for (p in c(3, 5, 7, 9)) {
  row <- list()
  for (k in c(141, 157)) {
    nl_r <- bunching_est(nl_pooled, k, poly = p, bw_below = 5, bw_above = 5)
    de_r <- bunching_est(de_pooled, k, poly = p, bw_below = 5, bw_above = 5)
    if (!is.null(nl_r) && !is.null(de_r)) {
      diff <- nl_r$b - de_r$b
      se_diff <- sqrt(nl_r$se^2 + de_r$se^2)
      row[[as.character(k)]] <- data.frame(
        kink = k, poly = p,
        b_nl = nl_r$b, se_nl = nl_r$se,
        b_de = de_r$b, se_de = de_r$se,
        diff = diff, se_diff = se_diff,
        t_stat = diff / se_diff
      )
    }
  }
  poly_robust[[as.character(p)]] <- bind_rows(row)
}
poly_df <- bind_rows(poly_robust)
cat("Kink 141:\n")
print(poly_df %>% filter(kink == 141) %>% select(poly, b_nl, b_de, diff, t_stat))
cat("\nKink 157:\n")
print(poly_df %>% filter(kink == 157) %>% select(poly, b_nl, b_de, diff, t_stat))

# ============================================================
# 2. ROBUSTNESS: VARY BANDWIDTH
# ============================================================
cat("\n=== Robustness 2: Bandwidth Sensitivity ===\n\n")

bw_robust <- list()
for (bw in c(3, 5, 7, 10)) {
  for (k in c(141, 157)) {
    nl_r <- bunching_est(nl_pooled, k, bw_below = bw, bw_above = bw)
    de_r <- bunching_est(de_pooled, k, bw_below = bw, bw_above = bw)
    if (!is.null(nl_r) && !is.null(de_r)) {
      diff <- nl_r$b - de_r$b
      se_diff <- sqrt(nl_r$se^2 + de_r$se^2)
      bw_robust[[paste(k, bw)]] <- data.frame(
        kink = k, bandwidth = bw,
        b_nl = nl_r$b, b_de = de_r$b,
        diff = diff, t_stat = diff / se_diff
      )
    }
  }
}
bw_df <- bind_rows(bw_robust)
cat("Kink 141 across bandwidths:\n")
print(bw_df %>% filter(kink == 141))
cat("\nKink 157 across bandwidths:\n")
print(bw_df %>% filter(kink == 157))

# ============================================================
# 3. YEAR-BY-YEAR ESTIMATION (stability check)
# ============================================================
cat("\n=== Robustness 3: Year-by-Year Estimates ===\n\n")

df_raw <- readRDS("../data/co2_distributions.rds")
year_results <- list()

for (yr in 2020:2022) {
  for (country in c("NL", "DE")) {
    yr_pooled <- df_raw %>%
      filter(country == !!country, year == yr) %>%
      group_by(co2) %>% summarise(count = sum(count), .groups = "drop")
    full <- data.frame(co2 = 1:250) %>%
      left_join(yr_pooled, by = "co2") %>%
      mutate(count = replace_na(count, 0))

    for (k in c(141, 157)) {
      r <- bunching_est(full, k, n_boot = 200)
      if (!is.null(r)) {
        year_results[[paste(yr, country, k)]] <- data.frame(
          year = yr, country = country, kink = k,
          b = r$b, se = r$se
        )
      }
    }
  }
}
year_df <- bind_rows(year_results)
cat("Year-by-year bunching at kink 141:\n")
print(year_df %>% filter(kink == 141) %>% arrange(country, year))
cat("\nYear-by-year bunching at kink 157:\n")
print(year_df %>% filter(kink == 157) %>% arrange(country, year))

# ============================================================
# 4. McCRARY DENSITY TEST
# ============================================================
cat("\n=== Robustness 4: McCrary-style Density Discontinuity ===\n\n")

# Simple version: test whether log density is discontinuous at the kink
# Regression: log(count) = α + β·1(co2 > kink) + f(co2) + ε on bins near kink
for (k in c(79, 101, 141, 157)) {
  for (country_name in c("NL", "DE")) {
    d <- if (country_name == "NL") nl_pooled else de_pooled
    test_d <- d %>%
      filter(co2 >= k - 15, co2 <= k + 15, count > 0) %>%
      mutate(
        above = as.integer(co2 > k),
        z = co2 - k,
        log_count = log(count)
      )

    if (nrow(test_d) < 10) next

    fit <- lm(log_count ~ above + z + I(z^2) + above:z, data = test_d)
    coef_above <- coef(fit)["above"]
    se_above <- sqrt(vcov(fit)["above", "above"])

    cat(sprintf("  %s kink %d: discontinuity = %.3f (SE=%.3f, t=%.2f)\n",
                country_name, k, coef_above, se_above, coef_above / se_above))
  }
}

# ============================================================
# 5. PHEV-ONLY ANALYSIS AT 79 g/km
# ============================================================
cat("\n=== PHEV-Only Analysis at 79 g/km ===\n\n")

# The 79 kink is in the PHEV range. Compare NL vs DE for PHEVs only.
# We only have NL fuel-type data. For DE, we assume similar PHEV CO2 distribution.
# The key test: does the NL PHEV distribution show MORE bunching at 79 than DE?

# NL PHEV distribution near 79
phev_nl <- fuel_near79 %>%
  filter(powertrain == "PHEV") %>%
  group_by(co2) %>% summarise(count = sum(count), .groups = "drop") %>%
  filter(co2 >= 50, co2 <= 110)

# Fill zeros
full_phev <- data.frame(co2 = 50:110) %>%
  left_join(phev_nl, by = "co2") %>%
  mutate(count = replace_na(count, 0))

cat("NL PHEV distribution (50-110 g/km):\n")
print(as.data.frame(full_phev %>% filter(count > 0)))

# Bunching estimate for NL PHEVs at 79
r_phev <- bunching_est(full_phev, 79, bw_below = 3, bw_above = 3,
                       poly = 5, window = 20, n_boot = 200)
if (!is.null(r_phev)) {
  cat(sprintf("\nPHEV bunching at 79: b = %.3f (SE = %.3f, t = %.2f)\n",
              r_phev$b, r_phev$se, r_phev$b / r_phev$se))
  cat(sprintf("Excess mass: %d vehicles\n", round(r_phev$excess)))
}

# ============================================================
# UPDATE DIAGNOSTICS
# ============================================================
# For a bunching design, "treated units" = kink points × countries
# "Pre-periods" = counterfactual bins
diagnostics <- list(
  n_treated = 4 * 2,  # 4 kinks × 2 countries
  n_pre = 25,         # bins on each side of kink for polynomial fit
  n_obs = sum(nl_pooled$count) + sum(de_pooled$count),
  design = "multi-cutoff bunching with difference-in-bunching",
  n_kinks = 4,
  n_nl_vehicles = sum(nl_pooled$count),
  n_de_vehicles = sum(de_pooled$count),
  years = "2020-2022"
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save robustness results
saveRDS(list(
  poly = poly_df,
  bandwidth = bw_df,
  year_by_year = year_df
), "../data/robustness_results.rds")

cat("\n04_robustness.R complete.\n")
