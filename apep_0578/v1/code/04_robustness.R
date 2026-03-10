## ============================================================================
## 04_robustness.R — Robustness checks and placebo tests
## Schengen Border Controls and Regional Economic Activity
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel_balanced.csv"))
load(file.path(data_dir, "main_results.RData"))

cat("=== Robustness Checks ===\n")

robustness_results <- list()

## ---------------------------------------------------------------------------
## 1. Placebo test: unaffected Schengen borders
## ---------------------------------------------------------------------------
cat("\n--- Placebo: Unaffected Schengen Borders ---\n")

# Assign fake treatment to control border regions using same timing
placebo_panel <- panel[region_type %in% c("control_border", "interior")]
placebo_panel[, placebo_treated := as.integer(region_type == "control_border" & year >= 2015)]

m_placebo <- feols(log_gdp_pc ~ placebo_treated | nuts3 + year,
                   data = placebo_panel, cluster = ~nuts3)
cat("Placebo (unaffected borders):\n")
summary(m_placebo)

robustness_results[["placebo_borders"]] <- data.table(
  check = "Placebo: unaffected borders",
  estimate = coef(m_placebo)["placebo_treated"],
  se = fixest::se(m_placebo)["placebo_treated"],
  p_value = fixest::pvalue(m_placebo)["placebo_treated"],
  n_obs = nobs(m_placebo)
)

## ---------------------------------------------------------------------------
## 2. Placebo timing (fake treatment in 2010 and 2012)
## ---------------------------------------------------------------------------
cat("\n--- Placebo Timing ---\n")

pre_panel <- panel[year <= 2014]
for (fake_year in c(2010, 2012)) {
  pre_panel[, paste0("fake_treat_", fake_year) := as.integer(
    region_type == "treated_border" & year >= fake_year
  )]

  m_fake <- feols(as.formula(paste0("log_gdp_pc ~ fake_treat_", fake_year, " | nuts3 + year")),
                  data = pre_panel, cluster = ~nuts3)

  robustness_results[[paste0("placebo_", fake_year)]] <- data.table(
    check = paste0("Placebo timing: ", fake_year),
    estimate = coef(m_fake)[1],
    se = fixest::se(m_fake)[1],
    p_value = fixest::pvalue(m_fake)[1],
    n_obs = nobs(m_fake)
  )
  cat("Placebo", fake_year, ": coef =", round(coef(m_fake)[1], 4),
      "se =", round(fixest::se(m_fake)[1], 4), "\n")
}

## ---------------------------------------------------------------------------
## 3. Leave-one-segment-out
## ---------------------------------------------------------------------------
cat("\n--- Leave-One-Segment-Out ---\n")

segments <- unique(panel[region_type == "treated_border", border_segment])
segments <- segments[!is.na(segments)]

loo_results <- list()
for (seg in segments) {
  loo_data <- panel[!(region_type == "treated_border" & border_segment == seg)]

  m_loo <- tryCatch(
    feols(log_gdp_pc ~ treated | nuts3 + year,
          data = loo_data, cluster = ~nuts3),
    error = function(e) NULL
  )

  if (!is.null(m_loo)) {
    loo_results[[seg]] <- data.table(
      excluded_segment = seg,
      estimate = coef(m_loo)["treated"],
      se = fixest::se(m_loo)["treated"],
      p_value = fixest::pvalue(m_loo)["treated"],
      n_obs = nobs(m_loo)
    )
  }
}

loo_dt <- rbindlist(loo_results)
cat("Leave-one-segment-out:\n")
print(loo_dt)
fwrite(loo_dt, file.path(tables_dir, "leave_one_out.csv"))

## ---------------------------------------------------------------------------
## 4. Control group sensitivity
## ---------------------------------------------------------------------------
cat("\n--- Control Group Sensitivity ---\n")

# (a) Border regions only (no interior)
m_border_only <- feols(log_gdp_pc ~ treated | nuts3 + year,
                       data = panel[region_type != "interior"],
                       cluster = ~nuts3)

# (b) Interior regions only (no control borders)
m_interior_only <- feols(log_gdp_pc ~ treated | nuts3 + year,
                         data = panel[region_type != "control_border"],
                         cluster = ~nuts3)

# (c) Country fixed effects × year
m_country_year <- feols(log_gdp_pc ~ treated | nuts3 + country^year,
                        data = panel, cluster = ~nuts3)

