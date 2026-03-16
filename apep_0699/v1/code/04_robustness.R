# 04_robustness.R — Robustness checks for apep_0699
# Saudi Arabia guardianship reform and female LFP

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) setwd(file.path(dirname(normalizePath(script_path)), ".."))

source("code/00_packages.R")
load("data/cleaned_data.RData")
load("data/results.RData")

# ============================================================
# ROBUSTNESS 1: In-space Permutation Tests (SCM placebo)
# Apply SCM to each donor country as if it were treated
# If Saudi gap > all donor gaps, p-value is low
# ============================================================
cat("=== ROBUSTNESS 1: In-space permutation tests ===\n")

scm_data_rob <- female_panel_wide %>%
  filter(iso2c %in% c("SA", results$complete_donors_scm), !is.na(lfp)) %>%
  select(iso2c, year, lfp)

scm_wide_rob <- scm_data_rob %>%
  pivot_wider(names_from = iso2c, values_from = lfp) %>%
  arrange(year)

pre_years <- scm_wide_rob %>% filter(year <= 2017)
post_years <- scm_wide_rob %>% filter(year >= 2018)

all_countries <- c("SA", results$complete_donors_scm)
placebo_gaps <- list()

compute_scm_gap <- function(treated_iso, donor_isos, data_wide, pre_end = 2017) {
  # SCM for any country as treated
  pre_d <- data_wide %>% filter(year <= pre_end)
  y_treat <- pre_d[[treated_iso]]
  donors_avail <- donor_isos[donor_isos %in% names(data_wide)]
  donors_avail <- donors_avail[donors_avail != treated_iso]
  y_donors <- as.matrix(pre_d[, donors_avail, drop = FALSE])

  # Remove NA columns
  keep <- apply(y_donors, 2, function(x) !any(is.na(x)))
  y_donors <- y_donors[, keep, drop = FALSE]
  if (ncol(y_donors) < 1) return(NULL)

  # Check treated is complete
  if (any(is.na(y_treat))) return(NULL)

  # Compute weights
  if (requireNamespace("quadprog", quietly = TRUE)) {
    library(quadprog)
    n <- ncol(y_donors)
    D <- t(y_donors) %*% y_donors + diag(1e-6, n)
    d <- t(y_donors) %*% y_treat
    A <- cbind(rep(1, n), diag(n))
    b <- c(1, rep(0, n))
    w <- tryCatch(solve.QP(D, d, A, b, meq = 1)$solution,
                  error = function(e) rep(1/n, n))
  } else {
    w <- rep(1/ncol(y_donors), ncol(y_donors))
  }
  w[w < 0.01] <- 0
  if (sum(w) == 0) w <- rep(1/ncol(y_donors), ncol(y_donors))
  w <- w / sum(w)

  # All years
  y_all <- as.matrix(data_wide[, colnames(y_donors), drop = FALSE])
  synth <- as.vector(y_all %*% w)
  actual <- data_wide[[treated_iso]]
  gap <- actual - synth

  tibble(
    iso2c = treated_iso,
    year = as.integer(data_wide$year),
    actual = actual,
    synthetic = synth,
    gap = gap
  )
}

# Compute placebo gaps for all countries
placebo_results <- list()
for (iso in all_countries) {
  donors <- all_countries[all_countries != iso]
  gap_df <- compute_scm_gap(iso, donors, scm_wide_rob)
  if (!is.null(gap_df)) {
    placebo_results[[iso]] <- gap_df
    # RMSPE for this country
    rmspe_pre <- sqrt(mean(gap_df$gap[gap_df$year <= 2017]^2, na.rm = TRUE))
    if (iso == "SA") cat("SA pre-RMSPE:", round(rmspe_pre, 2), "pp\n")
  }
}

