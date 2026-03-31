# =============================================================================
# 02_clean_data.R — Construct analysis variables
# =============================================================================

source("00_packages.R")

qwi_dt <- readRDS("../data/qwi_panel.rds")

cat("Input panel: ", nrow(qwi_dt), " rows\n")

# --- Create analysis variables ---

# Calendar quarter index (for FEs)
qwi_dt[, cal_q := (year - 2009) * 4 + quarter]

# State-industry-ethnicity panel ID
qwi_dt[, panel_id := paste(state_fips, industry, ethnicity, sep = "_")]

# Event time: quarters relative to treatment
qwi_dt[, event_time := ifelse(treated_state == 1,
                               cal_q - ((treat_year - 2009) * 4 + treat_quarter),
                               NA_real_)]

# Cohort year for CS estimator
qwi_dt[, cohort := ifelse(treated_state == 1, treat_year, 0)]  # 0 = never treated

# Treatment × Hispanic interaction (DDD)
qwi_dt[, treat_post_hisp := post * treated_state * hispanic]
qwi_dt[, treat_post := post * treated_state]
qwi_dt[, post_hisp := post * hispanic]

# Industry labels
ind_labels <- c(
  "23" = "Construction",
  "62" = "Health Care",
  "81" = "Other Services",
  "44-45" = "Retail",
  "72" = "Accommodation/Food",
  "31-33" = "Manufacturing"
)
qwi_dt[, industry_name := ind_labels[industry]]

# Licensed vs unlicensed industry flag
qwi_dt[, licensed := as.integer(industry %in% c("23", "62", "81"))]

# Log employment
qwi_dt[, log_emp := log(Emp)]
qwi_dt[log_emp == -Inf, log_emp := NA]

# Hiring rate (hires / employment)
qwi_dt[, hire_rate := HirA / Emp]
qwi_dt[is.infinite(hire_rate), hire_rate := NA]

# --- Summary statistics ---
cat("\n=== Summary Statistics ===\n")
cat(sprintf("States: %d (treated: %d, control: %d)\n",
    length(unique(qwi_dt$state_fips)),
    length(unique(qwi_dt[treated_state == 1, state_fips])),
    length(unique(qwi_dt[treated_state == 0, state_fips]))))
cat(sprintf("Quarters: %d (%d Q%d to %d Q%d)\n",
    length(unique(qwi_dt$cal_q)),
    min(qwi_dt$year), min(qwi_dt[year == min(year), quarter]),
    max(qwi_dt$year), max(qwi_dt[year == max(year), quarter])))
cat(sprintf("Industries: %d\n", length(unique(qwi_dt$industry))))

# Summary by ethnicity
summ <- qwi_dt[, .(
  mean_earn = mean(EarnS, na.rm = TRUE),
  sd_earn = sd(EarnS, na.rm = TRUE),
  mean_emp = mean(Emp, na.rm = TRUE),
  n_obs = .N
), by = .(ethnicity)]
cat("\nBy ethnicity:\n")
print(summ)

# Summary by treatment status
summ_treat <- qwi_dt[, .(
  mean_earn = mean(EarnS, na.rm = TRUE),
  n_states = uniqueN(state_fips),
  n_obs = .N
), by = .(treated_state, hispanic)]
cat("\nBy treatment × ethnicity:\n")
print(summ_treat)

# Summary by industry
summ_ind <- qwi_dt[, .(
  mean_earn = mean(EarnS, na.rm = TRUE),
  mean_emp = mean(Emp, na.rm = TRUE),
  n_obs = .N
), by = .(industry_name, licensed)]
cat("\nBy industry:\n")
print(summ_ind)

# --- Save cleaned panel ---
saveRDS(qwi_dt, "../data/analysis_panel.rds")
cat("\nCleaned panel saved: ", nrow(qwi_dt), " rows\n")
