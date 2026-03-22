## 03_main_analysis.R — Staggered DiD analysis using fixest
source("00_packages.R")

cat("=== Main Analysis ===\n")

panel <- fread("../data/panel_full.csv")

## Create integer state ID
state_map <- data.table(state = unique(panel$state), state_id = seq_along(unique(panel$state)))
panel <- merge(panel, state_map, by = "state")

## ---- LOW EDUCATION (E1 + E2) ----
cat("\n=== Low-Education Workers (E1 + E2) ===\n")

panel_low <- panel[education %in% c("E1", "E2")]

panel_low_agg <- panel_low[, .(
  HirA = sum(HirA, na.rm = TRUE),
  Sep = sum(Sep, na.rm = TRUE),
  Emp = sum(Emp, na.rm = TRUE),
  EarnS = weighted.mean(EarnS, Emp, na.rm = TRUE)
), by = .(state, state_id, year, quarter, time_idx, yq, adopt_year)]

panel_low_agg <- panel_low_agg[Emp > 0]
panel_low_agg[, TurnOvrS := (HirA + Sep) / (2 * Emp)]
panel_low_agg[, hire_rate := HirA / Emp]
panel_low_agg[, sep_rate := Sep / Emp]
panel_low_agg[, log_earn := log(EarnS)]

## Treated indicator
panel_low_agg[, treated := as.integer(adopt_year < 9999 &
  year > adopt_year | (year == adopt_year & quarter >= ceiling(1/3)))]
## Simpler: treated = year >= adoption year (annual precision is fine given cohort clustering)
panel_low_agg[, treated := as.integer(year >= adopt_year & adopt_year < 9999)]

## Balance panel
state_counts <- panel_low_agg[, .N, by = state_id]
max_N <- max(state_counts$N)
balanced <- state_counts[N >= floor(max_N * 0.9)]$state_id
panel_low_agg <- panel_low_agg[state_id %in% balanced]

cat("Low-ed panel: N =", nrow(panel_low_agg), "| States:", uniqueN(panel_low_agg$state_id), "\n")
cat("Mean turnover:", round(mean(panel_low_agg$TurnOvrS, na.rm = TRUE), 4), "\n")
cat("SD(turnover):", round(sd(panel_low_agg$TurnOvrS, na.rm = TRUE), 4), "\n")

## ---- TWFE: Main results ----
cat("\n=== TWFE Results (Low-Education) ===\n")

twfe_turn <- feols(TurnOvrS ~ treated | state_id + time_idx, data = panel_low_agg,
                   cluster = ~state_id)
twfe_hire <- feols(hire_rate ~ treated | state_id + time_idx, data = panel_low_agg,
                   cluster = ~state_id)
twfe_sep <- feols(sep_rate ~ treated | state_id + time_idx, data = panel_low_agg,
                  cluster = ~state_id)
twfe_earn <- feols(log_earn ~ treated | state_id + time_idx, data = panel_low_agg,
                   cluster = ~state_id)

cat("Turnover Rate:  b=", round(coef(twfe_turn), 5), " SE=", round(se(twfe_turn), 5),
    " p=", round(fixest::pvalue(twfe_turn), 4), "\n")
cat("Hire Rate:      b=", round(coef(twfe_hire), 5), " SE=", round(se(twfe_hire), 5),
    " p=", round(fixest::pvalue(twfe_hire), 4), "\n")
cat("Sep Rate:       b=", round(coef(twfe_sep), 5), " SE=", round(se(twfe_sep), 5),
    " p=", round(fixest::pvalue(twfe_sep), 4), "\n")
cat("Log Earnings:   b=", round(coef(twfe_earn), 5), " SE=", round(se(twfe_earn), 5),
    " p=", round(fixest::pvalue(twfe_earn), 4), "\n")

## ---- Sun-Abraham (annual cohorts) ----
cat("\n=== Sun-Abraham Event Study ===\n")

## Use annual cohorts to avoid collinearity
panel_low_agg[, cohort_year := fifelse(adopt_year >= 9999, NA_integer_, as.integer(adopt_year))]

## Create relative year
panel_low_agg[, rel_year := year - adopt_year]
panel_low_agg[adopt_year >= 9999, rel_year := NA_integer_]

## Sun-Abraham with annual cohorts on annual data
## Aggregate to state-year for cleaner event study
panel_annual <- panel_low_agg[, .(
  TurnOvrS = weighted.mean(TurnOvrS, Emp, na.rm = TRUE),
  hire_rate = weighted.mean(hire_rate, Emp, na.rm = TRUE),
  sep_rate = weighted.mean(sep_rate, Emp, na.rm = TRUE),
  log_earn = weighted.mean(log_earn, Emp, na.rm = TRUE),
  Emp = sum(Emp, na.rm = TRUE),
  HirA = sum(HirA, na.rm = TRUE),
  Sep = sum(Sep, na.rm = TRUE)
), by = .(state_id, year, adopt_year, cohort_year)]

panel_annual[, treated := as.integer(year >= adopt_year & adopt_year < 9999)]

cat("Annual panel: N =", nrow(panel_annual), "| States:", uniqueN(panel_annual$state_id), "\n")

## Sun-Abraham with fixest
sa_turn <- feols(TurnOvrS ~ sunab(cohort_year, year, ref.p = -1) | state_id + year,
                 data = panel_annual, cluster = ~state_id)
cat("\nSun-Abraham Turnover:\n")
print(summary(sa_turn, agg = "ATT"))

