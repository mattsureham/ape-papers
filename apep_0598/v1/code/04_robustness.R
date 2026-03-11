# 04_robustness.R — Placebo tests, leave-one-out, robustness
# APEP-0598: Greece Capital Controls & Shadow Economy Formalization

source("00_packages.R")

data_dir <- "../data/"

scm_panel <- fread(file.path(data_dir, "scm_panel.csv"))
sector_panel <- fread(file.path(data_dir, "sector_panel.csv"))
country_map <- fread(file.path(data_dir, "country_map.csv"))

greece_id <- country_map$country_id[country_map$country == "EL"]
donor_ids <- country_map$country_id[country_map$country != "EL"]
treatment_time <- (2015 - 2010) * 12 + 7

# Pre-treatment times
all_times <- sort(unique(scm_panel$time_index))
pre_times <- all_times[all_times < treatment_time]

# ============================================================
# 1. PLACEBO-IN-SPACE (Permutation Tests)
# ============================================================

cat("=== PLACEBO-IN-SPACE TESTS ===\n")

placebo_gaps <- list()

for (placebo_id in donor_ids) {
  placebo_country <- country_map$country[country_map$country_id == placebo_id]
  cat("  Running placebo for", placebo_country, "...\n")

  # Remaining donors (excluding the placebo unit and Greece)
  remaining_donors <- donor_ids[donor_ids != placebo_id]

  placebo_data <- scm_panel %>%
    filter(country_id %in% c(placebo_id, remaining_donors)) %>%
    select(country_id, time_index, value) %>%
    filter(!is.na(value)) %>%
    as.data.frame()

  # Check if we have enough data
  placebo_times <- sort(unique(placebo_data$time_index[
    placebo_data$country_id == placebo_id]))

  if (length(placebo_times) < 20) {
    cat("    Skipping - insufficient data\n")
    next
  }

  placebo_pre <- placebo_times[placebo_times < treatment_time]

  tryCatch({
    predictor_times_p <- list()
    for (yr in 2010:2014) {
      yr_times <- ((yr - 2010) * 12 + 1):((yr - 2010) * 12 + 12)
      yr_times <- yr_times[yr_times %in% placebo_pre]
      if (length(yr_times) > 0) {
        predictor_times_p[[paste0("turnover_", yr)]] <- yr_times
      }
    }

    special_preds <- list()
    for (nm in names(predictor_times_p)) {
      special_preds[[length(special_preds) + 1]] <-
        list("value", predictor_times_p[[nm]], "mean")
    }

    dp <- dataprep(
      foo = placebo_data,
      predictors = NULL,
      predictors.op = "mean",
      dependent = "value",
      unit.variable = "country_id",
      time.variable = "time_index",
      treatment.identifier = placebo_id,
      controls.identifier = remaining_donors,
      time.predictors.prior = placebo_pre,
      time.optimize.ssr = placebo_pre,
      time.plot = sort(unique(placebo_data$time_index)),
      special.predictors = special_preds
    )

    so <- synth(dp, optimxmethod = "BFGS")

    gaps <- dp$Y1plot - (dp$Y0plot %*% so$solution.w)
    gap_df <- data.frame(
      time_index = as.integer(rownames(gaps)),
      gap = as.numeric(gaps),
      country = placebo_country,
      country_id = placebo_id
    )

    placebo_gaps[[placebo_country]] <- gap_df

  }, error = function(e) {
    cat("    Error for", placebo_country, ":", e$message, "\n")
  })
}

