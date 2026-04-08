## 03_main_analysis.R — Main analysis: DMTO anticipatory bunching
## Paper: apep_1431 — France DMTO Composition Illusion
##
## Design: DiD using March 2025 as the event, within-department
## temporal comparison. Also cross-departmental heterogeneity analysis.

library(data.table)
library(fixest)
library(tidyverse)
library(lubridate)
library(jsonlite)

cat("=== Main Analysis: apep_1431 ===\n")

panel <- fread("data/dept_panel/dept_month_panel.csv")
cat(sprintf("Panel: %d rows, %d departments, years %d-%d\n",
            nrow(panel), uniqueN(panel$code_departement),
            min(panel$year), max(panel$year)))

# Drop ambiguous departments for main DiD (keep all for within-dept event study)
panel_did <- panel[!is.na(treated)]
cat(sprintf("DiD sample: %d treated, %d control departments\n",
            uniqueN(panel_did[treated==1]$code_departement),
            uniqueN(panel_did[treated==0]$code_departement)))

# -------------------------------------------------------------------
# PART 1: Within-department event study (full sample, no control needed)
# -------------------------------------------------------------------
# All departments are "treated" by the national DMTO reform.
# Event time = 0 for March 2025 (the rush month).
# Compare March 2025 to historical Marchmonths within same department.
# Department FE + year FE control for permanent differences and macro trends.

cat("\n=== Part 1: Within-Department Event Study ===\n")

# Create "March dummy" for each year (to allow year-specific March effects)
panel[, march_2025 := as.integer(year == 2025 & month == 3)]
panel[, feb_2025   := as.integer(year == 2025 & month == 2)]
panel[, jan_2025   := as.integer(year == 2025 & month == 1)]
panel[, apr_2025   := as.integer(year == 2025 & month == 4)]

# Year-Month fixed effects for the event study
panel[, ym_fe := paste0(year, "_", sprintf("%02d", month))]

# Trend variable (to capture market decline 2023-2024)
panel[, t_trend := (year - 2021) + (month - 1) / 12]

# Main event study: Does March 2025 show anomalous transactions?
# Use months 1-4 only to focus on the pre/rush/post window
panel_window <- panel[month %in% 1:4]  # Jan-Apr only
panel_window[, event_period := fcase(
  year < 2025 & month <= 4, "pre",
  year == 2025 & month == 1, "jan_2025",
  year == 2025 & month == 2, "feb_2025",
  year == 2025 & month == 3, "mar_2025",
  year == 2025 & month == 4, "apr_2025"
)]
panel_window[, event_f := factor(event_period,
              levels = c("pre", "jan_2025", "feb_2025", "mar_2025", "apr_2025"))]

# Reference period: average pre-2025 Jan-Apr (absorbed in dept + month FE)
# For the event study, identify March 2025 excess relative to historical March
m_event_n <- feols(log_n ~ i(event_f, ref = "pre") | code_departement + month,
                   data = panel_window,
                   cluster = ~code_departement)
cat("\nEvent study: log transactions (all departments):\n")
print(summary(m_event_n))

m_event_v <- feols(log_mean_value ~ i(event_f, ref = "pre") | code_departement + month,
                   data = panel_window,
                   cluster = ~code_departement)
cat("\nEvent study: log mean value:\n")
print(summary(m_event_v))

# -------------------------------------------------------------------
# PART 2: DiD — Treated vs Control departments in March 2025
# -------------------------------------------------------------------
cat("\n=== Part 2: DiD (Treated vs Control) ===\n")

# Add event indicators to panel_did
panel_did[, march_2025 := as.integer(year == 2025 & month == 3)]
panel_did[, feb_2025   := as.integer(year == 2025 & month == 2)]
panel_did[, apr_2025   := as.integer(year == 2025 & month == 4)]

# Create interaction: treated × March 2025
panel_did[, treat_march25 := treated * march_2025]
panel_did[, treat_feb25   := treated * feb_2025]
panel_did[, treat_apr25   := treated * apr_2025]

