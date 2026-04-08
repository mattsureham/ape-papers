## 04_robustness.R — Robustness checks
## Paper: apep_1431 — France DMTO Composition Illusion

library(data.table)
library(fixest)
library(tidyverse)
library(jsonlite)

cat("=== Robustness Checks: apep_1431 ===\n")

panel <- fread("data/dept_panel/dept_month_panel.csv")
panel_did <- panel[!is.na(treated)]

# Add event variables
for (p in list(panel, panel_did)) {
  p[, march_2025 := as.integer(year == 2025 & month == 3)]
  p[, feb_2025   := as.integer(year == 2025 & month == 2)]
  p[, apr_2025   := as.integer(year == 2025 & month == 4)]
}
panel[, march_2025 := as.integer(year == 2025 & month == 3)]
panel[, feb_2025   := as.integer(year == 2025 & month == 2)]
panel[, apr_2025   := as.integer(year == 2025 & month == 4)]
panel_did[, march_2025 := as.integer(year == 2025 & month == 3)]
panel_did[, feb_2025   := as.integer(year == 2025 & month == 2)]
panel_did[, apr_2025   := as.integer(year == 2025 & month == 4)]
panel_did[, treat_march25 := treated * march_2025]
panel_did[, treat_feb25   := treated * feb_2025]
panel_did[, treat_apr25   := treated * apr_2025]

# -------------------------------------------------------------------
# R1. Main result (reference)
# -------------------------------------------------------------------
m_main <- feols(log_n ~ treat_march25 + treat_feb25 + treat_apr25 |
                  code_departement + ym,
                data = panel_did, cluster = ~code_departement)
cat("\nMain specification (reference):\n")
print(summary(m_main))

# -------------------------------------------------------------------
# R2. Placebo: "March 2024" fake rush
# -------------------------------------------------------------------
cat("\n=== R2: Placebo — March 2024 ===\n")

panel_plac <- panel_did[year <= 2024]
panel_plac[, march_plac := as.integer(year == 2024 & month == 3)]
panel_plac[, feb_plac   := as.integer(year == 2024 & month == 2)]
panel_plac[, apr_plac   := as.integer(year == 2024 & month == 4)]
panel_plac[, treat_march_p := treated * march_plac]
panel_plac[, treat_feb_p   := treated * feb_plac]
panel_plac[, treat_apr_p   := treated * apr_plac]

m_plac <- feols(log_n ~ treat_march_p + treat_feb_p + treat_apr_p |
                  code_departement + ym,
                data = panel_plac, cluster = ~code_departement)
cat("Placebo DiD (fake March 2024 rush):\n")
print(summary(m_plac))

# -------------------------------------------------------------------
# R3. Placebo: March 2023
# -------------------------------------------------------------------
cat("\n=== R3: Placebo — March 2023 ===\n")

panel_plac23 <- panel_did[year <= 2023]
panel_plac23[, treat_march23 := treated * as.integer(year==2023 & month==3)]
panel_plac23[, treat_feb23   := treated * as.integer(year==2023 & month==2)]
panel_plac23[, treat_apr23   := treated * as.integer(year==2023 & month==4)]

m_plac23 <- feols(log_n ~ treat_march23 + treat_feb23 + treat_apr23 |
                    code_departement + ym,
                  data = panel_plac23, cluster = ~code_departement)
cat("Placebo DiD (fake March 2023 rush):\n")
print(summary(m_plac23))

# -------------------------------------------------------------------
# R4. Non-residential transactions (should show no March rush — placebo outcome)
# -------------------------------------------------------------------
cat("\n=== R4: Non-residential placebo outcome ===\n")

panel_other <- fread("data/dept_panel/dept_month_panel_other.csv")
panel_other_did <- panel_other[!is.na(treated)]
panel_other_did[, march_2025 := as.integer(year == 2025 & month == 3)]
panel_other_did[, feb_2025   := as.integer(year == 2025 & month == 2)]
panel_other_did[, apr_2025   := as.integer(year == 2025 & month == 4)]
panel_other_did[, treat_march25 := treated * march_2025]
panel_other_did[, treat_feb25   := treated * feb_2025]
panel_other_did[, treat_apr25   := treated * apr_2025]
panel_other_did[, log_n_other := log(n_other + 1)]

m_other <- feols(log_n_other ~ treat_march25 + treat_feb25 + treat_apr25 |
                   code_departement + ym,
                 data = panel_other_did[year >= 2021], cluster = ~code_departement)
cat("Non-residential DiD (should show no rush):\n")
print(summary(m_other))

# -------------------------------------------------------------------
# R5. Including ambiguous departments
# -------------------------------------------------------------------
cat("\n=== R5: Full sample (including ambiguous departments) ===\n")

# For ambiguous departments, set treated based on excess_ratio > 1.10
panel_full <- copy(panel)
panel_full[is.na(treated) & excess_ratio > 1.10, treated := 1L]
panel_full[is.na(treated) & excess_ratio <= 1.10, treated := 0L]
panel_full[, march_2025 := as.integer(year == 2025 & month == 3)]
panel_full[, feb_2025   := as.integer(year == 2025 & month == 2)]
panel_full[, apr_2025   := as.integer(year == 2025 & month == 4)]
panel_full[, treat_march25 := treated * march_2025]
panel_full[, treat_feb25   := treated * feb_2025]
panel_full[, treat_apr25   := treated * apr_2025]

m_full <- feols(log_n ~ treat_march25 + treat_feb25 + treat_apr25 |
                  code_departement + ym,
                data = panel_full[!is.na(treated)], cluster = ~code_departement)
cat("Full sample (including ambiguous, broader treated definition):\n")
print(summary(m_full))

# -------------------------------------------------------------------
# R6. Narrower window (only months 1-4, 2024-2025)
# -------------------------------------------------------------------
cat("\n=== R6: Narrow window 2024-2025 ===\n")

m_narrow <- feols(log_n ~ treat_march25 + treat_feb25 + treat_apr25 |
                    code_departement + ym,
                  data = panel_did[year >= 2024 & month <= 4], cluster = ~code_departement)
cat("Narrow window (2024-2025, months 1-4):\n")
print(summary(m_narrow))

# -------------------------------------------------------------------
# Save
# -------------------------------------------------------------------
save(m_main, m_plac, m_plac23, m_other, m_full, m_narrow,
     file = "data/robustness_results.RData")
cat("\nSaved: data/robustness_results.RData\n")
cat("\n=== Robustness complete ===\n")
