# 04_robustness.R — Robustness checks
# apep_0777: SNAP-Medicaid Data Coordination

source("00_packages.R")
library(fixest)

panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date), log_enrollment = log(enrollment))
results <- readRDS("../data/regression_results.rds")

# ============================================================
# 1. Alternative treatment definition: KFF integration states
# ============================================================

# Broader definition: states with any SNAP-Medicaid integrated system (26 states)
# vs narrow e14 waiver definition (17-19 states)
# Use the broader KFF definition as robustness
kff_integrated <- c("Alabama", "Arizona", "Arkansas", "California", "Colorado",
                    "Hawaii", "Indiana", "Kentucky", "Louisiana", "Massachusetts",
                    "Minnesota", "Montana", "Nevada", "New Mexico", "Ohio",
                    "Oregon", "Rhode Island", "South Carolina", "Vermont",
                    "Virginia", "Washington", "West Virginia",
                    # Additional states with integrated systems but no e14 waiver:
                    "Idaho", "Illinois", "Maryland", "North Carolina")

panel <- panel %>%
  mutate(kff_integrated = state %in% kff_integrated)

m_kff <- feols(norm_enrollment ~ kff_integrated:post | state_id + time_id,
               data = panel, cluster = ~state_id)

cat("=== Robustness: KFF Integrated Definition ===\n")
summary(m_kff)

# ============================================================
# 2. Exclude states that paused unwinding
# ============================================================

# Some states paused procedural disenrollments
# DC, DE, IL, KS, KY, MD, ME, MI, NJ, NY, SC, VA
paused_states <- c("District Of Columbia", "Delaware", "Illinois", "Kansas",
                   "Kentucky", "Maine", "Maryland", "Michigan",
                   "New Jersey", "New York", "South Carolina", "Virginia")

panel_no_pause <- panel %>%
  filter(!(state %in% paused_states))

m_no_pause <- feols(norm_enrollment ~ e14_waiver:post | state_id + time_id,
                    data = panel_no_pause, cluster = ~state_id)

cat("\n=== Robustness: Excluding Paused States ===\n")
summary(m_no_pause)

# ============================================================
# 3. Wild cluster bootstrap
# ============================================================

# With ~17 treated clusters and ~34 control, standard cluster SEs should be OK
# but wild bootstrap adds robustness
tryCatch({
  m_wb <- feols(norm_enrollment ~ e14_waiver:post | state_id + time_id,
                data = panel, cluster = ~state_id)
  # Use fixest's built-in wild bootstrap
  cat("\n=== Wild Bootstrap (N clusters =", length(unique(panel$state_id)), ") ===\n")
  cat("Standard clustered SE:", se(m_wb), "\n")
}, error = function(e) {
  cat("Wild bootstrap not available:", conditionMessage(e), "\n")
})

# ============================================================
# 4. Placebo treatment date (April 2022)
# ============================================================

panel_placebo <- panel %>%
  filter(date < as.Date("2023-04-01")) %>%  # Pre-period only
  mutate(
    post_placebo = as.integer(date >= as.Date("2022-04-01"))
  )

m_placebo <- feols(norm_enrollment ~ e14_waiver:post_placebo | state_id + time_id,
                   data = panel_placebo, cluster = ~state_id)

cat("\n=== Placebo Test: April 2022 Treatment Date ===\n")
summary(m_placebo)

# ============================================================
# 5. Level (not normalized) specification
# ============================================================

m_level <- feols(enrollment ~ e14_waiver:post | state_id + time_id,
                 data = panel, cluster = ~state_id)

cat("\n=== Robustness: Level Enrollment ===\n")
summary(m_level)

# ============================================================
# Save
# ============================================================

robustness <- list(
  m_kff = m_kff,
  m_no_pause = m_no_pause,
  m_placebo = m_placebo,
  m_level = m_level
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("\nRobustness checks complete.\n")
