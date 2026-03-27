## 04_robustness.R — Robustness checks for CROWN Act analysis
## apep_1066 v1

source("00_packages.R")
load("../data/analysis_panel.RData")
load("../data/results.RData")

## ============================================================
## 1. LEAVE-ONE-OUT: Drop each early adopter (CA, NY, NJ)
## ============================================================

early_adopters <- c("06", "36", "34")  # CA, NY, NJ
loo_results <- list()

for (st in early_adopters) {
  sub <- panel %>% filter(state_fips != st)
  m <- feols(
    log_earn ~ crown_black |
      state_fips^race + year^race + state_fips^year,
    data = sub,
    cluster = ~state_fips
  )
  loo_results[[st]] <- tibble(
    dropped_state = st,
    coef = coef(m)["crown_black"],
    se = se(m)["crown_black"],
    pval = pvalue(m)["crown_black"]
  )
}

loo_df <- bind_rows(loo_results)
cat("\n=== Leave-One-Out (Drop Early Adopter) ===\n")
print(loo_df)

## ============================================================
## 2. ALTERNATIVE COMPARISON: Black women vs White women only
## ============================================================

female_panel <- panel %>% filter(sex == "female")

m_female_only <- feols(
  log_earn ~ crown_black |
    state_fips^race + year^race + state_fips^year,
  data = female_panel,
  cluster = ~state_fips
)

cat("\n=== Black Women vs White Women (Female Only) ===\n")
summary(m_female_only)

## ============================================================
## 3. PLACEBO: White Male outcomes (should show no effect)
## ============================================================

## White males should not be affected by CROWN Act
## Run same DDD spec but with white_male as "treated" demographic
## If CROWN affects white male earnings, something is wrong
placebo_panel <- panel %>%
  mutate(
    placebo_treated = as.integer(race == "White" & sex == "male"),
    crown_placebo = crown_active * placebo_treated
  )

m_placebo <- feols(
  log_earn ~ crown_placebo |
    state_fips^demo_group + year^demo_group + state_fips^year,
  data = placebo_panel,
  cluster = ~state_fips
)

cat("\n=== Placebo: CROWN × White Male ===\n")
summary(m_placebo)

## ============================================================
## 4. HETEROGENEITY BY BLACK POPULATION SHARE
## ============================================================

## States with larger Black populations should have stronger effects
## (more Black workers affected → larger aggregate earnings gains)
black_pop <- panel %>%
  filter(year == 2017, race == "Black") %>%
  group_by(state_fips) %>%
  summarise(black_pop_total = sum(as.numeric(median_earnings), na.rm = TRUE)) %>%
  ungroup()

## Use 2017 Black pop total as a proxy — get actual from ACS
## Better: use Black share of population
## Fetch B02001: Race totals
## For now, use a binary split: above/below median of treated states

## Actually, use employment population as a proxy for Black presence
emp_base <- panel %>%
  filter(year == 2017, race == "Black") %>%
  group_by(state_fips) %>%
  summarise(base_emp = mean(emp_rate, na.rm = TRUE), .groups = "drop")

med_emp <- median(emp_base$base_emp, na.rm = TRUE)

panel_het <- panel %>%
  left_join(emp_base, by = "state_fips") %>%
  mutate(
    high_black_emp = as.integer(base_emp >= med_emp),
    crown_black_high = crown_black * high_black_emp,
    crown_black_low = crown_black * (1 - high_black_emp)
  )

m_het <- feols(
  log_earn ~ crown_black_high + crown_black_low |
    state_fips^race + year^race + state_fips^year,
  data = panel_het,
  cluster = ~state_fips
)

cat("\n=== Heterogeneity by Black Employment Rate (Above/Below Median) ===\n")
summary(m_het)

## ============================================================
## 5. RANDOMIZATION INFERENCE (permutation test)
## ============================================================

## Permute treatment assignment across states 500 times
set.seed(42)
n_perms <- 500
true_coef <- coef(m1_earn)["crown_black"]

perm_coefs <- numeric(n_perms)

state_list <- unique(panel$state_fips)
n_treated_states <- n_distinct(panel$state_fips[panel$ever_treated])

for (i in seq_len(n_perms)) {
  ## Randomly assign same number of states as treated
  fake_treated <- sample(state_list, n_treated_states, replace = FALSE)

  ## Assign random treatment years from actual distribution
  actual_years <- panel %>%
    filter(ever_treated) %>%
    distinct(state_fips, crown_year) %>%
    pull(crown_year)
  fake_years <- sample(actual_years, n_treated_states, replace = TRUE)

  perm_panel <- panel %>%
    mutate(
      fake_crown_year = ifelse(state_fips %in% fake_treated,
                                fake_years[match(state_fips, fake_treated)],
                                0),
      fake_crown_active = as.integer(fake_crown_year > 0 & year >= fake_crown_year),
      fake_crown_black = fake_crown_active * black
    )

  m_perm <- tryCatch(
    feols(
      log_earn ~ fake_crown_black |
        state_fips^race + year^race + state_fips^year,
      data = perm_panel,
      cluster = ~state_fips
    ),
    error = function(e) NULL
  )

  if (!is.null(m_perm)) {
    perm_coefs[i] <- coef(m_perm)["fake_crown_black"]
  } else {
    perm_coefs[i] <- NA
  }
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
ri_pvalue <- mean(abs(perm_coefs) >= abs(true_coef))

cat(sprintf("\n=== Randomization Inference ===\n"))
cat(sprintf("True coefficient: %.4f\n", true_coef))
cat(sprintf("RI p-value (two-sided): %.3f\n", ri_pvalue))
cat(sprintf("Permutations used: %d\n", length(perm_coefs)))

## ============================================================
## 6. SAVE ROBUSTNESS RESULTS
## ============================================================

save(loo_df, m_female_only, m_placebo, m_het,
     ri_pvalue, perm_coefs, true_coef,
     file = "../data/robustness.RData")
cat("Robustness results saved to data/robustness.RData\n")
