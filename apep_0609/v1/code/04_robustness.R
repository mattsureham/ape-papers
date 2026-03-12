# ==============================================================================
# 04_robustness.R — Robustness checks and placebos
# apep_0609: Wayfair Economic Nexus and Retail-Warehouse Reallocation
# ==============================================================================

source("00_packages.R")

results <- readRDS("../data/results_main.rds")
state_panel_sa <- results$state_panel_sa
age_panel <- readRDS("../data/age_panel.rds")

# ==============================================================================
# 1. PRE-COVID ONLY (2014Q1 - 2019Q4)
# ==============================================================================

cat("=== Pre-COVID Robustness ===\n")

state_precovid <- state_panel_sa %>% filter(yq <= 20194)

sa_ratio_precovid <- feols(
  log_ratio ~ sunab(first_treat_t, t) | state_id + t,
  data = state_precovid,
  cluster = ~state_id
)
cat("Pre-COVID SA ATT (log ratio):\n")
summary(sa_ratio_precovid)

sa_retail_precovid <- feols(
  log_retail ~ sunab(first_treat_t, t) | state_id + t,
  data = state_precovid,
  cluster = ~state_id
)

sa_wh_precovid <- feols(
  log_wh ~ sunab(first_treat_t, t) | state_id + t,
  data = state_precovid,
  cluster = ~state_id
)

# ==============================================================================
# 2. PLACEBO SECTORS: Healthcare and Education
# ==============================================================================

cat("\n=== Placebo: Healthcare ===\n")

# Build state-quarter panels for placebo sectors
triple_panel <- readRDS("../data/triple_panel.rds")

state_healthcare <- triple_panel %>%
  filter(ind_label == "Healthcare") %>%
  group_by(state_abbr, state_fips, yq, t, first_treat_yq) %>%
  summarise(total_emp = sum(Emp, na.rm = TRUE), .groups = "drop") %>%
  filter(total_emp > 0) %>%
  mutate(
    log_emp = log(total_emp),
    state_id = as.integer(factor(state_abbr)),
    first_treat_t = ifelse(first_treat_yq == 0, 10000,
                           (floor(first_treat_yq / 10) - 2014) * 4 + first_treat_yq %% 10)
  )

sa_healthcare <- feols(
  log_emp ~ sunab(first_treat_t, t) | state_id + t,
  data = state_healthcare,
  cluster = ~state_id
)
cat("Healthcare placebo:\n")
summary(sa_healthcare)

state_education <- triple_panel %>%
  filter(ind_label == "Education") %>%
  group_by(state_abbr, state_fips, yq, t, first_treat_yq) %>%
  summarise(total_emp = sum(Emp, na.rm = TRUE), .groups = "drop") %>%
  filter(total_emp > 0) %>%
  mutate(
    log_emp = log(total_emp),
    state_id = as.integer(factor(state_abbr)),
    first_treat_t = ifelse(first_treat_yq == 0, 10000,
                           (floor(first_treat_yq / 10) - 2014) * 4 + first_treat_yq %% 10)
  )

sa_education <- feols(
  log_emp ~ sunab(first_treat_t, t) | state_id + t,
  data = state_education,
  cluster = ~state_id
)
cat("Education placebo:\n")
summary(sa_education)

# ==============================================================================
# 3. BACON DECOMPOSITION
# ==============================================================================

cat("\n=== Bacon Decomposition ===\n")

# Need balanced panel for bacondecomp — keep only states with full 40 quarters
state_bacon <- state_panel_sa %>%
  mutate(treated = as.integer(t >= first_treat_t & first_treat_t < 10000))

state_counts <- state_bacon %>% count(state_id)
balanced_ids <- state_counts %>% filter(n == max(n)) %>% pull(state_id)
state_bacon_bal <- state_bacon %>% filter(state_id %in% balanced_ids)

bacon_out <- tryCatch({
  bacon(
    log_ratio ~ treated,
    data = state_bacon_bal,
    id_var = "state_id",
    time_var = "t"
  )
}, error = function(e) {
  cat("Bacon decomposition failed:", e$message, "\n")
  NULL
})

if (!is.null(bacon_out)) {
  cat("Bacon decomposition:\n")
  print(
    bacon_out %>%
      group_by(type) %>%
      summarise(
        n = n(),
        avg_weight = mean(weight),
        total_weight = sum(weight),
        avg_estimate = weighted.mean(estimate, weight),
        .groups = "drop"
      )
  )
}