robustness_results[["border_only"]] <- data.table(
  check = "Control: border regions only",
  estimate = coef(m_border_only)["treated"],
  se = fixest::se(m_border_only)["treated"],
  p_value = fixest::pvalue(m_border_only)["treated"],
  n_obs = nobs(m_border_only)
)

robustness_results[["interior_only"]] <- data.table(
  check = "Control: interior regions only",
  estimate = coef(m_interior_only)["treated"],
  se = fixest::se(m_interior_only)["treated"],
  p_value = fixest::pvalue(m_interior_only)["treated"],
  n_obs = nobs(m_interior_only)
)

robustness_results[["country_year"]] <- data.table(
  check = "Country × year FE",
  estimate = coef(m_country_year)["treated"],
  se = fixest::se(m_country_year)["treated"],
  p_value = fixest::pvalue(m_country_year)["treated"],
  n_obs = nobs(m_country_year)
)

## ---------------------------------------------------------------------------
## 5. COVID truncation (sample through 2019)
## ---------------------------------------------------------------------------
cat("\n--- COVID Truncation ---\n")

m_pre_covid <- feols(log_gdp_pc ~ treated | nuts3 + year,
                     data = panel[year <= 2019], cluster = ~nuts3)

robustness_results[["pre_covid"]] <- data.table(
  check = "Pre-COVID (through 2019)",
  estimate = coef(m_pre_covid)["treated"],
  se = fixest::se(m_pre_covid)["treated"],
  p_value = fixest::pvalue(m_pre_covid)["treated"],
  n_obs = nobs(m_pre_covid)
)

## ---------------------------------------------------------------------------
## 6. Wild cluster bootstrap (clustered at border segment level)
## ---------------------------------------------------------------------------
cat("\n--- Wild Cluster Bootstrap ---\n")

# Create segment-level cluster variable
panel[, cluster_var := fifelse(!is.na(border_segment), border_segment, nuts3)]

m_wcb <- tryCatch({
  boottest(m1, param = "treated", B = 9999,
           clustid = panel[!is.na(log_gdp_pc), .(cluster_seg = fifelse(!is.na(border_segment),
                                                                        border_segment, "control"))],
           type = "webb")
}, error = function(e) {
  # Fallback: cluster at country level
  cat("WCB at segment level failed:", e$message, "\n")
  cat("Using standard cluster-robust SEs as fallback\n")
  NULL
})

if (!is.null(m_wcb)) {
  robustness_results[["wcb"]] <- data.table(
    check = "Wild cluster bootstrap",
    estimate = coef(m1)["treated"],
    se = NA_real_,
    p_value = m_wcb$p_val,
    n_obs = nobs(m1)
  )
}

## ---------------------------------------------------------------------------
## 7. Randomization Inference
## ---------------------------------------------------------------------------
cat("\n--- Randomization Inference ---\n")

set.seed(42)
n_perms <- 1000
true_coef <- coef(m1)["treated"]

# Permute treatment assignment across regions (keeping time structure)
treated_regions <- unique(panel[region_type == "treated_border", nuts3])
all_regions <- unique(panel$nuts3)

ri_coefs <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  # Randomly assign same number of treated regions
  fake_treated <- sample(all_regions, length(treated_regions))

  ri_panel <- copy(panel)
  ri_panel[, ri_treat := as.integer(nuts3 %in% fake_treated & year >= 2015)]

  m_ri <- tryCatch(
    feols(log_gdp_pc ~ ri_treat | nuts3 + year, data = ri_panel, cluster = ~nuts3),
    error = function(e) NULL
  )

  if (!is.null(m_ri)) {
    ri_coefs[i] <- coef(m_ri)["ri_treat"]
  } else {
    ri_coefs[i] <- NA
  }

  if (i %% 200 == 0) cat("  RI permutation", i, "of", n_perms, "\n")
}

ri_coefs <- ri_coefs[!is.na(ri_coefs)]
ri_p <- mean(abs(ri_coefs) >= abs(true_coef))
cat("RI p-value:", ri_p, "(", sum(abs(ri_coefs) >= abs(true_coef)), "of",
    length(ri_coefs), "permutations)\n")

robustness_results[["ri"]] <- data.table(
  check = "Randomization inference",
  estimate = true_coef,
  se = NA_real_,
  p_value = ri_p,
  n_obs = nobs(m1)
)

# Save RI distribution for figure
fwrite(data.table(ri_coef = ri_coefs), file.path(data_dir, "ri_distribution.csv"))

## ---------------------------------------------------------------------------
## 8. HonestDiD — Rambachan-Roth sensitivity
## ---------------------------------------------------------------------------
cat("\n--- HonestDiD Sensitivity ---\n")

