## 03_main_analysis.R — Main regressions
## apep_0640: E-Verify Mandates and Hispanic Employment

source("00_packages.R")
library(fixest)
library(did)
library(data.table)
library(dplyr)

cat("Loading data...\n")
df <- readRDS("../data/state_panel.rds")
everify_states <- readRDS("../data/everify_states.rds")

# ============================================================================
# Prepare annual state panel (collapse quarters within year)
# ============================================================================
annual <- df %>%
  filter(year <= 2019, state_fips != 11) %>%  # Drop DC, pre-COVID
  group_by(state_fips, year, ethnicity_label, hispanic, treated, state_abbr) %>%
  summarise(
    HirA = sum(HirA, na.rm = TRUE),
    Sep = sum(Sep, na.rm = TRUE),
    .groups = "drop"
  )

# Compute earnings separately to avoid weighted.mean NA issues
earn_avg <- df %>%
  filter(year <= 2019, state_fips != 11,
         !is.na(EarnS), !is.na(Emp), Emp > 0) %>%
  group_by(state_fips, year, ethnicity_label, hispanic) %>%
  summarise(
    EarnS = weighted.mean(EarnS, w = Emp),
    .groups = "drop"
  )

emp_avg <- df %>%
  filter(year <= 2019, state_fips != 11, !is.na(Emp)) %>%
  group_by(state_fips, year, ethnicity_label, hispanic) %>%
  summarise(
    Emp = mean(Emp, na.rm = TRUE),
    .groups = "drop"
  )

annual <- annual %>%
  left_join(emp_avg, by = c("state_fips", "year", "ethnicity_label", "hispanic")) %>%
  left_join(earn_avg, by = c("state_fips", "year", "ethnicity_label", "hispanic")) %>%
  mutate(
    log_emp = log(Emp),
    log_earn = log(EarnS),
    hire_rate = HirA / (Emp * 4),
    sep_rate = Sep / (Emp * 4),
    state_eth = paste0(state_fips, "_", hispanic)
  )

# Treatment year for event study
annual <- annual %>%
  left_join(
    everify_states %>% select(state_fips, treat_year),
    by = "state_fips"
  ) %>%
  mutate(
    first_treat = ifelse(is.na(treat_year), 0, treat_year),
    post = ifelse(first_treat > 0, as.integer(year >= first_treat), 0L),
    treat_post = as.integer(treated & post == 1),
    ddd = treat_post * hispanic,
    cohort = ifelse(first_treat == 0, Inf, first_treat)
  )

cat(sprintf("Annual panel: %d states, %d years, %s obs\n",
            n_distinct(annual$state_fips),
            n_distinct(annual$year),
            format(nrow(annual), big.mark = ",")))

# ============================================================================
# A. Sun-Abraham Event Study: Hispanic employment
# ============================================================================
cat("\n=== Sun-Abraham Event Study: Hispanic Log Employment ===\n")

hisp_annual <- annual %>% filter(hispanic == 1)
nonhisp_annual <- annual %>% filter(hispanic == 0)

sa_emp <- feols(
  log_emp ~ sunab(cohort, year) | state_fips + year,
  data = hisp_annual,
  cluster = ~state_fips
)
cat("Hispanic employment event study:\n")
print(summary(sa_emp))

saveRDS(sa_emp, "../data/sa_emp.rds")

# ============================================================================
# B. Sun-Abraham: Non-Hispanic placebo
# ============================================================================
cat("\n=== Placebo: Non-Hispanic Employment ===\n")

sa_placebo <- feols(
  log_emp ~ sunab(cohort, year) | state_fips + year,
  data = nonhisp_annual,
  cluster = ~state_fips
)
cat("Non-Hispanic employment event study:\n")
print(summary(sa_placebo))

saveRDS(sa_placebo, "../data/sa_placebo.rds")

# ============================================================================
# C. DDD Regressions (fixest)
# ============================================================================
cat("\n=== DDD Regressions ===\n")

