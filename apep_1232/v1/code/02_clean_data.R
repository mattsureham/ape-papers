## 02_clean_data.R — Construct treatment variables and analysis sample
## APEP-1232: Medicaid Doula Reimbursement and Birth Outcomes

source("00_packages.R")

panel <- readRDS("../data/natality_panel.rds")

# Panel already has 'state' (abbreviation) and 'dob_yy' from 01_fetch_data.R
panel <- panel %>% rename(year = dob_yy)

cat("States in panel:", n_distinct(panel$state), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")

# ─── Treatment coding: Medicaid doula reimbursement adoption year ────────────
# Source: National Academy for State Health Policy (NASHP), National Health
# Law Program, Kaiser Family Foundation doula coverage trackers
#
# Coding rule: year of policy implementation (SPA effective date).
# For mid-year adoptions, code to that calendar year since doula support
# at birth benefits births from the adoption month forward.

doula_adoption <- data.frame(
  state = c("OR", "MN",           # Pre-sample (2014)
            "MD", "VA", "NV",     # 2022 cohort
            "DC",                  # 2022 cohort
            "MI", "CA", "OK", "MA" # 2023 cohort
            ),
  adopt_year = c(2014, 2014,
                 2022, 2022, 2022,
                 2022,
                 2023, 2023, 2023, 2023),
  stringsAsFactors = FALSE
)

panel <- panel %>%
  left_join(doula_adoption, by = "state") %>%
  mutate(
    # For Callaway-Sant'Anna: first_treat = adoption year, 0 for never-treated
    first_treat = ifelse(is.na(adopt_year), 0L, as.integer(adopt_year)),
    # Binary post-treatment indicator
    treated_post = as.integer(!is.na(adopt_year) & year >= adopt_year),
    # Treatment group labels
    treat_group = case_when(
      is.na(adopt_year) ~ "Never treated",
      adopt_year <= 2017 ~ "Always treated (pre-2018)",
      TRUE ~ paste0("Cohort ", adopt_year)
    ),
    # Medicaid indicator
    is_medicaid = as.integer(payer == "medicaid")
  )

# ─── Summary statistics ──────────────────────────────────────────────────────
cat("\n========== TREATMENT GROUPS ==========\n")
panel %>%
  filter(payer == "medicaid") %>%
  group_by(treat_group) %>%
  summarise(
    states = n_distinct(state),
    state_list = paste(sort(unique(state)), collapse = ", "),
    mean_csrate = round(weighted.mean(csection_rate, births), 3),
    total_births = format(sum(births), big.mark = ","),
    .groups = "drop"
  ) %>%
  print(width = 200)

cat("\n========== PAYER BALANCE ==========\n")
panel %>%
  group_by(payer) %>%
  summarise(
    total_births = format(sum(births), big.mark = ","),
    mean_csrate = round(weighted.mean(csection_rate, births), 3),
    mean_preterm = round(weighted.mean(preterm_rate, births), 3),
    .groups = "drop"
  ) %>%
  print()

# ─── Create numeric state ID for DiD ────────────────────────────────────────
panel <- panel %>%
  mutate(state_id = as.integer(factor(state)))

# ─── Save analysis dataset ───────────────────────────────────────────────────
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nSaved analysis panel:", nrow(panel), "rows\n")

# ─── Summary for validation ─────────────────────────────────────────────────
cat("\n========== DESIGN PARAMETERS ==========\n")
n_treated <- n_distinct(panel$state[panel$first_treat > 0 & panel$first_treat <= 2023])
n_never <- n_distinct(panel$state[panel$first_treat == 0])
n_pre <- length(unique(panel$year[panel$year < 2022]))
cat("Treated states (in sample):", n_treated, "\n")
cat("Never-treated states:", n_never, "\n")
cat("Pre-periods (before first 2022 cohort):", n_pre, "\n")
cat("Total state-year-payer cells:", nrow(panel), "\n")