honest_result <- tryCatch({
  # Extract pre-treatment coefficients from event study
  es_coefs_csv <- fread(file.path(tables_dir, "tab3_event_study.csv"))
  pre_coefs <- es_coefs_csv[event_time < 0]
  post_coefs <- es_coefs_csv[event_time >= 0]

  if (nrow(pre_coefs) >= 2 && nrow(post_coefs) >= 1) {
    # Use fixest::iplot data for HonestDiD
    betahat <- c(pre_coefs$estimate, post_coefs$estimate)
    sigma <- diag(c(pre_coefs$se, post_coefs$se)^2)  # Simplified covariance

    # Relative magnitudes approach
    delta_rm_results <- createSensitivityResults_relativeMagnitudes(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = nrow(pre_coefs),
      numPostPeriods = nrow(post_coefs),
      Mbarvec = seq(0, 2, by = 0.5)
    )
    delta_rm_results
  } else {
    cat("Not enough pre/post periods for HonestDiD\n")
    NULL
  }
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
  NULL
})

if (!is.null(honest_result)) {
  honest_dt <- as.data.table(honest_result)
  fwrite(honest_dt, file.path(tables_dir, "honestdid_sensitivity.csv"))
  cat("HonestDiD results saved.\n")
}

## ---------------------------------------------------------------------------
## 9. Compile robustness summary table
## ---------------------------------------------------------------------------
rob_table <- rbindlist(robustness_results, fill = TRUE)
rob_table[, ci_lower := estimate - 1.96 * se]
rob_table[, ci_upper := estimate + 1.96 * se]
rob_table[, stars := fifelse(p_value < 0.01, "***",
                    fifelse(p_value < 0.05, "**",
                    fifelse(p_value < 0.1, "*", "")))]

cat("\nRobustness Summary:\n")
print(rob_table)

fwrite(rob_table, file.path(tables_dir, "tab5_robustness.csv"))

## ---------------------------------------------------------------------------
## 10. Segment-level Randomization Inference
## ---------------------------------------------------------------------------
cat("\n--- Segment-Level Randomization Inference ---\n")

# Permute treatment at border-segment level (not region level)
# This respects the actual assignment mechanism
set.seed(123)
n_seg_perms <- 1000

# Get unique border segments and their regions
seg_map <- unique(panel[region_type == "treated_border" & !is.na(border_segment),
                         .(border_segment, nuts3, first_treat)])
true_segments <- unique(seg_map$border_segment)
n_treat_seg <- length(true_segments)

# All border segments (treated + control)
# Create "fake segments" from control border regions grouped by country
ctrl_regions <- unique(panel[region_type == "control_border", .(nuts3, country)])
# Group control regions into pseudo-segments by country
ctrl_regions[, fake_segment := paste0("ctrl_", country)]
ctrl_segs <- unique(ctrl_regions$fake_segment)

all_segs <- c(true_segments, ctrl_segs)
cat("  Total segments:", length(all_segs), "(", n_treat_seg, "treated,",
    length(ctrl_segs), "control pseudo-segments)\n")

seg_ri_coefs <- numeric(n_seg_perms)
for (i in seq_len(n_seg_perms)) {
  # Randomly select which segments are "treated"
  fake_treat_segs <- sample(all_segs, n_treat_seg)

  ri_panel2 <- copy(panel)
  # Determine which regions belong to fake-treated segments
  fake_treat_regions <- character(0)
  for (s in fake_treat_segs) {
    if (s %in% true_segments) {
      fake_treat_regions <- c(fake_treat_regions,
                               seg_map[border_segment == s, nuts3])
    } else {
      fake_treat_regions <- c(fake_treat_regions,
                               ctrl_regions[fake_segment == s, nuts3])
    }
  }
  ri_panel2[, seg_ri_treat := as.integer(nuts3 %in% fake_treat_regions & year >= 2015)]

  m_seg_ri <- tryCatch(
    feols(log_gdp_pc ~ seg_ri_treat | nuts3 + year, data = ri_panel2, cluster = ~nuts3),
    error = function(e) NULL
  )

  if (!is.null(m_seg_ri)) {
    seg_ri_coefs[i] <- coef(m_seg_ri)["seg_ri_treat"]
  } else {
    seg_ri_coefs[i] <- NA
  }

  if (i %% 200 == 0) cat("  Seg-RI permutation", i, "of", n_seg_perms, "\n")
}

