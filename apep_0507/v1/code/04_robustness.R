# =============================================================================
# 04_robustness.R — Robustness checks
# Swiss Municipal Mergers and Democratic Participation
# =============================================================================

source("00_packages.R")

# =============================================================================
# STEP 1: Load data and main results
# =============================================================================

cat("\n=== Loading data ===\n")
panel <- fread(file.path(DATA_DIR, "panel_vote.csv"))
annual <- fread(file.path(DATA_DIR, "panel_annual.csv"))
panel[, vote_date := as.Date(vote_date)]
panel[, vdate := as.character(vote_date)]
panel[, cohort := fifelse(ever_merged, first_merger_year, 10000L)]

results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
cat("  Loaded panel and main results\n")

# =============================================================================
# STEP 2: Alternative clustering
# =============================================================================

cat("\n=== Alternative clustering ===\n")

# Canton-level clustering (26 cantons)
r_canton <- feols(turnout_pct ~ post_merger | current_bfs + canton^vdate,
                  data = panel, cluster = ~canton)
cat("  Canton clustering: coef = ", round(coef(r_canton)["post_mergerTRUE"], 3),
    " SE = ", round(summary(r_canton)$coeftable["post_mergerTRUE", "Std. Error"], 3), "\n")

# Two-way clustering (municipality + year)
r_twoway <- feols(turnout_pct ~ post_merger | current_bfs + canton^vdate,
                  data = panel, cluster = ~current_bfs + vote_year)
cat("  Two-way clustering: coef = ", round(coef(r_twoway)["post_mergerTRUE"], 3),
    " SE = ", round(summary(r_twoway)$coeftable["post_mergerTRUE", "Std. Error"], 3), "\n")

# =============================================================================
# STEP 3: Different sample restrictions
# =============================================================================

cat("\n=== Sample restrictions ===\n")

# Post-2000 only (main merger wave)
r_post2000 <- feols(turnout_pct ~ post_merger | current_bfs + canton^vdate,
                    data = panel[vote_year >= 2000], cluster = ~current_bfs)
cat("  Post-2000: coef = ", round(coef(r_post2000)["post_mergerTRUE"], 3), "\n")

# German-speaking cantons only
german_cantons <- c("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG",
                    "SO", "BS", "BL", "SH", "AR", "AI", "SG", "GR", "AG", "TG")
r_german <- feols(turnout_pct ~ post_merger | current_bfs + canton^vdate,
                  data = panel[canton %in% german_cantons], cluster = ~current_bfs)
cat("  German cantons: coef = ", round(coef(r_german)["post_mergerTRUE"], 3), "\n")

# French/Italian cantons
latin_cantons <- c("GE", "VD", "VS", "NE", "JU", "FR", "TI")
r_latin <- feols(turnout_pct ~ post_merger | current_bfs + canton^vdate,
                 data = panel[canton %in% latin_cantons], cluster = ~current_bfs)
cat("  Latin cantons: coef = ", round(coef(r_latin)["post_mergerTRUE"], 3), "\n")

# =============================================================================
# STEP 4: Heterogeneity by merger size
# =============================================================================

cat("\n=== Heterogeneity by merger characteristics ===\n")

# Count number of municipalities dissolved per merger event
merger_xwalk <- fread(file.path(DATA_DIR, "merger_crosswalk.csv"))
merger_size <- merger_xwalk[, .(n_dissolved = .N), by = successor_code]
panel <- merge(panel, merger_size, by.x = "current_bfs", by.y = "successor_code",
               all.x = TRUE)
panel[is.na(n_dissolved), n_dissolved := 0L]

# Small mergers (2 municipalities) vs large (3+)
panel[, large_merger := n_dissolved >= 3]

r_het_size <- feols(turnout_pct ~ post_merger * large_merger |
                      current_bfs + canton^vdate,
                    data = panel,
                    cluster = ~current_bfs)
cat("  Merger size interaction:\n")
print(summary(r_het_size)$coeftable[, 1:2])

# =============================================================================
# STEP 5: Heterogeneity by pre-merger population
# =============================================================================

cat("\n=== Heterogeneity by pre-merger population ===\n")

# Use first available population as baseline
first_pop <- panel[population > 0, .(baseline_pop = first(population)),
                   by = current_bfs]
panel <- merge(panel, first_pop, by = "current_bfs", all.x = TRUE)

