# ==============================================================================
# 03_main_analysis.R — Main empirical analysis
# Paper: Protecting Landscapes, Punishing Renters (apep_0567)
# Switzerland's 2012 Second Homes Initiative (Lex Weber)
#
# Inputs:  ../data/panel.csv (from 02_clean_data.R)
# Outputs: ../data/sumstats.csv, did_main.csv, event_study_*.csv,
#          cs_did_results.csv, rdd_results.csv, mechanism_sectors.csv,
#          heterogeneity.csv
# ==============================================================================

source("00_packages.R")

# --- Paths -------------------------------------------------------------------
data_dir  <- normalizePath("../data", mustWork = FALSE)
input_file <- file.path(data_dir, "panel.csv")

stopifnot(
  "panel.csv not found — run 02_clean_data.R first" = file.exists(input_file)
)

panel <- data.table::fread(input_file)
cat(sprintf("Loaded panel: %s obs, %s municipalities, years %s-%s\n",
            format(nrow(panel), big.mark = ","),
            uniqueN(panel$gem_id),
            min(panel$year), max(panel$year)))

# Ensure key variables are typed correctly
panel[, `:=`(
  gem_id            = as.character(gem_id),
  year              = as.integer(year),
  treated           = as.integer(treated),
  post              = as.integer(post),
  canton_id         = as.character(canton_id),
  german_speaking   = as.integer(german_speaking),
  tourism_intensity = as.factor(tourism_intensity)
)]

# ==============================================================================
# 1. SUMMARY STATISTICS TABLE
# ==============================================================================
cat("\n=== 1. Summary Statistics (pre-treatment 2010-2012) ===\n")

sumstat_vars <- c("vacancy_rate", "population", "log_pop",
                  "emp_total", "emp_secondary", "emp_tertiary",
                  "second_home_share")

pre <- panel[year >= 2010 & year <= 2012]

compute_sumstats <- function(dt, varnames) {
  rbindlist(lapply(varnames, function(v) {
    x <- dt[[v]]
    x <- x[!is.na(x)]
    data.table(
      variable = v,
      n        = length(x),
      mean     = mean(x),
      sd       = sd(x),
      median   = median(x),
      p25      = quantile(x, 0.25),
      p75      = quantile(x, 0.75)
    )
  }))
}

ss_treated <- compute_sumstats(pre[treated == 1], sumstat_vars)
ss_control <- compute_sumstats(pre[treated == 0], sumstat_vars)

ss_treated[, group := "treated"]
ss_control[, group := "control"]
sumstats <- rbind(ss_treated, ss_control)

fwrite(sumstats, file.path(data_dir, "sumstats.csv"))
cat(sprintf("  Treated municipalities: %d, Control: %d\n",
            uniqueN(pre[treated == 1]$gem_id),
            uniqueN(pre[treated == 0]$gem_id)))

# ==============================================================================
# 2. MAIN DiD (TWFE BASELINE)
# ==============================================================================
cat("\n=== 2. Main TWFE DiD ===\n")

main_outcomes <- c("vacancy_rate", "log_pop",
                   "log_emp_total", "log_emp_tertiary")

run_twfe <- function(yvar, dt) {
  # For employment outcomes, restrict to years with data (2011+)
  if (grepl("^log_emp", yvar)) {
    dt <- dt[year >= 2011]
  }
  # Drop rows with missing outcome
  dt <- dt[!is.na(get(yvar))]
  if (nrow(dt) == 0) return(NULL)

  fml <- as.formula(paste0(yvar, " ~ treated:post | gem_id + year"))
  tryCatch({
    est <- feols(fml, data = dt, cluster = ~canton_id)
    ct  <- coeftable(est)
    data.table(
      outcome     = yvar,
      coefficient = ct[1, "Estimate"],
      se          = ct[1, "Std. Error"],
      t_stat      = ct[1, "t value"],
      p_value     = ct[1, "Pr(>|t|)"],
      n_obs       = est$nobs,
      n_units     = length(unique(dt$gem_id)),
      r2_within   = tryCatch(fitstat(est, "wr2")[[1]], error = function(e) NA_real_)
    )
  }, error = function(e) {
    warning(sprintf("TWFE failed for %s: %s", yvar, e$message))
    NULL
  })
}

did_main <- rbindlist(lapply(main_outcomes, run_twfe, dt = copy(panel)))