# Main DiD: effect of being treated × March 2025
# Control for department and month-year FE
m_did_n <- feols(log_n ~ treat_march25 + treat_feb25 + treat_apr25 |
                   code_departement + ym,
                 data = panel_did,
                 cluster = ~code_departement)
cat("\nDiD: log transactions (treated × March 2025 vs. all other months):\n")
print(summary(m_did_n))

# Same for value
m_did_v <- feols(log_mean_value ~ treat_march25 + treat_feb25 + treat_apr25 |
                   code_departement + ym,
                 data = panel_did,
                 cluster = ~code_departement)
cat("\nDiD: log mean value:\n")
print(summary(m_did_v))

# Compositional outcomes
m_did_sh500 <- feols(share_above_500k ~ treat_march25 + treat_feb25 + treat_apr25 |
                       code_departement + ym,
                     data = panel_did,
                     cluster = ~code_departement)
cat("\nDiD: share above 500K:\n")
print(summary(m_did_sh500))

m_did_sh300 <- feols(share_above_300k ~ treat_march25 + treat_feb25 + treat_apr25 |
                       code_departement + ym,
                     data = panel_did,
                     cluster = ~code_departement)
cat("\nDiD: share above 300K:\n")
print(summary(m_did_sh300))

# -------------------------------------------------------------------
# PART 3: Cross-department heterogeneity
# -------------------------------------------------------------------
cat("\n=== Part 3: Heterogeneity by baseline transaction value ===\n")

# Does the March 2025 surge scale with the department's baseline value level?
# Higher-value departments have more to gain from rushing (larger absolute tax savings)

dept_baseline <- panel[year %in% 2022:2024,
                        .(baseline_mean_value = mean(mean_value, na.rm=TRUE),
                          baseline_log_n = mean(log_n, na.rm=TRUE)),
                        by = code_departement]

# Quintiles of baseline value
dept_baseline[, value_quintile := ntile(baseline_mean_value, 5)]
panel_hetero <- merge(panel, dept_baseline[, .(code_departement, baseline_mean_value,
                                                value_quintile)],
                      by = "code_departement")

# Interaction: March 2025 × value quintile
panel_hetero[, march_2025 := as.integer(year == 2025 & month == 3)]
panel_hetero[, q_march25 := value_quintile * march_2025]

m_hetero <- feols(log_n ~ i(value_quintile, march_2025, ref = 1) |
                    code_departement + ym,
                  data = panel_hetero,
                  cluster = ~code_departement)
cat("Heterogeneity: March 2025 surge by baseline value quintile:\n")
print(summary(m_hetero))

# Similarly for value composition
m_hetero_v <- feols(log_mean_value ~ i(value_quintile, march_2025, ref = 1) |
                      code_departement + ym,
                    data = panel_hetero,
                    cluster = ~code_departement)
cat("Heterogeneity (log value): March 2025 by value quintile:\n")
print(summary(m_hetero_v))

# -------------------------------------------------------------------
# PART 4: Compute key scalars
# -------------------------------------------------------------------
cat("\n=== Key Scalars ===\n")

# Overall national March surge
nat_march <- panel[year == 2025 & month == 3, sum(n_transactions)]
nat_feb   <- panel[year == 2025 & month == 2, sum(n_transactions)]

# Historical national March/Feb ratio
hist_ratios <- panel[year %in% 2022:2024 & month %in% c(2,3),
                      .(n=sum(n_transactions)), by=.(year, month)]
hist_wide2 <- dcast(hist_ratios, year ~ month, value.var = "n")
setnames(hist_wide2, c("year", "n_feb", "n_mar"))
hist_mean_ratio <- mean(hist_wide2$n_mar / hist_wide2$n_feb)

observed_ratio <- nat_march / nat_feb
excess_pct <- (observed_ratio / hist_mean_ratio - 1) * 100

cat(sprintf("National March/Feb 2025 ratio: %.3f\n", observed_ratio))
cat(sprintf("Historical March/Feb ratio (2022-2024): %.3f\n", hist_mean_ratio))
cat(sprintf("Excess: +%.1f%%\n", excess_pct))

