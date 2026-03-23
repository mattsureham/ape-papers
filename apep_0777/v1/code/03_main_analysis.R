# 03_main_analysis.R — Main DiD analysis
# apep_0777: SNAP-Medicaid Data Coordination

source("00_packages.R")
library(fixest)

panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date))

cat("Panel:", nrow(panel), "state-months\n")

# ============================================================
# 1. Main DiD: Normalized enrollment
# ============================================================

# Model 1: Simple DiD
m1 <- feols(norm_enrollment ~ e14_waiver:post | state_id + time_id,
            data = panel, cluster = ~state_id)

cat("\n=== Model 1: DiD on Normalized Enrollment ===\n")
summary(m1)

# Model 2: Log enrollment
panel <- panel %>%
  mutate(log_enrollment = log(enrollment))

m2 <- feols(log_enrollment ~ e14_waiver:post | state_id + time_id,
            data = panel, cluster = ~state_id)

cat("\n=== Model 2: DiD on Log Enrollment ===\n")
summary(m2)

# ============================================================
# 2. Event Study
# ============================================================

# Create event-time dummies (relative to April 2023)
# Bin endpoints at -12 and +12
panel <- panel %>%
  mutate(
    month_rel_binned = pmax(pmin(month_rel, 12), -12)
  )

m3_es <- feols(norm_enrollment ~ i(month_rel_binned, e14_waiver, ref = -1) |
                 state_id + time_id,
               data = panel, cluster = ~state_id)

cat("\n=== Model 3: Event Study ===\n")
summary(m3_es)

# Extract event study coefficients for table
coef_names <- names(coef(m3_es))
# Pattern: "month_rel_binned::-5:e14_waiver" or "month_rel_binned::5:e14_waiver"
month_nums <- as.integer(str_extract(coef_names, "-?[0-9]+"))
es_coefs <- data.frame(
  month = month_nums,
  estimate = as.numeric(coef(m3_es)),
  se = as.numeric(se(m3_es))
) %>%
  filter(!is.na(month)) %>%
  mutate(
    ci_low = estimate - 1.96 * se,
    ci_high = estimate + 1.96 * se
  )

cat("\n=== Event Study Coefficients ===\n")
print(es_coefs)

# ============================================================
# 3. Heterogeneity: Expansion vs Non-Expansion States
# ============================================================

# States that expanded Medicaid have larger enrollment bases
# The unwinding effect might differ
expansion_states <- c("Alaska", "Arizona", "Arkansas", "California", "Colorado",
                      "Connecticut", "Delaware", "District Of Columbia", "Hawaii",
                      "Idaho", "Illinois", "Indiana", "Iowa", "Kentucky",
                      "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan",
                      "Minnesota", "Missouri", "Montana", "Nebraska", "Nevada",
                      "New Hampshire", "New Jersey", "New Mexico", "New York",
                      "North Carolina", "North Dakota", "Ohio", "Oklahoma",
                      "Oregon", "Pennsylvania", "Rhode Island", "South Dakota",
                      "Utah", "Vermont", "Virginia", "Washington",
                      "West Virginia", "Wisconsin")

panel <- panel %>%
  mutate(expansion = state %in% expansion_states)

m4_het <- feols(norm_enrollment ~ e14_waiver:post:expansion +
                  e14_waiver:post:I(!expansion) | state_id + time_id,
                data = panel, cluster = ~state_id)

cat("\n=== Model 4: Heterogeneity by Expansion Status ===\n")
summary(m4_het)

# ============================================================
# 4. Dynamic effect: post-period quarters
# ============================================================

panel <- panel %>%
  mutate(
    post_q1 = as.integer(date >= as.Date("2023-04-01") & date <= as.Date("2023-06-01")),
    post_q2 = as.integer(date >= as.Date("2023-07-01") & date <= as.Date("2023-09-01")),
    post_q3 = as.integer(date >= as.Date("2023-10-01") & date <= as.Date("2023-12-01")),
    post_q4 = as.integer(date >= as.Date("2024-01-01") & date <= as.Date("2024-03-01")),
    post_q5plus = as.integer(date >= as.Date("2024-04-01"))
  )

m5_dyn <- feols(norm_enrollment ~ e14_waiver:(post_q1 + post_q2 + post_q3 + post_q4 + post_q5plus) |
                  state_id + time_id,
                data = panel, cluster = ~state_id)

cat("\n=== Model 5: Dynamic Post-Period Effects ===\n")
summary(m5_dyn)

# ============================================================
# 5. Diagnostics
# ============================================================

diagnostics <- list(
  n_treated = n_distinct(panel$state[panel$e14_waiver == TRUE]),
  n_pre = n_distinct(panel$date[panel$post == 0]),
  n_obs = nrow(panel)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Diagnostics ===\n")
cat("E14 states (treated):", diagnostics$n_treated, "\n")
cat("Pre-treatment months:", diagnostics$n_pre, "\n")
cat("Total observations:", diagnostics$n_obs, "\n")

# ============================================================
# Save results
# ============================================================

saveRDS(list(
  m1_did = m1, m2_log = m2, m3_es = m3_es,
  m4_het = m4_het, m5_dyn = m5_dyn,
  es_coefs = es_coefs
), "../data/regression_results.rds")

cat("\nAnalysis complete.\n")