# Combine placebo results
if (length(placebo_gaps) > 0) {
  all_placebo_gaps <- bind_rows(placebo_gaps)
  fwrite(all_placebo_gaps, file.path(data_dir, "placebo_gaps.csv"))

  # Compute RMSPE ratios for inference
  rmspe_placebo <- all_placebo_gaps %>%
    mutate(post = as.integer(time_index >= treatment_time)) %>%
    group_by(country) %>%
    summarise(
      pre_rmspe = sqrt(mean(gap[post == 0]^2)),
      post_rmspe = sqrt(mean(gap[post == 1]^2)),
      rmspe_ratio = post_rmspe / pre_rmspe,
      .groups = "drop"
    )

  # Load Greece RMSPE
  greece_rmspe <- fread(file.path(data_dir, "scm_rmspe.csv"))
  greece_ratio <- greece_rmspe$value[greece_rmspe$metric == "rmspe_ratio"]

  # Add Greece
  rmspe_all <- bind_rows(
    rmspe_placebo,
    data.frame(country = "EL", pre_rmspe = NA, post_rmspe = NA,
               rmspe_ratio = greece_ratio)
  ) %>%
    arrange(desc(rmspe_ratio))

  # P-value: proportion of placebos with RMSPE ratio >= Greece
  rank_greece <- which(rmspe_all$country == "EL")
  p_value <- rank_greece / nrow(rmspe_all)

  cat("\nRMSPE ratios (sorted):\n")
  print(rmspe_all)
  cat("\nGreece rank:", rank_greece, "of", nrow(rmspe_all), "\n")
  cat("Placebo p-value:", round(p_value, 4), "\n")

  fwrite(rmspe_all, file.path(data_dir, "rmspe_ratios.csv"))

  # Save p-value
  pval_df <- data.frame(
    rank = rank_greece,
    n_units = nrow(rmspe_all),
    p_value = p_value
  )
  fwrite(pval_df, file.path(data_dir, "placebo_pvalue.csv"))
}

# ============================================================
# 2. LEAVE-ONE-OUT ROBUSTNESS
# ============================================================

cat("\n=== LEAVE-ONE-OUT ROBUSTNESS ===\n")

loo_results <- list()

for (drop_id in donor_ids) {
  drop_country <- country_map$country[country_map$country_id == drop_id]
  cat("  Dropping", drop_country, "...\n")

  remaining <- donor_ids[donor_ids != drop_id]

  loo_data <- scm_panel %>%
    filter(country_id %in% c(greece_id, remaining)) %>%
    select(country_id, time_index, value) %>%
    filter(!is.na(value)) %>%
    as.data.frame()

  tryCatch({
    predictor_times_l <- list()
    for (yr in 2010:2014) {
      yr_times <- ((yr - 2010) * 12 + 1):((yr - 2010) * 12 + 12)
      yr_times <- yr_times[yr_times %in% pre_times]
      if (length(yr_times) > 0) {
        predictor_times_l[[paste0("turnover_", yr)]] <- yr_times
      }
    }

    special_preds_l <- list()
    for (nm in names(predictor_times_l)) {
      special_preds_l[[length(special_preds_l) + 1]] <-
        list("value", predictor_times_l[[nm]], "mean")
    }

    dp_loo <- dataprep(
      foo = loo_data,
      predictors = NULL,
      predictors.op = "mean",
      dependent = "value",
      unit.variable = "country_id",
      time.variable = "time_index",
      treatment.identifier = greece_id,
      controls.identifier = remaining,
      time.predictors.prior = pre_times,
      time.optimize.ssr = pre_times,
      time.plot = sort(unique(loo_data$time_index)),
      special.predictors = special_preds_l
    )

    so_loo <- synth(dp_loo, optimxmethod = "BFGS")

    synthetic_loo <- dp_loo$Y0plot %*% so_loo$solution.w

    loo_df <- data.frame(
      time_index = as.integer(rownames(synthetic_loo)),
      synthetic = as.numeric(synthetic_loo),
      dropped = drop_country
    )

    loo_results[[drop_country]] <- loo_df

  }, error = function(e) {
    cat("    Error:", e$message, "\n")
  })
}

if (length(loo_results) > 0) {
  all_loo <- bind_rows(loo_results)
  fwrite(all_loo, file.path(data_dir, "loo_results.csv"))

  # Summary: how much does synthetic Greece change?
  loo_summary <- all_loo %>%
    filter(time_index >= treatment_time) %>%
    group_by(dropped) %>%
    summarise(mean_synthetic = mean(synthetic, na.rm = TRUE), .groups = "drop")

  cat("\nLeave-one-out summary (post-treatment synthetic mean):\n")
  print(loo_summary)
}

