## 04_robustness.R — Robustness checks and mechanism decomposition
## apep_0501: Municipal Mergers and Direct Democracy in Switzerland

source("00_packages.R")

DATA_DIR <- "../data"

# =============================================================================
# 1. LOAD DATA
# =============================================================================

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, vote_date := as.Date(vote_date)]
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))

cat(sprintf("Panel: %s obs, %d treated, %d control communes\n",
            format(nrow(panel), big.mark = ","),
            results$n_treated, results$n_control))

# =============================================================================
# 2. STACKED DiD (COHORT-SPECIFIC CLEAN WINDOWS)
# =============================================================================

cat("\n=== Stacked DiD ===\n")

# For each cohort (treatment_year), create a clean 2×2 window:
# ±5 years, only using never-treated controls
treatment_years <- sort(unique(panel[treated == TRUE, treatment_year]))
cat(sprintf("Treatment cohorts: %d (%d to %d)\n",
            length(treatment_years), min(treatment_years), max(treatment_years)))

stacked_data <- list()
for (g in treatment_years) {
  window_start <- g - 5
  window_end <- g + 5

  # Treated communes in this cohort
  cohort_treated <- panel[treatment_year == g &
                           vote_year >= window_start &
                           vote_year <= window_end]

  # Never-treated controls in the same window
  cohort_control <- panel[treated == FALSE &
                           vote_year >= window_start &
                           vote_year <= window_end]

  cohort_data <- rbind(cohort_treated, cohort_control)
  cohort_data[, cohort := g]

  # Create cohort-specific IDs to avoid overlap
  cohort_data[, stacked_id := paste0(commune_code, "_", g)]

  stacked_data[[as.character(g)]] <- cohort_data
}

stacked <- rbindlist(stacked_data)
stacked[, stacked_id_num := as.integer(factor(stacked_id))]
stacked[, cohort_vote := paste0(cohort, "_", vote_id)]
stacked[, canton := substr(commune_code, 1, nchar(commune_code) - 2)]

cat(sprintf("Stacked panel: %s rows\n", format(nrow(stacked), big.mark = ",")))

# Stacked DiD regression
stacked_did <- feols(turnout_final ~ post | stacked_id_num + cohort_vote,
                      data = stacked, cluster = ~commune_id)
cat("Stacked DiD:\n")
print(summary(stacked_did))

results$att_stacked <- coef(stacked_did)["postTRUE"]
results$se_stacked <- se(stacked_did)["postTRUE"]
results$n_stacked <- nrow(stacked)
results$communes_stacked <- uniqueN(stacked$commune_code)

# =============================================================================
# 3. MATCHED DiD
# =============================================================================

cat("\n=== Matched DiD ===\n")

# Match treated communes to controls on pre-merger turnout mean and variance
pre_means <- panel[vote_year >= 2000 & vote_year <= 2005, .(
  pre_turnout_mean = mean(turnout_final, na.rm = TRUE),
  pre_turnout_sd = sd(turnout_final, na.rm = TRUE),
  pre_eligible_mean = mean(as.numeric(eligible), na.rm = TRUE),
  n_pre_votes = .N
), by = .(commune_code, treated)]

# Nearest-neighbor matching on pre-turnout mean
treated_pre <- pre_means[treated == TRUE]
control_pre <- pre_means[treated == FALSE]

if (nrow(treated_pre) > 0 && nrow(control_pre) > 0) {
  matched_pairs <- list()
  for (i in seq_len(nrow(treated_pre))) {
    diffs <- abs(control_pre$pre_turnout_mean - treated_pre$pre_turnout_mean[i])
    best_match <- which.min(diffs)
    matched_pairs[[i]] <- data.table(
      treated_commune = treated_pre$commune_code[i],
      control_commune = control_pre$commune_code[best_match],
      turnout_diff = diffs[best_match]
    )
  }
  matched <- rbindlist(matched_pairs)
  cat(sprintf("Matched %d treated communes (mean turnout diff: %.2f pp)\n",
              nrow(matched), mean(matched$turnout_diff)))

  # Matched sample DiD
  matched_communes <- c(matched$treated_commune, matched$control_commune)
  matched_panel <- panel[commune_code %in% matched_communes]

  matched_did <- feols(turnout_final ~ post | commune_id + vote_id,
                        data = matched_panel, cluster = ~commune_id)
  cat("Matched DiD:\n")
  print(summary(matched_did))

  results$att_matched <- coef(matched_did)["postTRUE"]
  results$se_matched <- se(matched_did)["postTRUE"]
  results$n_matched <- nrow(matched_panel)
  results$communes_matched <- uniqueN(matched_panel$commune_code)
}

# =============================================================================
# 4. EXCLUDING GLARUS (MEGA-MERGER ROBUSTNESS)
# =============================================================================

cat("\n=== Excluding Glarus ===\n")