if (nrow(did_main) > 0) {
  fwrite(did_main, file.path(data_dir, "did_main.csv"))
  cat("  Results:\n")
  print(did_main[, .(outcome, coefficient = round(coefficient, 4),
                     se = round(se, 4), p_value = round(p_value, 4))])
} else {
  warning("No TWFE results produced.")
}

# ==============================================================================
# 3. EVENT STUDY
# ==============================================================================
cat("\n=== 3. Event Study ===\n")

# Create relative time variable (treatment year = 2013)
panel[, rel_year := year - 2013L]
# Bin endpoints at -10 and +10
panel[, rel_year_binned := pmax(pmin(rel_year, 10L), -10L)]

run_event_study <- function(yvar, dt) {
  if (grepl("^log_emp", yvar)) {
    dt <- dt[year >= 2011]
  }
  dt <- dt[!is.na(get(yvar))]
  if (nrow(dt) == 0) return(NULL)

  fml <- as.formula(paste0(
    yvar, " ~ i(rel_year_binned, treated, ref = -1) | gem_id + year"
  ))
  tryCatch({
    est <- feols(fml, data = dt, cluster = ~canton_id)
    ct  <- as.data.table(coeftable(est), keep.rownames = "term")

    # Extract relative year from coefficient names
    ct[, rel_year := as.integer(gsub(".*::(-?\\d+):.*", "\\1", term))]
    ct[, .(
      rel_year,
      coefficient = Estimate,
      se          = `Std. Error`,
      ci_lower    = Estimate - 1.96 * `Std. Error`,
      ci_upper    = Estimate + 1.96 * `Std. Error`,
      p_value     = `Pr(>|t|)`
    )]
  }, error = function(e) {
    warning(sprintf("Event study failed for %s: %s", yvar, e$message))
    NULL
  })
}

# Vacancy rate event study
es_vacancy <- run_event_study("vacancy_rate", copy(panel))
if (!is.null(es_vacancy)) {
  fwrite(es_vacancy, file.path(data_dir, "event_study_vacancy.csv"))
  cat("  Vacancy rate event study: ", nrow(es_vacancy), " coefficients\n")
}

# Population event study
es_pop <- run_event_study("log_pop", copy(panel))
if (!is.null(es_pop)) {
  fwrite(es_pop, file.path(data_dir, "event_study_pop.csv"))
  cat("  Population event study: ", nrow(es_pop), " coefficients\n")
}

# ==============================================================================
# 4. CALLAWAY-SANT'ANNA DiD
# ==============================================================================
cat("\n=== 4. Callaway-Sant'Anna DiD ===\n")

# All treated units have g = 2013 (uniform treatment timing)
panel[, g_year := fifelse(treated == 1L, 2013L, 0L)]

run_cs_did <- function(yvar, dt) {
  if (grepl("^log_emp", yvar)) {
    dt <- dt[year >= 2011]
  }
  dt <- dt[!is.na(get(yvar))]
  if (nrow(dt) == 0) return(NULL)

  # CS DiD requires numeric id and time; never-treated = 0
  dt[, id_num := as.integer(as.factor(gem_id))]
  # gname must be numeric — treated get 2013, never-treated get 0
  dt_df <- as.data.frame(dt)
  dt_df$g_year_cs <- ifelse(dt_df$treated == 1, 2013, 0)

  tryCatch({
    cs_out <- att_gt(
      yname  = yvar,
      tname  = "year",
      idname = "id_num",
      gname  = "g_year_cs",
      data   = dt_df,
      control_group = "nevertreated",
      base_period   = "universal"
    )

    # Aggregate to overall ATT
    agg_overall <- aggte(cs_out, type = "simple")

    # Aggregate to dynamic (event-study style)
    agg_dynamic <- aggte(cs_out, type = "dynamic")

    # Combine results
    overall_row <- data.table(
      outcome     = yvar,
      type        = "overall",
      estimate    = agg_overall$overall.att,
      se          = agg_overall$overall.se,
      ci_lower    = agg_overall$overall.att - 1.96 * agg_overall$overall.se,
      ci_upper    = agg_overall$overall.att + 1.96 * agg_overall$overall.se,
      rel_year    = NA_integer_
    )

    dynamic_rows <- data.table(
      outcome     = yvar,
      type        = "dynamic",
      estimate    = agg_dynamic$att.egt,
      se          = agg_dynamic$se.egt,
      ci_lower    = agg_dynamic$att.egt - 1.96 * agg_dynamic$se.egt,
      ci_upper    = agg_dynamic$att.egt + 1.96 * agg_dynamic$se.egt,
      rel_year    = agg_dynamic$egt
    )

    rbind(overall_row, dynamic_rows)
  }, error = function(e) {
    warning(sprintf("CS-DiD failed for %s: %s", yvar, e$message))
    NULL
  })
}