# Value composition shift
nat_val_mar <- panel[year == 2025 & month == 3, mean(mean_value) / 1000]
nat_val_feb <- panel[year == 2025 & month == 2, mean(mean_value) / 1000]
hist_val_ratios <- panel[year %in% 2022:2024 & month %in% c(2,3),
                          .(v=mean(mean_value)), by=.(year, month)]
hist_val_wide <- dcast(hist_val_ratios, year ~ month, value.var = "v")
setnames(hist_val_wide, c("year", "v_feb", "v_mar"))
hist_mean_val_ratio <- mean(hist_val_wide$v_mar / hist_val_wide$v_feb)

observed_val_ratio <- nat_val_mar / nat_val_feb
excess_val_pct <- (observed_val_ratio / hist_mean_val_ratio - 1) * 100

cat(sprintf("National avg value March/Feb 2025: %.3f (%.0fK / %.0fK EUR)\n",
            observed_val_ratio, nat_val_mar, nat_val_feb))
cat(sprintf("Historical avg value March/Feb: %.3f\n", hist_mean_val_ratio))
cat(sprintf("Excess value shift: +%.1f%%\n", excess_val_pct))

# DiD coefficients
march_coef_n <- coef(m_did_n)["treat_march25"]
march_se_n   <- se(m_did_n)["treat_march25"]
march_coef_v <- coef(m_did_v)["treat_march25"]
march_se_v   <- se(m_did_v)["treat_march25"]
march_coef_sh500 <- coef(m_did_sh500)["treat_march25"]
march_se_sh500   <- se(m_did_sh500)["treat_march25"]

cat(sprintf("\nDiD March 2025 effect (log transactions): %.3f (SE=%.3f)\n",
            march_coef_n, march_se_n))
cat(sprintf("DiD March 2025 effect (log mean value): %.3f (SE=%.3f)\n",
            march_coef_v, march_se_v))
cat(sprintf("DiD March 2025 effect (share >500K): %.3f (SE=%.3f)\n",
            march_coef_sh500, march_se_sh500))
cat(sprintf("DiD March 2025 transactions: exp(%.3f) = +%.1f%%\n",
            march_coef_n, (exp(march_coef_n) - 1) * 100))

# -------------------------------------------------------------------
# PART 5: Save results
# -------------------------------------------------------------------
save(m_event_n, m_event_v, m_did_n, m_did_v, m_did_sh500, m_did_sh300,
     m_hetero, m_hetero_v, panel, panel_did, panel_window, panel_hetero,
     nat_march, nat_feb, observed_ratio, hist_mean_ratio, excess_pct,
     nat_val_mar, nat_val_feb, observed_val_ratio, hist_mean_val_ratio, excess_val_pct,
     march_coef_n, march_se_n, march_coef_v, march_se_v,
     march_coef_sh500, march_se_sh500,
     file = "data/model_results.RData")
cat("Saved: data/model_results.RData\n")

# Update diagnostics
diag <- read_json("data/diagnostics.json")
diag$n_treated <- uniqueN(panel_did[treated==1]$code_departement)
diag$n_pre <- length(unique(panel[year < 2025]$ym))
diag$n_obs <- nrow(panel_did)
write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

scalars <- list(
  march_nat_ratio = round(observed_ratio, 3),
  hist_nat_ratio = round(hist_mean_ratio, 3),
  excess_pct = round(excess_pct, 1),
  val_ratio = round(observed_val_ratio, 3),
  hist_val_ratio = round(hist_mean_val_ratio, 3),
  excess_val_pct = round(excess_val_pct, 1),
  march_coef_n = round(march_coef_n, 3),
  march_se_n = round(march_se_n, 3),
  march_pct_n = round((exp(march_coef_n)-1)*100, 1),
  march_coef_v = round(march_coef_v, 3),
  march_se_v = round(march_se_v, 3),
  march_coef_sh500 = round(march_coef_sh500, 3),
  march_se_sh500 = round(march_se_sh500, 3)
)
write_json(scalars, "data/scalars.json", auto_unbox = TRUE)
cat("Saved: data/scalars.json\n")

cat("\n=== Main analysis complete ===\n")