# Post-treatment gap for SA vs donors
placebo_df <- bind_rows(placebo_results)
post_guard_gaps <- placebo_df %>%
  filter(year >= 2020) %>%
  group_by(iso2c) %>%
  summarise(mean_gap = mean(gap, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(mean_gap))

sa_gap_post <- post_guard_gaps %>% filter(iso2c == "SA") %>% pull(mean_gap)
n_larger <- sum(post_guard_gaps$mean_gap >= sa_gap_post) - 1  # exclude SA itself
n_total <- nrow(post_guard_gaps) - 1
pval_permutation <- n_larger / n_total
cat("Post-guardianship (2020+) mean gap for SA:", round(sa_gap_post, 2), "pp\n")
cat("Countries with larger gap:", n_larger, "of", n_total, "\n")
cat("Permutation p-value:", round(pval_permutation, 3), "\n")

# ============================================================
# ROBUSTNESS 2: In-time Placebo Test
# "Treat" Saudi Arabia at 2015 (false treatment) → should be null
# ============================================================
cat("\n=== ROBUSTNESS 2: In-time placebo (2015 false treatment) ===\n")

long_panel_placebo <- long_panel %>%
  mutate(
    placebo_guard = as.integer(year >= 2015),
    placebo_driving = as.integer(year >= 2014),
    treated_placebo = is_saudi * is_female * placebo_guard
  ) %>%
  filter(year <= 2018)  # Only pre-reform data for this placebo

mod_placebo <- feols(
  lfp ~ saudi_female * placebo_guard +
        saudi_female * placebo_driving +
        log_gdp |
    country_gender + year,
  data = long_panel_placebo,
  cluster = ~iso2c
)

placebo_coef <- coef(mod_placebo)["saudi_female:placebo_guard"]
placebo_se <- sqrt(diag(vcov(mod_placebo)))["saudi_female:placebo_guard"]
cat("In-time placebo (2015 false treatment) coefficient:", round(placebo_coef, 3),
    "SE:", round(placebo_se, 3), "\n")
cat("True effect should be ~0 for pre-2019 data.\n")

# ============================================================
# ROBUSTNESS 3: Exclude COVID year (2020) to isolate 2019 effect
# ============================================================
cat("\n=== ROBUSTNESS 3: Exclude 2020 ===\n")

mod_no2020 <- feols(
  lfp ~ saudi_female * post_guard +
        saudi_female * post_driving +
        log_gdp |
    country_gender + year,
  data = long_panel %>% filter(year != 2020),
  cluster = ~iso2c
)

no2020_coef <- coef(mod_no2020)["saudi_female:post_guard"]
no2020_se <- sqrt(diag(vcov(mod_no2020)))["saudi_female:post_guard"]
cat("DDD ex-COVID guardianship effect:", round(no2020_coef, 2), "SE:", round(no2020_se, 2), "\n")

# ============================================================
# ROBUSTNESS 4: Gender gap (female - male LFP within Saudi Arabia)
# Outcome: CHANGE IN GENDER GAP vs comparison countries
# ============================================================
cat("\n=== ROBUSTNESS 4: Gender gap analysis ===\n")

gender_gap_panel <- long_panel %>%
  select(iso2c, country, year, gender, lfp) %>%
  pivot_wider(names_from = gender, values_from = lfp) %>%
  mutate(
    gender_gap = male - female,  # Positive = men work more
    is_saudi = as.integer(iso2c == "SA"),
    post_guard = as.integer(year >= 2019),
    post_driving = as.integer(year >= 2018)
  ) %>%
  filter(!is.na(gender_gap))

mod_gap <- feols(
  gender_gap ~ is_saudi * post_guard +
               is_saudi * post_driving |
    iso2c + year,
  data = gender_gap_panel,
  cluster = ~iso2c
)

gap_coef <- coef(mod_gap)["is_saudi:post_guard"]
gap_se <- sqrt(diag(vcov(mod_gap)))["is_saudi:post_guard"]
cat("Gender gap DiD (guardianship effect on M-F gap):", round(gap_coef, 2), "SE:", round(gap_se, 2), "\n")
cat("(Negative = guardianship reform closed the gender gap)\n")

# ============================================================
# ROBUSTNESS 5: Pre-trend F-test
# ============================================================
cat("\n=== ROBUSTNESS 5: Pre-trend test ===\n")

pre_trend_data <- female_panel_wide %>%
  filter(iso2c %in% c("SA", results$complete_donors_scm),
         year <= 2017, !is.na(lfp)) %>%
  mutate(
    is_saudi = as.integer(iso2c == "SA"),
    year_num = year - 2014,
    trend_sa = is_saudi * year_num
  )

mod_pretrend <- feols(
  lfp ~ is_saudi * year_num | iso2c,
  data = pre_trend_data
)

pre_trend_coef <- coef(mod_pretrend)["is_saudi:year_num"]
pre_trend_se <- sqrt(diag(vcov(mod_pretrend)))["is_saudi:year_num"]
cat("Pre-trend slope differential (Saudi vs donors):", round(pre_trend_coef, 3),
    "SE:", round(pre_trend_se, 3), "\n")
cat("Should be close to 0 for parallel trends.\n")

# ============================================================
# SAVE ROBUSTNESS RESULTS
# ============================================================
robustness_results <- list(
  placebo_df = placebo_df,
  post_guard_gaps = post_guard_gaps,
  pval_permutation = pval_permutation,
  sa_gap_post = sa_gap_post,
  mod_placebo = mod_placebo,
  placebo_coef = placebo_coef,
  placebo_se = placebo_se,
  mod_no2020 = mod_no2020,
  no2020_coef = no2020_coef,
  no2020_se = no2020_se,
  mod_gap = mod_gap,
  gap_coef = gap_coef,
  gap_se = gap_se,
  mod_pretrend = mod_pretrend,
  pre_trend_coef = pre_trend_coef,
  pre_trend_se = pre_trend_se
)

save(robustness_results, file = "data/robustness_results.RData")
cat("\nRobustness analysis complete.\n")