# ============================================================
# 3. PLACEBO-IN-TIME
# ============================================================

cat("\n=== PLACEBO-IN-TIME ===\n")

# Run SCM with fake treatment dates: July 2012, July 2013, July 2014
placebo_times_fake <- c(
  (2012 - 2010) * 12 + 7,  # July 2012
  (2013 - 2010) * 12 + 7,  # July 2013
  (2014 - 2010) * 12 + 7   # July 2014
)

time_placebo_results <- list()

for (fake_t in placebo_times_fake) {
  fake_year <- 2010 + (fake_t - 1) %/% 12
  cat("  Placebo treatment:", fake_year, "\n")

  fake_pre <- all_times[all_times < fake_t & all_times >= min(all_times)]

  if (length(fake_pre) < 12) {
    cat("    Skipping - insufficient pre-periods\n")
    next
  }

  scm_data_time <- scm_panel %>%
    filter(time_index < treatment_time) %>%  # Only use pre-actual-treatment data
    select(country_id, time_index, value) %>%
    filter(!is.na(value)) %>%
    as.data.frame()

  tryCatch({
    # Use pre-period years for special predictors
    start_year <- 2010
    end_year <- fake_year - 1
    special_preds_t <- list()
    for (yr in start_year:end_year) {
      yr_times <- ((yr - 2010) * 12 + 1):((yr - 2010) * 12 + 12)
      yr_times <- yr_times[yr_times %in% fake_pre]
      if (length(yr_times) > 0) {
        special_preds_t[[length(special_preds_t) + 1]] <-
          list("value", yr_times, "mean")
      }
    }

    dp_time <- dataprep(
      foo = scm_data_time,
      predictors = NULL,
      predictors.op = "mean",
      dependent = "value",
      unit.variable = "country_id",
      time.variable = "time_index",
      treatment.identifier = greece_id,
      controls.identifier = donor_ids,
      time.predictors.prior = fake_pre,
      time.optimize.ssr = fake_pre,
      time.plot = sort(unique(scm_data_time$time_index)),
      special.predictors = special_preds_t
    )

    so_time <- synth(dp_time, optimxmethod = "BFGS")

    gaps_time <- dp_time$Y1plot - (dp_time$Y0plot %*% so_time$solution.w)
    gap_time_df <- data.frame(
      time_index = as.integer(rownames(gaps_time)),
      gap = as.numeric(gaps_time),
      fake_treatment_year = fake_year
    )

    time_placebo_results[[as.character(fake_year)]] <- gap_time_df

  }, error = function(e) {
    cat("    Error:", e$message, "\n")
  })
}

if (length(time_placebo_results) > 0) {
  all_time_placebos <- bind_rows(time_placebo_results)
  fwrite(all_time_placebos, file.path(data_dir, "time_placebo_gaps.csv"))
}

# ============================================================
# 4. SECTOR DiD ROBUSTNESS
# ============================================================

cat("\n=== SECTOR DiD ROBUSTNESS ===\n")

# Add relative time
baseline_time_sec <- (2015 - 2010) * 12 + 6
sector_panel <- sector_panel %>%
  mutate(rel_time = time_index - baseline_time_sec)

# Alternative: binary treatment (high cash vs low cash)
sector_panel <- sector_panel %>%
  mutate(high_cash = as.integer(cash_share >= 0.75))

did_binary <- feols(
  value ~ high_cash:post | nace + time_index,
  data = sector_panel,
  cluster = ~nace
)
cat("\nBinary DiD (high cash vs low):\n")
print(summary(did_binary))

