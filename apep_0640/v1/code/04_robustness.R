## 04_robustness.R — Robustness checks
## apep_0640: E-Verify Mandates and Hispanic Employment

source("00_packages.R")

cat("Loading data...\n")
df <- readRDS("../data/state_panel.rds")
everify_states <- readRDS("../data/everify_states.rds")
state_ind <- readRDS("../data/state_ind_panel.rds")

# ============================================================================
# Reconstruct annual panel (same as 03_main)
# ============================================================================
emp_avg <- df %>%
  filter(year <= 2019, state_fips != 11, !is.na(Emp)) %>%
  group_by(state_fips, year, ethnicity_label, hispanic, treated) %>%
  summarise(Emp = mean(Emp, na.rm = TRUE), .groups = "drop")

earn_avg <- df %>%
  filter(year <= 2019, state_fips != 11,
         !is.na(EarnS), !is.na(Emp), Emp > 0) %>%
  group_by(state_fips, year, ethnicity_label, hispanic) %>%
  summarise(EarnS = weighted.mean(EarnS, w = Emp), .groups = "drop")

annual <- emp_avg %>%
  left_join(earn_avg, by = c("state_fips", "year", "ethnicity_label", "hispanic")) %>%
  left_join(everify_states %>% select(state_fips, treat_year), by = "state_fips") %>%
  mutate(
    log_emp = log(Emp),
    log_earn = log(EarnS),
    first_treat = ifelse(is.na(treat_year), 0, treat_year),
    cohort = ifelse(first_treat == 0, Inf, first_treat)
  )

hisp <- annual %>% filter(hispanic == 1)

# ============================================================================
# 1. Exclude Arizona (most studied E-Verify state, Great Recession overlap)
# ============================================================================
cat("\n=== Robustness 1: Exclude Arizona ===\n")

sa_noaz <- feols(
  log_emp ~ sunab(cohort, year) | state_fips + year,
  data = hisp %>% filter(state_fips != 4),
  cluster = ~state_fips
)

sa_noaz_coefs <- coef(sa_noaz)
post_idx <- grep("^year::[0-9]", names(sa_noaz_coefs))
cat(sprintf("Avg post-treatment (excl AZ): %.4f (%.1f%%)\n",
            mean(sa_noaz_coefs[post_idx]),
            (exp(mean(sa_noaz_coefs[post_idx])) - 1) * 100))

saveRDS(sa_noaz, "../data/sa_noaz.rds")

# ============================================================================
# 2. Stacked DiD (clean 4-year windows around each cohort)
# ============================================================================
cat("\n=== Robustness 2: Stacked DiD ===\n")

cohorts <- unique(hisp$first_treat[hisp$first_treat > 0 & hisp$first_treat <= 2019])

stacked_list <- lapply(cohorts, function(g) {
  window <- (g - 4):(g + 4)
  sub <- hisp %>%
    filter(year %in% window) %>%
    filter(first_treat == g | first_treat == 0) %>%
    mutate(
      stack_id = g,
      post = as.integer(year >= g),
      treated_unit = as.integer(first_treat == g),
      state_stack = paste0(state_fips, "_", g)
    )
  return(sub)
})

stacked <- bind_rows(stacked_list)

stacked <- stacked %>%
  mutate(year_stack = paste0(year, "_", stack_id))

stacked_did <- feols(
  log_emp ~ treated_unit:post | state_stack + year_stack,
  data = stacked,
  cluster = ~state_fips
)

cat("Stacked DiD result:\n")
cat(sprintf("  β = %.4f (SE = %.4f)\n",
            coef(stacked_did), se(stacked_did)))

saveRDS(stacked_did, "../data/stacked_did.rds")

# ============================================================================
# 3. Industry Heterogeneity: High- vs Low-Immigrant Industries
# ============================================================================
cat("\n=== Robustness 3: Industry Heterogeneity ===\n")

ind_annual <- state_ind %>%
  filter(year <= 2019, !is.na(Emp), Emp > 0) %>%
  mutate(
    ethnicity_label = ifelse(ethnicity == "A2", "Hispanic", "Non-Hispanic"),
    hispanic = as.integer(ethnicity == "A2")
  ) %>%
  filter(hispanic == 1) %>%
  group_by(state_fips, year, industry, treated) %>%
  summarise(Emp = sum(Emp, na.rm = TRUE), .groups = "drop") %>%
  left_join(everify_states %>% select(state_fips, treat_year), by = "state_fips") %>%
  mutate(
    log_emp = log(Emp),
    first_treat = ifelse(is.na(treat_year), 0, treat_year),
    cohort = ifelse(first_treat == 0, Inf, first_treat),
    state_ind = paste0(state_fips, "_", industry)
  )

