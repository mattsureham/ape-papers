## 04_robustness.R — Robustness checks for PSL paper
## apep_0704: Paid Sick Leave and Worker Separation Dynamics

source("00_packages.R")

cat("=== Running robustness checks ===\n")

# ── Load data ──
qwi_main <- readRDS("../data/qwi_main.rds")
qwi_age <- readRDS("../data/qwi_age.rds")
results <- readRDS("../data/main_results.rds")

# ────────────────────────────────────────────────────────────────────
# TABLE 4: Industry Heterogeneity (by NAICS sector)
# ────────────────────────────────────────────────────────────────────
cat("\n--- Table 4: Industry Heterogeneity ---\n")

# Run separate DDD for each high-exposure industry
industries <- c("72", "44-45", "62")
ind_names <- c("Accommodation/Food", "Retail", "Healthcare")

ind_results <- list()
for (i in seq_along(industries)) {
  ind_data <- qwi_main %>%
    filter(industry %in% c(industries[i], "52", "54")) %>%
    mutate(
      target_ind = industry == industries[i],
      treated_post_target = treated_state & post & target_ind
    )

  mod <- feols(
    sep_rate ~ treated_post_target |
      state_abbr^industry + state_abbr^time_period + industry^time_period,
    data = ind_data,
    cluster = ~state_abbr
  )
  ind_results[[ind_names[i]]] <- mod
  cat(sprintf("  %s: coef = %.3f (SE = %.3f)\n",
              ind_names[i], coef(mod), se(mod)))
}

# ────────────────────────────────────────────────────────────────────
# TABLE 5: Age Heterogeneity
# ────────────────────────────────────────────────────────────────────
cat("\n--- Table 5: Age Heterogeneity ---\n")

age_results <- list()
age_groups <- c("14-18", "19-21", "22-24", "25-34", "35-44", "45-54", "55-64", "65+")

for (ag in age_groups) {
  ag_data <- qwi_age %>%
    filter(age_group == ag, industry %in% c("72", "44-45", "62", "52", "54")) %>%
    mutate(
      treated_post_high = treated_state & post & high_exposure,
      state_ind = paste(state_abbr, industry, sep = "_")
    )

  if (nrow(ag_data) < 100) {
    cat(sprintf("  %s: insufficient data (%d rows)\n", ag, nrow(ag_data)))
    next
  }

  mod <- tryCatch(
    feols(
      sep_rate ~ treated_post_high |
        state_abbr^industry + state_abbr^time_period + industry^time_period,
      data = ag_data,
      cluster = ~state_abbr
    ),
    error = function(e) {
      cat(sprintf("  %s: estimation error — %s\n", ag, e$message))
      NULL
    }
  )

  if (!is.null(mod)) {
    age_results[[ag]] <- mod
    cat(sprintf("  %s: coef = %.3f (SE = %.3f)\n", ag, coef(mod), se(mod)))
  }
}

# ────────────────────────────────────────────────────────────────────
# ROBUSTNESS: Placebo — Finance & Professional Services only
# ────────────────────────────────────────────────────────────────────
cat("\n--- Placebo: Low-Exposure Industries Only ---\n")

placebo_data <- qwi_main %>%
  filter(low_exposure) %>%
  mutate(treated_post = treated_state & post)

placebo_mod <- feols(
  sep_rate ~ treated_post | state_abbr + time_period,
  data = placebo_data,
  cluster = ~state_abbr
)

cat(sprintf("Placebo (Finance + Prof Svcs): coef = %.3f (SE = %.3f, p = %.3f)\n",
            coef(placebo_mod), se(placebo_mod), pvalue(placebo_mod)))

# ────────────────────────────────────────────────────────────────────
# ROBUSTNESS: Leave-one-state-out
# ────────────────────────────────────────────────────────────────────
cat("\n--- Leave-One-State-Out ---\n")

treated_states <- c("CT","CA","MA","OR","VT","AZ","WA","MD","RI","NJ",
                    "MI","NV","NY","CO","ME","NM")

loo_results <- data.frame(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

ddd_data <- qwi_main %>%
  filter(industry %in% c("72", "44-45", "62", "52", "54")) %>%
  mutate(treated_post_high = treated_state & post & high_exposure)

for (st in treated_states) {
  mod_loo <- feols(
    sep_rate ~ treated_post_high |
      state_abbr^industry + state_abbr^time_period + industry^time_period,
    data = ddd_data %>% filter(state_abbr != st),
    cluster = ~state_abbr
  )
  loo_results <- rbind(loo_results, data.frame(
    dropped = st, coef = coef(mod_loo), se = se(mod_loo)
  ))
}

cat("Leave-one-out range:\n")
cat(sprintf("  Coef range: [%.3f, %.3f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  Baseline: %.3f\n", coef(results$ddd_1)))

# ────────────────────────────────────────────────────────────────────
# ROBUSTNESS: Exclude COVID window (2020Q1–2021Q2)
# ────────────────────────────────────────────────────────────────────
cat("\n--- Excluding COVID Window ---\n")

ddd_nocovid <- feols(
  sep_rate ~ treated_post_high |
    state_abbr^industry + state_abbr^time_period + industry^time_period,
  data = ddd_data %>% filter(!(year == 2020 | (year == 2021 & quarter <= 2))),
  cluster = ~state_abbr
)

cat(sprintf("No-COVID DDD: coef = %.3f (SE = %.3f)\n",
            coef(ddd_nocovid), se(ddd_nocovid)))

# ────────────────────────────────────────────────────────────────────
# Save robustness results
# ────────────────────────────────────────────────────────────────────
rob_results <- list(
  ind_results = ind_results,
  age_results = age_results,
  placebo_mod = placebo_mod,
  loo_results = loo_results,
  ddd_nocovid = ddd_nocovid
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