# Spec 1: log employment
# DDD: state_eth FE absorb state×ethnicity, year FE absorb time
# treat_post = DD for all workers; ddd = additional Hispanic effect
ddd1 <- feols(
  log_emp ~ treat_post + ddd |
    state_eth + year,
  data = annual,
  cluster = ~state_fips
)
cat("\nDDD — log(Employment):\n")
coef_ddd <- coef(ddd1)["ddd"]
se_ddd <- se(ddd1)["ddd"]
cat(sprintf("  β(DDD) = %.4f (SE = %.4f, t = %.2f)\n",
            coef_ddd, se_ddd, coef_ddd / se_ddd))
cat(sprintf("  Interpretation: E-Verify mandates reduce Hispanic employment by %.1f%%\n",
            (exp(coef_ddd) - 1) * 100))

# Spec 2: log earnings
ddd2 <- feols(
  log_earn ~ treat_post + ddd |
    state_eth + year,
  data = annual,
  cluster = ~state_fips
)
cat("\nDDD — log(Earnings):\n")
cat(sprintf("  β(DDD) = %.4f (SE = %.4f)\n",
            coef(ddd2)["ddd"], se(ddd2)["ddd"]))

# Spec 3: hiring rate
ddd3 <- feols(
  hire_rate ~ treat_post + ddd |
    state_eth + year,
  data = annual,
  cluster = ~state_fips
)
cat("\nDDD — Hiring Rate:\n")
cat(sprintf("  β(DDD) = %.4f (SE = %.4f)\n",
            coef(ddd3)["ddd"], se(ddd3)["ddd"]))

# Spec 4: separation rate
ddd4 <- feols(
  sep_rate ~ treat_post + ddd |
    state_eth + year,
  data = annual,
  cluster = ~state_fips
)
cat("\nDDD — Separation Rate:\n")
cat(sprintf("  β(DDD) = %.4f (SE = %.4f)\n",
            coef(ddd4)["ddd"], se(ddd4)["ddd"]))

saveRDS(list(ddd1 = ddd1, ddd2 = ddd2, ddd3 = ddd3, ddd4 = ddd4),
        "../data/ddd_models.rds")

# ============================================================================
# D. Sun-Abraham: Earnings event study
# ============================================================================
cat("\n=== Sun-Abraham: Hispanic Earnings ===\n")

sa_earn <- feols(
  log_earn ~ sunab(cohort, year) | state_fips + year,
  data = hisp_annual,
  cluster = ~state_fips
)
cat("Hispanic earnings event study:\n")
print(summary(sa_earn))

saveRDS(sa_earn, "../data/sa_earn.rds")

# ============================================================================
# E. Summary of key results
# ============================================================================
cat("\n" , paste(rep("=", 60), collapse = ""), "\n")
cat("SUMMARY OF KEY RESULTS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# SA overall ATT: average of post-treatment coefficients
sa_coefs <- coef(sa_emp)
sa_names <- names(sa_coefs)
post_idx <- grep("^year::[0-9]", sa_names)
if (length(post_idx) > 0) {
  mean_post <- mean(sa_coefs[post_idx])
  cat(sprintf("\nSA Hispanic Emp (avg post): %.4f (%.1f%%)\n",
              mean_post, (exp(mean_post) - 1) * 100))
}

cat(sprintf("\nDDD Employment: %.4f (SE %.4f)\n", coef_ddd, se_ddd))
cat(sprintf("DDD Earnings: %.4f (SE %.4f)\n",
            coef(ddd2)["ddd"], se(ddd2)["ddd"]))
cat(sprintf("DDD Hiring: %.4f (SE %.4f)\n",
            coef(ddd3)["ddd"], se(ddd3)["ddd"]))
cat(sprintf("DDD Separation: %.4f (SE %.4f)\n",
            coef(ddd4)["ddd"], se(ddd4)["ddd"]))

# ============================================================================
# F. Diagnostics for validator
# ============================================================================
n_treated <- 8  # pre-2019 cohorts
n_pre <- min(hisp_annual$first_treat[hisp_annual$first_treat > 0]) -
  min(hisp_annual$year)
n_obs <- nrow(annual)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = as.integer(n_pre),
  n_obs = n_obs,
  cs_att = as.numeric(coef_ddd),
  cs_se = as.numeric(se_ddd),
  ddd_coef = as.numeric(coef_ddd),
  ddd_se = as.numeric(se_ddd)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")
cat("Main analysis complete.\n")