# High-immigrant industries
hi_immig <- c("23", "72", "11", "56")
lo_immig <- c("51", "52", "54", "62")

# High-immigrant
sa_hi <- feols(
  log_emp ~ sunab(cohort, year) | state_ind + year,
  data = ind_annual %>% filter(industry %in% hi_immig),
  cluster = ~state_fips
)

hi_coefs <- coef(sa_hi)
hi_post <- grep("^year::[0-9]", names(hi_coefs))
cat(sprintf("High-immigrant industries: avg post = %.4f (%.1f%%)\n",
            mean(hi_coefs[hi_post]),
            (exp(mean(hi_coefs[hi_post])) - 1) * 100))

# Low-immigrant (placebo)
sa_lo <- feols(
  log_emp ~ sunab(cohort, year) | state_ind + year,
  data = ind_annual %>% filter(industry %in% lo_immig),
  cluster = ~state_fips
)

lo_coefs <- coef(sa_lo)
lo_post <- grep("^year::[0-9]", names(lo_coefs))
cat(sprintf("Low-immigrant industries: avg post = %.4f (%.1f%%)\n",
            mean(lo_coefs[lo_post]),
            (exp(mean(lo_coefs[lo_post])) - 1) * 100))

saveRDS(list(sa_hi = sa_hi, sa_lo = sa_lo), "../data/sa_industry.rds")

# ============================================================================
# 4. Restrict to 2008-2016 window (exclude late adopters TN 2017+)
# ============================================================================
cat("\n=== Robustness 4: Early Adopters Only (2008-2013) ===\n")

sa_early <- feols(
  log_emp ~ sunab(cohort, year) | state_fips + year,
  data = hisp %>%
    filter(first_treat <= 2013 | first_treat == 0) %>%
    filter(year <= 2016),
  cluster = ~state_fips
)

early_coefs <- coef(sa_early)
early_post <- grep("^year::[0-9]", names(early_coefs))
cat(sprintf("Early adopters only: avg post = %.4f (%.1f%%)\n",
            mean(early_coefs[early_post]),
            (exp(mean(early_coefs[early_post])) - 1) * 100))

saveRDS(sa_early, "../data/sa_early.rds")

# ============================================================================
# 5. Randomization Inference (permute treatment assignment)
# ============================================================================
cat("\n=== Robustness 5: Randomization Inference (500 permutations) ===\n")

# Get actual ATT
sa_main <- readRDS("../data/sa_emp.rds")
actual_coefs <- coef(sa_main)
actual_post <- grep("^year::[0-9]", names(actual_coefs))
actual_att <- mean(actual_coefs[actual_post])

set.seed(42)
n_perms <- 500
perm_atts <- numeric(n_perms)
treated_states <- unique(hisp$state_fips[hisp$first_treat > 0])
all_states <- unique(hisp$state_fips)
n_treated <- length(treated_states)
actual_treats <- hisp %>%
  filter(first_treat > 0) %>%
  distinct(state_fips, first_treat) %>%
  pull(first_treat)

for (i in seq_len(n_perms)) {
  # Randomly assign treatment to n_treated states
  fake_treated <- sample(all_states, n_treated)
  # Randomly assign treatment years from actual distribution
  fake_treats <- sample(actual_treats, n_treated, replace = FALSE)

  fake_data <- hisp %>%
    mutate(
      fake_first = ifelse(state_fips %in% fake_treated,
                          fake_treats[match(state_fips, fake_treated)],
                          0),
      fake_cohort = ifelse(fake_first == 0, Inf, fake_first)
    )

  tryCatch({
    fake_sa <- feols(
      log_emp ~ sunab(fake_cohort, year) | state_fips + year,
      data = fake_data,
      warn = FALSE
    )
    fc <- coef(fake_sa)
    fp <- grep("^year::[0-9]", names(fc))
    perm_atts[i] <- if (length(fp) > 0) mean(fc[fp]) else NA_real_
  }, error = function(e) {
    perm_atts[i] <<- NA_real_
  })

  if (i %% 100 == 0) cat(sprintf("  Permutation %d/%d\n", i, n_perms))
}

perm_atts <- perm_atts[!is.na(perm_atts)]
ri_p <- mean(abs(perm_atts) >= abs(actual_att))
cat(sprintf("\nRI p-value (two-sided): %.4f\n", ri_p))
cat(sprintf("Actual ATT: %.4f, RI 2.5th: %.4f, RI 97.5th: %.4f\n",
            actual_att,
            quantile(perm_atts, 0.025),
            quantile(perm_atts, 0.975)))

saveRDS(list(actual_att = actual_att, perm_atts = perm_atts, ri_p = ri_p),
        "../data/ri_results.rds")

cat("\nRobustness checks complete.\n")