# Split at median population among treated
treated_med_pop <- median(first_pop[current_bfs %in% panel[ever_merged == TRUE, unique(current_bfs)],
                                     baseline_pop], na.rm = TRUE)
panel[, small_muni := baseline_pop < treated_med_pop]

r_het_pop <- feols(turnout_pct ~ post_merger * small_muni |
                     current_bfs + canton^vdate,
                   data = panel, cluster = ~current_bfs)
cat("  Population interaction:\n")
print(summary(r_het_pop)$coeftable[, 1:2])

# =============================================================================
# STEP 6: Placebo — National Council election turnout
# =============================================================================

cat("\n=== Placebo: Election turnout ===\n")

elec_file <- file.path(DATA_DIR, "election_turnout.csv")
if (file.exists(elec_file)) {
  elec_dt <- fread(elec_file)

  # Match election data to BFS numbers using same geo_label lookup
  geo_lookup_file <- file.path(DATA_DIR, "id_map.csv")
  id_map <- fread(geo_lookup_file)

  # Need to merge election data with merger treatment
  # Election geo_labels are also "......Name" format
  # For now, use a simpler approach: match BFS from population data

  # Extract BFS from election geo_label (same as population: "......0001 Name")
  elec_dt[, clean_label := sub("^[.]+", "", geo_label)]
  elec_dt[, bfs_nr := as.integer(sub("^([0-9]+) .*$", "\\1", clean_label))]
  elec_dt <- elec_dt[!is.na(bfs_nr)]

  # Add merger treatment
  merger_info <- unique(panel[, .(current_bfs, ever_merged, first_merger_year)])
  elec_dt <- merge(elec_dt, merger_info, by.x = "bfs_nr", by.y = "current_bfs",
                   all.x = TRUE)
  elec_dt[is.na(ever_merged), ever_merged := FALSE]
  elec_dt[, post_merger := ever_merged & year >= first_merger_year]

  if (nrow(elec_dt[!is.na(election_turnout_pct)]) > 100) {
    r_elec <- feols(election_turnout_pct ~ post_merger | bfs_nr + year,
                    data = elec_dt, cluster = ~bfs_nr)
    cat("  Election placebo: coef = ", round(coef(r_elec)["post_mergerTRUE"], 3),
        " (SE = ", round(summary(r_elec)$coeftable["post_mergerTRUE", "Std. Error"], 3), ")\n")
  } else {
    cat("  Insufficient election data for placebo test\n")
  }
} else {
  cat("  No election data available\n")
}

# =============================================================================
# STEP 7: HonestDiD sensitivity analysis
# =============================================================================

cat("\n=== HonestDiD Sensitivity ===\n")

tryCatch({
  sa_model <- results$sunab_2
  es_coefs <- as.data.table(summary(sa_model)$coeftable, keep.rownames = TRUE)
  setnames(es_coefs, c("term", "estimate", "se", "tstat", "pvalue"))
  es_coefs[, rel_year := as.integer(gsub(".*::(-?[0-9]+)$", "\\1", term))]
  es_coefs <- es_coefs[!is.na(rel_year)][order(rel_year)]

  # Separate pre and post
  pre_idx <- which(es_coefs$rel_year < 0)
  post_idx <- which(es_coefs$rel_year >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    # Get variance-covariance matrix for the event-study coefficients
    vcov_mat <- vcov(sa_model)
    coef_names <- es_coefs$term

    # Filter vcov to event-study terms only
    vcov_es <- vcov_mat[coef_names, coef_names]
    beta_es <- es_coefs$estimate

    # Rambachan-Roth: sensitivity to linear violations of parallel trends
    # Using relative magnitudes approach
    honest_result <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = beta_es,
      sigma = vcov_es,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0.5, 2, by = 0.5)
    )

    cat("  HonestDiD results (relative magnitudes):\n")
    print(honest_result)

    saveRDS(honest_result, file.path(DATA_DIR, "honestdid_results.rds"))
  } else {
    cat("  Not enough pre/post periods for HonestDiD\n")
  }
}, error = function(e) {
  cat("  HonestDiD failed: ", e$message, "\n")
})

# =============================================================================
# STEP 8: Dynamic effects — does turnout decline immediately or gradually?
# =============================================================================

cat("\n=== Dynamic treatment effects ===\n")