cs_outcomes <- c("vacancy_rate", "log_pop")
cs_results  <- rbindlist(lapply(cs_outcomes, run_cs_did, dt = copy(panel)))

if (!is.null(cs_results) && nrow(cs_results) > 0) {
  fwrite(cs_results, file.path(data_dir, "cs_did_results.csv"))
  cat("  CS-DiD overall ATTs:\n")
  print(cs_results[type == "overall",
                   .(outcome, estimate = round(estimate, 4),
                     se = round(se, 4))])
} else {
  warning("No CS-DiD results produced.")
}

# ==============================================================================
# 5. RDD AT 20% THRESHOLD
# ==============================================================================
cat("\n=== 5. RDD at 20% Second-Home Threshold ===\n")

# Collapse to municipality-level post-treatment means for cross-sectional RDD
post_data <- panel[post == 1 & !is.na(second_home_share)]
post_data <- post_data[, .(
  vacancy_rate = mean(vacancy_rate, na.rm = TRUE),
  log_pop      = mean(log_pop, na.rm = TRUE),
  second_home_share = mean(second_home_share)
), by = gem_id]

run_rdd <- function(yvar, dt, cutoff = 20) {
  dt <- dt[!is.na(get(yvar))]
  if (nrow(dt) == 0) return(NULL)

  tryCatch({
    rd <- rdrobust(
      y = dt[[yvar]],
      x = dt[["second_home_share"]],
      c = cutoff
    )

    # Density test at the cutoff
    dens <- tryCatch({
      rddensity(X = dt[["second_home_share"]], c = cutoff)
    }, error = function(e) NULL)

    # rdrobust output: coef/se/pv are matrices or vectors
    data.table(
      outcome        = yvar,
      rd_estimate    = rd$coef[1],
      rd_se          = rd$se[3],  # robust SE
      rd_p_value     = rd$pv[3],  # robust p-value
      rd_bw          = rd$bws[1, 1],
      rd_n_left      = rd$N_h[1],
      rd_n_right     = rd$N_h[2],
      rd_bc_estimate = rd$coef[2],
      rd_robust_ci_l = rd$ci[3, 1],
      rd_robust_ci_u = rd$ci[3, 2],
      density_p      = if (!is.null(dens)) dens$test$p_jk else NA_real_
    )
  }, error = function(e) {
    warning(sprintf("RDD failed for %s: %s", yvar, e$message))
    NULL
  })
}

rdd_outcomes <- c("vacancy_rate", "log_pop")
rdd_results  <- rbindlist(lapply(rdd_outcomes, run_rdd, dt = copy(post_data)))

if (!is.null(rdd_results) && nrow(rdd_results) > 0) {
  fwrite(rdd_results, file.path(data_dir, "rdd_results.csv"))
  cat("  RDD results:\n")
  print(rdd_results[, .(outcome,
                        rd_estimate = round(rd_estimate, 4),
                        rd_se       = round(rd_se, 4),
                        rd_p_value  = round(rd_p_value, 4),
                        density_p   = round(density_p, 4))])
} else {
  warning("No RDD results produced.")
}

# ==============================================================================
# 6. MECHANISM: EMPLOYMENT BY SECTOR
# ==============================================================================
cat("\n=== 6. Mechanism — Employment by Sector ===\n")

sector_outcomes <- c("log_emp_total", "log_emp_secondary",
                     "log_emp_tertiary")

mechanism_results <- rbindlist(lapply(sector_outcomes, run_twfe, dt = copy(panel)))

if (nrow(mechanism_results) > 0) {
  fwrite(mechanism_results, file.path(data_dir, "mechanism_sectors.csv"))
  cat("  Sector DiD results:\n")
  print(mechanism_results[, .(outcome,
                              coefficient = round(coefficient, 4),
                              se          = round(se, 4),
                              p_value     = round(p_value, 4))])
} else {
  warning("No mechanism results produced.")
}

# ==============================================================================
# 7. HETEROGENEITY
# ==============================================================================
cat("\n=== 7. Heterogeneity Analysis ===\n")