# Sector-specific event studies
for (sec in unique(sector_panel$nace)) {
  sec_data <- sector_panel %>% filter(nace == sec)
  sec_label <- unique(sec_data$sector_label)
  cat("\n", sec, "(", sec_label, "):\n")

  # Simple pre-post mean comparison
  pre_mean <- mean(sec_data$value[sec_data$post == 0], na.rm = TRUE)
  post_mean <- mean(sec_data$value[sec_data$post == 1], na.rm = TRUE)
  cat("  Pre mean:", round(pre_mean, 2), "\n")
  cat("  Post mean:", round(post_mean, 2), "\n")
  cat("  Difference:", round(post_mean - pre_mean, 2), "\n")
}

# Save robustness models
save(did_binary, file = file.path(data_dir, "robustness_models.RData"))
fwrite(as.data.frame(coeftable(did_binary)), file.path(data_dir, "did_binary_results.csv"))

# ============================================================
# 5. PERSISTENCE TEST (post-control-removal)
# ============================================================

cat("\n=== PERSISTENCE TEST ===\n")

# Controls fully removed September 2019
# Check if SCM gap persists after September 2019
removal_time <- (2019 - 2010) * 12 + 9  # September 2019

if (file.exists(file.path(data_dir, "scm_gaps.csv"))) {
  gaps_df <- fread(file.path(data_dir, "scm_gaps.csv"))

  # Divide post-treatment into: during controls vs after removal
  persistence <- gaps_df %>%
    filter(post == 1) %>%
    mutate(
      period = case_when(
        time_index < removal_time ~ "During controls",
        TRUE ~ "After removal"
      )
    ) %>%
    group_by(period) %>%
    summarise(
      mean_gap = mean(gap, na.rm = TRUE),
      sd_gap = sd(gap, na.rm = TRUE),
      n_months = n(),
      .groups = "drop"
    )

  cat("\nPersistence of SCM gap:\n")
  print(persistence)
  fwrite(persistence, file.path(data_dir, "persistence_test.csv"))
}

# ============================================================
# 6. WILD CLUSTER BOOTSTRAP (sector DiD)
# ============================================================

cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

library(fwildclusterboot)

# Reload and prepare sector panel (nace must be factor for fwildclusterboot)
sector_panel <- fread(file.path(data_dir, "sector_panel.csv"))
sector_panel[, nace := as.factor(nace)]
baseline_time_sec <- (2015 - 2010) * 12 + 6
sector_panel[, rel_time := time_index - baseline_time_sec]
sector_panel[, high_cash := as.integer(cash_share >= 0.75)]

# Re-estimate models so fwildclusterboot can access the data environment
did_main_boot <- feols(
  value ~ cash_share:post | nace + time_index,
  data = sector_panel, cluster = ~nace
)
did_binary_boot <- feols(
  value ~ high_cash:post | nace + time_index,
  data = sector_panel, cluster = ~nace
)

# Wild cluster bootstrap - continuous
set.seed(12345)
cat("Bootstrap for continuous treatment (cash_share x post)...\n")
boot_cont <- boottest(
  did_main_boot,
  param = "cash_share:post",
  clustid = ~nace,
  B = 99999,
  type = "webb"
)
cat("  Bootstrap p-value (continuous):", boot_cont$p_val, "\n")

# Wild cluster bootstrap - binary
cat("Bootstrap for binary treatment (high_cash x post)...\n")
boot_bin <- boottest(
  did_binary_boot,
  param = "high_cash:post",
  clustid = ~nace,
  B = 99999,
  type = "webb"
)
cat("  Bootstrap p-value (binary):", boot_bin$p_val, "\n")

# Save bootstrap results
boot_results <- data.frame(
  specification = c("continuous", "binary"),
  analytic_p = c(
    coeftable(did_main_boot)["cash_share:post", "Pr(>|t|)"],
    coeftable(did_binary_boot)["high_cash:post", "Pr(>|t|)"]
  ),
  bootstrap_p = c(boot_cont$p_val, boot_bin$p_val)
)
fwrite(boot_results, file.path(data_dir, "bootstrap_pvalues.csv"))
cat("\nBootstrap results saved to data/bootstrap_pvalues.csv\n")
print(boot_results)

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
