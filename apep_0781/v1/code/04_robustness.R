## 04_robustness.R — Robustness checks
## apep_0781: UI Taxable Wage Base and Employer Separations

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/results.rds")

analysis <- panel %>%
  filter(group %in% c("Treated", "Control (Fed Min)"))

# ══════════════════════════════════════════════════════════════════
# R1. Manufacturing (mid-wage) — intermediate effect expected
# ══════════════════════════════════════════════════════════════════

cat("=== R1. Manufacturing ===\n")

mfg_data <- analysis %>%
  filter(industry_code == "31-33") %>%
  mutate(treated = as.integer(treated_state),
         post = as.integer(post_increase))

twfe_mfg <- feols(
  log_sep ~ i(post, treated, ref = 0L) | state_fips + yq,
  data = mfg_data,
  cluster = ~state_fips
)
cat("Manufacturing separations:\n")
print(summary(twfe_mfg))

# ══════════════════════════════════════════════════════════════════
# R2. Exclude 2008-2010 crisis years
# ══════════════════════════════════════════════════════════════════

cat("\n=== R2. Exclude Great Recession ===\n")

no_crisis <- analysis %>%
  filter(low_wage, !(year %in% 2008:2010)) %>%
  mutate(treated = as.integer(treated_state),
         post = as.integer(post_increase))

twfe_no_crisis <- feols(
  log_sep ~ i(post, treated, ref = 0L) | state_fips + yq + industry_code,
  data = no_crisis,
  cluster = ~state_fips
)
cat("Low-wage separations (excl 2008-2010):\n")
print(summary(twfe_no_crisis))

# ══════════════════════════════════════════════════════════════════
# R3. Hiring effects (mirror of separations)
# ══════════════════════════════════════════════════════════════════

cat("\n=== R3. Hiring Effects ===\n")

low_wage_data <- analysis %>%
  filter(low_wage, !is.na(HirN), HirN > 0) %>%
  mutate(treated = as.integer(treated_state),
         post = as.integer(post_increase),
         log_hir = log(HirN + 1))

twfe_hir <- feols(
  log_hir ~ i(post, treated, ref = 0L) | state_fips + yq + industry_code,
  data = low_wage_data,
  cluster = ~state_fips
)
cat("Low-wage hiring:\n")
print(summary(twfe_hir))

# ══════════════════════════════════════════════════════════════════
# R4. Include "Other" states (broader control group)
# ══════════════════════════════════════════════════════════════════

cat("\n=== R4. Broader control group ===\n")

broad_data <- panel %>%
  filter(low_wage, !is.na(Emp), Emp > 0) %>%
  mutate(treated = as.integer(treated_state),
         post = as.integer(post_increase))

twfe_broad <- feols(
  log_sep ~ i(post, treated, ref = 0L) | state_fips + yq + industry_code,
  data = broad_data,
  cluster = ~state_fips
)
cat("Broad control group:\n")
print(summary(twfe_broad))

# ══════════════════════════════════════════════════════════════════
# Save
# ══════════════════════════════════════════════════════════════════

rob_results <- list(
  twfe_mfg = twfe_mfg,
  twfe_no_crisis = twfe_no_crisis,
  twfe_hir = twfe_hir,
  twfe_broad = twfe_broad
)

saveRDS(rob_results, "../data/rob_results.rds")
cat("\nRobustness results saved.\n")