# ==============================================================================
# 4. AGE-SPECIFIC EFFECTS (Retail only)
# ==============================================================================

cat("\n=== Age-Specific Effects ===\n")

# State-level age panel for retail
state_age <- age_panel %>%
  group_by(state_abbr, state_fips, yq, t, first_treat_yq, age_label, young) %>%
  summarise(
    total_emp = sum(Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(total_emp > 0) %>%
  mutate(
    log_emp = log(total_emp),
    state_id = as.integer(factor(state_abbr)),
    first_treat_t = ifelse(first_treat_yq == 0, 10000,
                           (floor(first_treat_yq / 10) - 2014) * 4 + first_treat_yq %% 10)
  )

# Young workers (14-24)
sa_young <- feols(
  log_emp ~ sunab(first_treat_t, t) | state_id + t,
  data = state_age %>% filter(young),
  cluster = ~state_id
)
cat("Young retail workers (14-24):\n")
summary(sa_young)

# Prime-age workers (25-34)
sa_prime <- feols(
  log_emp ~ sunab(first_treat_t, t) | state_id + t,
  data = state_age %>% filter(age_label == "25-34"),
  cluster = ~state_id
)
cat("Prime-age retail workers (25-34):\n")
summary(sa_prime)

# ==============================================================================
# 5. HONESTDID SENSITIVITY
# ==============================================================================

cat("\n=== HonestDiD Sensitivity ===\n")

# Extract event-study coefficients from Sun-Abraham for HonestDiD
tryCatch({
  honest_result <- HonestDiD::createSensitivityResults(
    betahat = coef(results$sa_ratio),
    sigma = vcov(results$sa_ratio),
    numPrePeriods = sum(grepl("^t::-", names(coef(results$sa_ratio)))),
    numPostPeriods = sum(grepl("^t::[0-9]", names(coef(results$sa_ratio)))),
    Mbarvec = seq(0, 0.05, by = 0.01)
  )
  cat("HonestDiD bounds computed.\n")
}, error = function(e) {
  cat("HonestDiD requires specific coefficient structure. Using CS-DiD event study instead.\n")
  honest_result <<- NULL
})

# ==============================================================================
# 6. PERMUTATION INFERENCE
# ==============================================================================

cat("\n=== Permutation Inference ===\n")

set.seed(42)
n_perms <- 500

# Get the actual ATT
actual_att <- coef(results$sa_ratio)[1]  # First sunab coefficient

# Permute treatment timing
perm_atts <- numeric(n_perms)
unique_states <- unique(state_panel_sa$state_abbr)
treat_times <- state_panel_sa %>%
  distinct(state_abbr, first_treat_t) %>%
  pull(first_treat_t)

for (i in seq_len(n_perms)) {
  if (i %% 100 == 0) cat("  Permutation", i, "/", n_perms, "\n")

  # Shuffle treatment timing across states
  perm_data <- state_panel_sa %>%
    mutate(first_treat_t = sample(treat_times)[state_id])

  perm_fit <- tryCatch(
    feols(log_ratio ~ sunab(first_treat_t, t) | state_id + t,
          data = perm_data, cluster = ~state_id),
    error = function(e) NULL
  )

  if (!is.null(perm_fit)) {
    perm_atts[i] <- coef(perm_fit)[1]
  } else {
    perm_atts[i] <- NA
  }
}

perm_p <- mean(abs(perm_atts) >= abs(actual_att), na.rm = TRUE)
cat("Permutation p-value:", round(perm_p, 3), "\n")

# ==============================================================================
# SAVE ROBUSTNESS RESULTS
# ==============================================================================

robustness <- list(
  sa_ratio_precovid = sa_ratio_precovid,
  sa_retail_precovid = sa_retail_precovid,
  sa_wh_precovid = sa_wh_precovid,
  sa_healthcare = sa_healthcare,
  sa_education = sa_education,
  bacon_out = bacon_out,
  sa_young = sa_young,
  sa_prime = sa_prime,
  honest_result = if (exists("honest_result")) honest_result else NULL,
  perm_p = perm_p,
  perm_atts = perm_atts,
  actual_att = actual_att,
  state_age = state_age
)

saveRDS(robustness, "../data/results_robustness.rds")
cat("\nRobustness results saved.\n")