sa_hire <- feols(hire_rate ~ sunab(cohort_year, year, ref.p = -1) | state_id + year,
                 data = panel_annual, cluster = ~state_id)
cat("\nSun-Abraham Hire Rate:\n")
print(summary(sa_hire, agg = "ATT"))

sa_sep <- feols(sep_rate ~ sunab(cohort_year, year, ref.p = -1) | state_id + year,
                data = panel_annual, cluster = ~state_id)
cat("\nSun-Abraham Separation Rate:\n")
print(summary(sa_sep, agg = "ATT"))

sa_earn <- feols(log_earn ~ sunab(cohort_year, year, ref.p = -1) | state_id + year,
                 data = panel_annual, cluster = ~state_id)
cat("\nSun-Abraham Log Earnings:\n")
print(summary(sa_earn, agg = "ATT"))

## ---- HIGH EDUCATION PLACEBO ----
cat("\n=== Placebo: High-Education (Bachelor's+) ===\n")

panel_high <- panel[education == "E4"]
panel_high <- merge(panel_high, state_map, by = "state", suffixes = c("", ".y"))
if ("state_id.y" %in% names(panel_high)) {
  panel_high[, state_id := state_id.y]
  panel_high[, state_id.y := NULL]
}
panel_high <- panel_high[Emp > 0]
panel_high[, hire_rate := HirA / Emp]
panel_high[, sep_rate := Sep / Emp]
panel_high[, treated := as.integer(year >= adopt_year & adopt_year < 9999)]

ph_counts <- panel_high[, .N, by = state_id]
ph_balanced <- ph_counts[N >= floor(max(ph_counts$N) * 0.9)]$state_id
panel_high <- panel_high[state_id %in% ph_balanced]

twfe_ph_turn <- feols(TurnOvrS ~ treated | state_id + time_idx, data = panel_high,
                      cluster = ~state_id)
twfe_ph_hire <- feols(hire_rate ~ treated | state_id + time_idx, data = panel_high,
                      cluster = ~state_id)
cat("Placebo Turnover:  b=", round(coef(twfe_ph_turn), 5), " SE=", round(se(twfe_ph_turn), 5),
    " p=", round(fixest::pvalue(twfe_ph_turn), 4), "\n")
cat("Placebo Hire Rate: b=", round(coef(twfe_ph_hire), 5), " SE=", round(se(twfe_ph_hire), 5),
    " p=", round(fixest::pvalue(twfe_ph_hire), 4), "\n")

## ---- TRIPLE-DIFFERENCE: Low-ed vs High-ed ----
cat("\n=== Triple-Difference (Low-Ed vs High-Ed) ===\n")

## Stack low and high education panels
panel_low_agg[, low_ed := 1L]
panel_high_sub <- panel_high[state_id %in% balanced, .(
  state_id, year, quarter, time_idx, TurnOvrS, hire_rate, sep_rate, treated
)]
panel_high_sub[, low_ed := 0L]

panel_low_sub <- panel_low_agg[, .(
  state_id, year, quarter, time_idx, TurnOvrS, hire_rate, sep_rate, treated
)]
panel_low_sub[, low_ed := 1L]

panel_ddd <- rbind(panel_low_sub, panel_high_sub)
panel_ddd[, state_ed := paste0(state_id, "_", low_ed)]

## DDD: treatment * low_education
ddd_turn <- feols(TurnOvrS ~ treated:i(low_ed) | state_ed + time_idx^low_ed,
                  data = panel_ddd, cluster = ~state_id)
cat("DDD Turnover:\n")
print(summary(ddd_turn))

## ---- Save results ----
results <- list(
  twfe_turn = twfe_turn, twfe_hire = twfe_hire,
  twfe_sep = twfe_sep, twfe_earn = twfe_earn,
  sa_turn = sa_turn, sa_hire = sa_hire,
  sa_sep = sa_sep, sa_earn = sa_earn,
  twfe_ph_turn = twfe_ph_turn, twfe_ph_hire = twfe_ph_hire,
  ddd_turn = ddd_turn,
  panel_low_agg = panel_low_agg, panel_annual = panel_annual,
  panel_high = panel_high
)
saveRDS(results, "../data/main_results.rds")

## Diagnostics for validator
diagnostics <- list(
  n_treated = uniqueN(panel_low_agg[treated == 1]$state_id),
  n_pre = length(unique(panel_low_agg[treated == 0 & adopt_year < 9999]$time_idx)),
  n_obs = nrow(panel_low_agg)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", paste(names(diagnostics), diagnostics, sep = "=", collapse = ", "), "\n")

cat("\n=== KEY RESULTS SUMMARY ===\n")
cat("Turnover: b=", round(coef(twfe_turn), 5), " p=", round(fixest::pvalue(twfe_turn), 4), "\n")
cat("Hire:     b=", round(coef(twfe_hire), 5), " p=", round(fixest::pvalue(twfe_hire), 4), "\n")
cat("Sep:      b=", round(coef(twfe_sep), 5), " p=", round(fixest::pvalue(twfe_sep), 4), "\n")
cat("Earn:     b=", round(coef(twfe_earn), 5), " p=", round(fixest::pvalue(twfe_earn), 4), "\n")
cat("Placebo:  b=", round(coef(twfe_ph_turn), 5), " p=", round(fixest::pvalue(twfe_ph_turn), 4), "\n")

cat("\n=== Main analysis complete ===\n")