# Glarus merged from 25 to 3 communes in 2011 — an extreme outlier
# Identify Glarus communes (BFS codes starting with certain range)
# Glarus canton codes: typically 1601-1632
glarus_pattern <- "Glarus|GL "
panel[, is_glarus := grepl(glarus_pattern, commune_label, ignore.case = TRUE)]

if (sum(panel$is_glarus) > 0) {
  no_glarus_data <- panel[is_glarus == FALSE]
  no_glarus <- feols(turnout_final ~ post | commune_id + vote_id,
                      data = no_glarus_data,
                      cluster = ~commune_id)
  cat("Excluding Glarus:\n")
  print(summary(no_glarus))
  results$att_no_glarus <- coef(no_glarus)["postTRUE"]
  results$se_no_glarus <- se(no_glarus)["postTRUE"]
  results$n_no_glarus <- nrow(no_glarus_data)
  results$communes_no_glarus <- uniqueN(no_glarus_data$commune_code)
} else {
  cat("No Glarus communes identified in label matching.\n")
}

# =============================================================================
# 5. MECHANISM: SIZE EFFECT (DOSE-RESPONSE)
# =============================================================================

cat("\n=== Mechanism: Size effect ===\n")

# Treatment intensity = log change in eligible voters at merger
panel[, eligible_num := as.numeric(eligible)]
dose_data <- panel[treated == TRUE]

# Compute size jump for each treated commune
dose_data[, .(
  pre_eligible = mean(eligible_num[post == FALSE], na.rm = TRUE),
  post_eligible = mean(eligible_num[post == TRUE], na.rm = TRUE)
), by = commune_code] -> size_change

size_change[, size_ratio := post_eligible / pre_eligible]
size_change[, log_size_ratio := log(size_ratio)]
size_change <- size_change[is.finite(log_size_ratio)]

# Merge back
panel <- merge(panel, size_change[, .(commune_code, log_size_ratio)],
               by = "commune_code", all.x = TRUE)
panel[is.na(log_size_ratio), log_size_ratio := 0]

dose_response <- feols(turnout_final ~ post * log_size_ratio | commune_id + vote_id,
                        data = panel, cluster = ~commune_id)
cat("Dose-response (size ratio):\n")
print(summary(dose_response))

# =============================================================================
# 5b. DOSE-RESPONSE IN STACKED DiD FRAMEWORK
# =============================================================================

cat("\n=== Dose-response in stacked DiD ===\n")

# Merge log_size_ratio into stacked data
stacked <- merge(stacked, size_change[, .(commune_code, log_size_ratio)],
                 by = "commune_code", all.x = TRUE)
stacked[is.na(log_size_ratio), log_size_ratio := 0]

dose_stacked <- feols(turnout_final ~ post * log_size_ratio |
                        stacked_id_num + cohort_vote,
                      data = stacked, cluster = ~commune_id)
cat("Dose-response (stacked DiD):\n")
print(summary(dose_stacked))

results$dose_stacked_base <- coef(dose_stacked)["postTRUE"]
results$dose_stacked_interaction <- coef(dose_stacked)["postTRUE:log_size_ratio"]
results$dose_stacked_se_base <- se(dose_stacked)["postTRUE"]
results$dose_stacked_se_interaction <- se(dose_stacked)["postTRUE:log_size_ratio"]

# =============================================================================
# 5c. STACKED DiD WITH CLEAN CONTROLS (EXCL. POST-2020 MERGERS)
# =============================================================================

cat("\n=== Stacked DiD with strictly never-merged controls ===\n")

# Load full merger timeline to identify ALL communes that ever merged
merger_timeline <- fread(file.path(DATA_DIR, "merger_timeline.csv"))
first_merger_all <- fread(file.path(DATA_DIR, "first_merger.csv"))

# Identify communes that merge after 2020 (contaminated controls)
post2020_mergers <- first_merger_all[first_merger_year > 2020, as.character(successor_code)]
cat(sprintf("Controls merging after 2020: %d communes\n", length(post2020_mergers)))

# Rebuild stacked with strictly never-merged controls
stacked_clean <- list()
for (g in treatment_years) {
  window_start <- g - 5
  window_end <- g + 5

  cohort_treated <- panel[treatment_year == g &
                           vote_year >= window_start &
                           vote_year <= window_end]

  # Exclude post-2020 mergers from controls
  cohort_control <- panel[treated == FALSE &
                           !(commune_code %in% post2020_mergers) &
                           vote_year >= window_start &
                           vote_year <= window_end]

  cohort_data <- rbind(cohort_treated, cohort_control)
  cohort_data[, cohort := g]
  cohort_data[, stacked_id := paste0(commune_code, "_", g)]
  stacked_clean[[as.character(g)]] <- cohort_data
}

stacked_strict <- rbindlist(stacked_clean)
stacked_strict[, stacked_id_num := as.integer(factor(stacked_id))]
stacked_strict[, cohort_vote := paste0(cohort, "_", vote_id)]