# Bin event time: immediate (0-2), medium (3-5), long-run (6+)
# Never-merged municipalities are coded as "pre" (reference) for proper DiD comparison
panel[, event_bin := fcase(
  !ever_merged, "pre",
  rel_year < 0, "pre",
  rel_year <= 2, "immediate",
  rel_year <= 5, "medium_run",
  rel_year > 5, "long_run",
  default = NA_character_
)]
panel[, event_bin := factor(event_bin,
                            levels = c("pre", "immediate", "medium_run", "long_run"))]

r_dynamic <- feols(turnout_pct ~ event_bin | current_bfs + canton^vdate,
                   data = panel, cluster = ~current_bfs)
cat("  Dynamic effects:\n")
print(summary(r_dynamic)$coeftable[, 1:2])

# =============================================================================
# STEP 9: Placebo test — randomized treatment dates
# =============================================================================

cat("\n=== Placebo: randomized treatment dates ===\n")

set.seed(42)

# Get the distribution of actual merger years among treated
actual_years <- panel[ever_merged == TRUE, unique(first_merger_year)]

# Among never-merged municipalities, randomly assign fake treatment years
# drawn from the actual distribution
never_merged_ids <- panel[ever_merged == FALSE, unique(current_bfs)]
fake_treatment <- data.table(
  current_bfs = never_merged_ids,
  fake_merger_year = sample(actual_years, length(never_merged_ids), replace = TRUE)
)

placebo_panel <- merge(panel[ever_merged == FALSE], fake_treatment, by = "current_bfs")
placebo_panel[, fake_post := vote_year >= fake_merger_year]
placebo_panel[, vdate := as.character(vote_date)]

r_placebo <- feols(turnout_pct ~ fake_post | current_bfs + canton^vdate,
                   data = placebo_panel, cluster = ~current_bfs)
cat("  Placebo (randomized dates on controls): coef = ",
    round(coef(r_placebo)["fake_postTRUE"], 3),
    " (SE = ", round(summary(r_placebo)$coeftable["fake_postTRUE", "Std. Error"], 3), ")\n")

# =============================================================================
# STEP 10: Single-merger municipalities only
# =============================================================================

cat("\n=== Single-merger robustness ===\n")

# Count how many merger events affected each current_bfs
merger_xwalk2 <- fread(file.path(DATA_DIR, "merger_crosswalk.csv"))
merger_count <- merger_xwalk2[, .(n_mergers = uniqueN(merger_year)), by = successor_code]
single_merger_ids <- merger_count[n_mergers == 1, successor_code]

# Panel restricted to single-merger treated + all never-merged
single_panel <- panel[(!ever_merged) | (current_bfs %in% single_merger_ids)]
single_panel[, vdate := as.character(vote_date)]

r_single <- feols(turnout_pct ~ post_merger | current_bfs + canton^vdate,
                  data = single_panel, cluster = ~current_bfs)
cat("  Single-merger only: coef = ", round(coef(r_single)["post_mergerTRUE"], 3),
    " N = ", nrow(single_panel),
    " (", length(single_merger_ids), " treated munis)\n")

# =============================================================================
# STEP 11: Wild cluster bootstrap (canton-level)
# =============================================================================

cat("\n=== Wild cluster bootstrap (canton-level) ===\n")

tryCatch({
  if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
    install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
  }
  library(fwildclusterboot)

  # Run wild cluster bootstrap on canton-clustered specification
  boot_result <- boottest(
    results$twfe_2,
    param = "post_mergerTRUE",
    clustid = panel$canton,
    B = 9999,
    type = "webb"
  )
  cat("  Wild bootstrap p-value: ", round(boot_result$p_val, 4), "\n")
  cat("  Wild bootstrap CI: [", round(boot_result$conf_int[1], 3),
      ", ", round(boot_result$conf_int[2], 3), "]\n")

  saveRDS(boot_result, file.path(DATA_DIR, "wild_bootstrap_result.rds"))
}, error = function(e) {
  cat("  Wild bootstrap failed: ", e$message, "\n")
  cat("  (Non-fatal — proceeding without wild bootstrap)\n")
})

# =============================================================================
# STEP 12: Save all robustness results
# =============================================================================

cat("\n=== Saving robustness results ===\n")

rob_results <- list(
  canton_cluster = r_canton,
  twoway_cluster = r_twoway,
  post2000 = r_post2000,
  german = r_german,
  latin = r_latin,
  het_size = r_het_size,
  het_pop = r_het_pop,
  dynamic = r_dynamic,
  placebo = r_placebo,
  single_merger = r_single
)
saveRDS(rob_results, file.path(DATA_DIR, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