seg_ri_coefs <- seg_ri_coefs[!is.na(seg_ri_coefs)]
seg_ri_p <- mean(abs(seg_ri_coefs) >= abs(true_coef))
cat("Segment-level RI p-value:", seg_ri_p, "\n")
cat("  Permutation SD:", round(sd(seg_ri_coefs), 4), "\n")

robustness_results[["seg_ri"]] <- data.table(
  check = "Segment-level RI",
  estimate = true_coef,
  se = NA_real_,
  p_value = seg_ri_p,
  n_obs = nobs(m1)
)

fwrite(data.table(seg_ri_coef = seg_ri_coefs), file.path(data_dir, "seg_ri_distribution.csv"))

## ---------------------------------------------------------------------------
## 11. Placebos under Country-by-Year FE
## ---------------------------------------------------------------------------
cat("\n--- Placebos under Country × Year FE ---\n")

# Placebo: unaffected borders with country × year FE
m_placebo_cy <- tryCatch(
  feols(log_gdp_pc ~ placebo_treated | nuts3 + country^year,
        data = placebo_panel, cluster = ~nuts3),
  error = function(e) { cat("Placebo C×Y failed:", e$message, "\n"); NULL }
)

if (!is.null(m_placebo_cy)) {
  robustness_results[["placebo_borders_cy"]] <- data.table(
    check = "Placebo borders + C×Y FE",
    estimate = coef(m_placebo_cy)["placebo_treated"],
    se = fixest::se(m_placebo_cy)["placebo_treated"],
    p_value = fixest::pvalue(m_placebo_cy)["placebo_treated"],
    n_obs = nobs(m_placebo_cy)
  )
  cat("Placebo (borders, C×Y FE): coef =",
      round(coef(m_placebo_cy)["placebo_treated"], 4), "\n")
}

# Timing placebo with country × year FE
pre_panel_cy <- panel[year <= 2014]
pre_panel_cy[, fake_treat_2010 := as.integer(
  region_type == "treated_border" & year >= 2010
)]

m_fake_cy <- tryCatch(
  feols(log_gdp_pc ~ fake_treat_2010 | nuts3 + country^year,
        data = pre_panel_cy, cluster = ~nuts3),
  error = function(e) { cat("Timing placebo C×Y failed:", e$message, "\n"); NULL }
)

if (!is.null(m_fake_cy)) {
  robustness_results[["placebo_2010_cy"]] <- data.table(
    check = "Placebo 2010 + C×Y FE",
    estimate = coef(m_fake_cy)["fake_treat_2010"],
    se = fixest::se(m_fake_cy)["fake_treat_2010"],
    p_value = fixest::pvalue(m_fake_cy)["fake_treat_2010"],
    n_obs = nobs(m_fake_cy)
  )
  cat("Placebo 2010 (C×Y FE): coef =",
      round(coef(m_fake_cy)["fake_treat_2010"], 4), "\n")
}

## ---------------------------------------------------------------------------
## 12. Border-only + Country × Year FE (preferred specification)
## ---------------------------------------------------------------------------
cat("\n--- Border-only + Country × Year FE ---\n")

border_panel <- panel[region_type != "interior"]
m_border_cy <- feols(log_gdp_pc ~ treated | nuts3 + country^year,
                     data = border_panel, cluster = ~nuts3)

robustness_results[["border_cy"]] <- data.table(
  check = "Border only + C×Y FE",
  estimate = coef(m_border_cy)["treated"],
  se = fixest::se(m_border_cy)["treated"],
  p_value = fixest::pvalue(m_border_cy)["treated"],
  n_obs = nobs(m_border_cy)
)

cat("Border only + C×Y FE: coef =", round(coef(m_border_cy)["treated"], 4),
    "se =", round(fixest::se(m_border_cy)["treated"], 4), "\n")

## ---------------------------------------------------------------------------
## Recompile robustness summary
## ---------------------------------------------------------------------------
rob_table <- rbindlist(robustness_results, fill = TRUE)
rob_table[, ci_lower := estimate - 1.96 * se]
rob_table[, ci_upper := estimate + 1.96 * se]
rob_table[, stars := fifelse(p_value < 0.01, "***",
                    fifelse(p_value < 0.05, "**",
                    fifelse(p_value < 0.1, "*", "")))]

cat("\nFull Robustness Summary:\n")
print(rob_table)

fwrite(rob_table, file.path(tables_dir, "tab5_robustness.csv"))

cat("\n04_robustness.R complete.\n")
