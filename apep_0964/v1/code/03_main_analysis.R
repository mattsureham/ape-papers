# 03_main_analysis.R — Primary regressions: ATAD and aggregate debt bias
source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")

cat("=== Main Analysis ===\n")

# ================================================================
# TABLE 1: Summary Statistics
# ================================================================
cat("\n--- Summary Statistics ---\n")

sum_vars <- c("interest_gos_ratio", "debt_ratio", "leverage",
              "debt_securities", "loans", "interest_paid", "gos_ebitda",
              "gdp_growth", "inflation")

pre <- panel[year < 2019]
post <- panel[year >= 2019]

sumstats <- rbindlist(lapply(sum_vars, function(v) {
  data.table(
    variable = v,
    mean_pre = mean(pre[[v]], na.rm = TRUE),
    sd_pre = sd(pre[[v]], na.rm = TRUE),
    mean_post = mean(post[[v]], na.rm = TRUE),
    sd_post = sd(post[[v]], na.rm = TRUE),
    n_pre = sum(!is.na(pre[[v]])),
    n_post = sum(!is.na(post[[v]]))
  )
}))

print(sumstats)

# ================================================================
# TABLE 2: Main DiD — Dose-Response
# ================================================================
cat("\n--- Main DiD: Dose-Response ---\n")

# Model 1: Simple adopted effect on interest/GOS
m1 <- feols(interest_gos_w ~ adopted | geo + year, data = panel,
            cluster = ~geo)

# Model 2: Dose-response (adopted × dose intensity)
m2 <- feols(interest_gos_w ~ treat_dose | geo + year, data = panel,
            cluster = ~geo)

# Model 3: Dose-response with macro controls
m3 <- feols(interest_gos_w ~ treat_dose + gdp_growth + inflation | geo + year,
            data = panel, cluster = ~geo)

# Model 4: Debt composition (debt securities share)
m4 <- feols(debt_ratio_w ~ treat_dose | geo + year, data = panel,
            cluster = ~geo)

# Model 5: Leverage
m5 <- feols(leverage_w ~ treat_dose | geo + year, data = panel,
            cluster = ~geo)

# Model 6: Net interest / GOS (aligns with ATAD's net borrowing cost definition)
m6 <- feols(net_interest_gos_w ~ treat_dose | geo + year, data = panel,
            cluster = ~geo)

cat("\n--- Main Results ---\n")
etable(m1, m2, m3, m4, m5, m6,
       headers = c("Int/GOS", "Int/GOS Dose", "Int/GOS Controls",
                    "Debt Share", "Leverage", "Net Int/GOS"))

# ================================================================
# TABLE 3: Event Study (leads and lags)
# ================================================================
cat("\n--- Event Study ---\n")

# Use full panel with staggered adoption for identification
# event_time = year - adoption_year (varies across derogation cohorts)
# Bin endpoints: ≤-5 and ≥+4
panel[, et := pmin(pmax(event_time, -5), 4)]

# Interest/GOS event study — dose-weighted
es1 <- feols(interest_gos_w ~ i(et, dose, ref = -1) | geo + year,
             data = panel, cluster = ~geo)

cat("Event study coefficients (Interest/GOS, dose-weighted):\n")
print(coeftable(es1))

# Debt ratio event study — dose-weighted
es2 <- feols(debt_ratio_w ~ i(et, dose, ref = -1) | geo + year,
             data = panel, cluster = ~geo)

cat("Event study coefficients (Debt ratio, dose-weighted):\n")
print(coeftable(es2))

# ================================================================
# TABLE 4: Derogation Placebo
# ================================================================
cat("\n--- Derogation Placebo ---\n")

# Derogation countries should show no effect in 2019-2021
# (they hadn't adopted ATAD yet)
# Restrict to 2012-2021 (before any derogation country adopted)
placebo_panel <- panel[year <= 2021]

# Create placebo treatment: post2019 × derogation
placebo_panel[, placebo_treat := post2019 * derogation]

plac1 <- feols(interest_gos_w ~ placebo_treat | geo + year,
               data = placebo_panel, cluster = ~geo)

plac2 <- feols(debt_ratio_w ~ placebo_treat | geo + year,
               data = placebo_panel, cluster = ~geo)

cat("Placebo (derogation countries, 2019-2021):\n")
etable(plac1, plac2, headers = c("Int/GOS Placebo", "Debt Share Placebo"))

# ================================================================
# Save diagnostics
# ================================================================
diag <- list(
  n_treated = uniqueN(panel[adopted == 1, geo]),
  n_pre = uniqueN(panel[year < 2019, year]),
  n_obs = nrow(panel),
  n_countries = uniqueN(panel$geo),
  n_years = uniqueN(panel$year),
  n_early = uniqueN(panel[derogation == 0, geo]),
  n_derogation = uniqueN(panel[derogation == 1, geo])
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nSaved diagnostics.json\n")

# Save model objects for table generation
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6,
             es1 = es1, es2 = es2, plac1 = plac1, plac2 = plac2,
             sumstats = sumstats, panel = panel),
        "../data/models.rds")
cat("Saved models.rds\n")