run_twfe_subset <- function(yvar, dt, subset_var, subset_val, subset_label) {
  dt_sub <- dt[get(subset_var) == subset_val]
  if (grepl("^log_emp", yvar)) {
    dt_sub <- dt_sub[year >= 2011]
  }
  dt_sub <- dt_sub[!is.na(get(yvar))]
  if (nrow(dt_sub) < 50) {
    warning(sprintf("Too few obs for %s | %s=%s (%d rows)",
                    yvar, subset_var, subset_val, nrow(dt_sub)))
    return(NULL)
  }

  fml <- as.formula(paste0(yvar, " ~ treated:post | gem_id + year"))
  tryCatch({
    est <- feols(fml, data = dt_sub, cluster = ~canton_id)
    ct  <- coeftable(est)
    data.table(
      outcome     = yvar,
      het_dim     = subset_var,
      het_group   = subset_label,
      coefficient = ct[1, "Estimate"],
      se          = ct[1, "Std. Error"],
      p_value     = ct[1, "Pr(>|t|)"],
      n_obs       = est$nobs,
      n_units     = uniqueN(dt_sub$gem_id)
    )
  }, error = function(e) {
    warning(sprintf("Heterogeneity failed for %s | %s=%s: %s",
                    yvar, subset_var, subset_val, e$message))
    NULL
  })
}

het_results <- list()

# --- 7a. By tourism intensity ------------------------------------------------
cat("  7a. By tourism intensity\n")
for (tl in c("high", "medium", "low")) {
  for (yv in c("vacancy_rate", "log_pop")) {
    het_results <- c(het_results, list(
      run_twfe_subset(yv, copy(panel), "tourism_intensity", tl,
                      paste0("tourism_", tl))
    ))
  }
}

# --- 7b. By language region ---------------------------------------------------
cat("  7b. By language region\n")
for (lang in c(1L, 0L)) {
  label <- if (lang == 1L) "german" else "french_italian"
  for (yv in c("vacancy_rate", "log_pop")) {
    het_results <- c(het_results, list(
      run_twfe_subset(yv, copy(panel), "german_speaking", lang,
                      paste0("lang_", label))
    ))
  }
}

# --- 7c. By treatment intensity (above/below median second-home share) --------
cat("  7c. By treatment intensity\n")
med_sh <- median(panel[treated == 1]$second_home_share, na.rm = TRUE)
panel[, high_intensity := fifelse(second_home_share >= med_sh & treated == 1, 1L,
                                   fifelse(treated == 1, 0L, NA_integer_))]

# Only among treated units
for (int_val in c(1L, 0L)) {
  label <- if (int_val == 1L) "high_intensity" else "low_intensity"
  for (yv in c("vacancy_rate", "log_pop")) {
    dt_sub <- copy(panel)[treated == 1 | treated == 0]  # keep all, subset below
    het_results <- c(het_results, list(
      tryCatch({
        # Use continuous treatment: interact treated*post with high_intensity dummy
        dt_int <- copy(panel)[treated == 1]
        dt_int <- dt_int[high_intensity == int_val]
        # Add back controls
        dt_int <- rbind(dt_int, panel[treated == 0], fill = TRUE)
        run_twfe(yv, dt_int)
      }, error = function(e) NULL)
    ))
    if (!is.null(het_results[[length(het_results)]])) {
      het_results[[length(het_results)]]$het_dim <- "intensity"
      het_results[[length(het_results)]]$het_group <- paste0("intensity_", label)
    }
  }
}

heterogeneity <- rbindlist(het_results[!sapply(het_results, is.null)], fill = TRUE)

if (nrow(heterogeneity) > 0) {
  fwrite(heterogeneity, file.path(data_dir, "heterogeneity.csv"))
  cat("  Heterogeneity results:\n")
  print(heterogeneity[, .(outcome, het_group,
                          coefficient = round(coefficient, 4),
                          se          = round(se, 4),
                          p_value     = round(p_value, 4),
                          n_units)])
} else {
  warning("No heterogeneity results produced.")
}

# ==============================================================================
# SUMMARY
# ==============================================================================
cat("\n=== Analysis Complete ===\n")
output_files <- c(
  "sumstats.csv", "did_main.csv",
  "event_study_vacancy.csv", "event_study_pop.csv",
  "cs_did_results.csv", "rdd_results.csv",
  "mechanism_sectors.csv", "heterogeneity.csv"
)
for (f in output_files) {
  fp <- file.path(data_dir, f)
  if (file.exists(fp)) {
    cat(sprintf("  [OK] %s (%s rows)\n", f,
                format(nrow(fread(fp, nrows = Inf)), big.mark = ",")))
  } else {
    cat(sprintf("  [MISSING] %s\n", f))
  }
}
cat("Done.\n")