cat(sprintf("Clean stacked panel: %s rows (vs %s with all controls)\n",
            format(nrow(stacked_strict), big.mark = ","),
            format(nrow(stacked), big.mark = ",")))

stacked_strict_did <- feols(turnout_final ~ post | stacked_id_num + cohort_vote,
                             data = stacked_strict, cluster = ~commune_id)
cat("Stacked DiD (strictly never-merged controls):\n")
print(summary(stacked_strict_did))

results$att_stacked_strict <- coef(stacked_strict_did)["postTRUE"]
results$se_stacked_strict <- se(stacked_strict_did)["postTRUE"]

# =============================================================================
# 5d. NARROWER WINDOW: ±3 YEARS
# =============================================================================

cat("\n=== Stacked DiD ±3 years ===\n")

stacked_narrow <- list()
for (g in treatment_years) {
  window_start <- g - 3
  window_end <- g + 3
  cohort_treated <- panel[treatment_year == g &
                           vote_year >= window_start &
                           vote_year <= window_end]
  cohort_control <- panel[treated == FALSE &
                           vote_year >= window_start &
                           vote_year <= window_end]
  cohort_data <- rbind(cohort_treated, cohort_control)
  cohort_data[, cohort := g]
  cohort_data[, stacked_id := paste0(commune_code, "_", g)]
  stacked_narrow[[as.character(g)]] <- cohort_data
}

stacked_3yr <- rbindlist(stacked_narrow)
stacked_3yr[, stacked_id_num := as.integer(factor(stacked_id))]
stacked_3yr[, cohort_vote := paste0(cohort, "_", vote_id)]

stacked_3yr_did <- feols(turnout_final ~ post | stacked_id_num + cohort_vote,
                          data = stacked_3yr, cluster = ~commune_id)
cat("Stacked DiD ±3 years:\n")
print(summary(stacked_3yr_did))

results$att_stacked_3yr <- coef(stacked_3yr_did)["postTRUE"]
results$se_stacked_3yr <- se(stacked_3yr_did)["postTRUE"]
results$n_stacked_3yr <- nrow(stacked_3yr)

# =============================================================================
# 5e. CANTON-CLUSTERED STANDARD ERRORS
# =============================================================================

cat("\n=== Canton-clustered SEs ===\n")

# Extract canton from commune_code (first 1-2 digits represent canton)
panel[, canton := substr(commune_code, 1, nchar(commune_code) - 2)]

stacked_canton <- feols(turnout_final ~ post | stacked_id_num + cohort_vote,
                         data = stacked, cluster = ~canton)
cat("Stacked DiD (canton-clustered):\n")
cat(sprintf("  ATT: %.3f, SE(canton): %.3f, SE(commune): %.3f\n",
            coef(stacked_canton)["postTRUE"],
            se(stacked_canton)["postTRUE"],
            results$se_stacked))

results$se_stacked_canton <- se(stacked_canton)["postTRUE"]

# =============================================================================
# 6. PLACEBO: RANDOMIZED MERGER TIMING
# =============================================================================

cat("\n=== Placebo: randomized merger timing ===\n")

set.seed(42)
n_permutations <- 200
placebo_atts <- numeric(n_permutations)

treated_communes <- unique(panel[treated == TRUE, commune_code])
all_years <- sort(unique(panel$vote_year))
treatment_years_pool <- all_years[all_years >= 2000 & all_years <= 2020]

for (p in seq_len(n_permutations)) {
  # Randomly assign treatment years to treated communes
  fake_treatment <- data.table(
    commune_code = treated_communes,
    fake_year = sample(treatment_years_pool, length(treated_communes), replace = TRUE)
  )

  placebo_panel <- merge(panel, fake_treatment, by = "commune_code", all.x = TRUE)
  placebo_panel[, fake_post := !is.na(fake_year) & vote_year >= fake_year]

  placebo_reg <- tryCatch({
    feols(turnout_final ~ fake_post | commune_id + vote_id,
          data = placebo_panel, cluster = ~commune_id)
  }, error = function(e) NULL)

  if (!is.null(placebo_reg)) {
    placebo_atts[p] <- coef(placebo_reg)["fake_postTRUE"]
  }
}

# Randomization inference p-value
real_att <- results$att_twfe
ri_pval <- mean(abs(placebo_atts) >= abs(real_att), na.rm = TRUE)
cat(sprintf("RI p-value (200 permutations): %.4f\n", ri_pval))
cat(sprintf("Real ATT: %.4f, Placebo mean: %.4f, Placebo SD: %.4f\n",
            real_att, mean(placebo_atts, na.rm = TRUE),
            sd(placebo_atts, na.rm = TRUE)))

results$ri_pval <- ri_pval
saveRDS(placebo_atts, file.path(DATA_DIR, "placebo_atts.rds"))

# =============================================================================
# 7. SAVE ALL RESULTS
# =============================================================================

saveRDS(results, file.path(DATA_DIR, "main_results.rds"))
cat("\nRobustness checks complete.\n")
