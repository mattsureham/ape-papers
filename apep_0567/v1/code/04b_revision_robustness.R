# ==============================================================================
# 04b_revision_robustness.R — Additional robustness for revision
# Paper: Protecting Landscapes, Punishing Renters (apep_0567)
#
# Analyses:
#   1. Local DiD (near-threshold municipalities: 10-30%, 5-35%, 15-25%)
#   2. Joint pre-trends F-test (Wald test on pre-treatment event study coefs)
#   3. Canton-by-year fixed effects
#
# Inputs:  ../data/panel.csv
# Outputs: ../data/local_did.csv, ../data/pretrends_test.csv,
#          ../data/canton_year_fe.csv
# ==============================================================================

library(data.table)
library(fixest)

# --- Paths -------------------------------------------------------------------
data_dir   <- normalizePath("../data", mustWork = FALSE)
input_file <- file.path(data_dir, "panel.csv")

stopifnot(
  "panel.csv not found — run 02_clean_data.R first" = file.exists(input_file)
)

panel <- fread(input_file)
cat(sprintf("Loaded panel: %s obs, %s municipalities, years %s-%s\n",
            format(nrow(panel), big.mark = ","),
            uniqueN(panel$gem_id),
            min(panel$year), max(panel$year)))

# Ensure key variables are typed correctly
panel[, `:=`(
  gem_id    = as.character(gem_id),
  year      = as.integer(year),
  treated   = as.integer(treated),
  post      = as.integer(post),
  canton_id = as.character(canton_id)
)]

# Ensure rel_year exists
panel[, rel_year := year - 2013L]

# ==============================================================================
# 1. LOCAL DiD — Near-threshold municipalities
# ==============================================================================
cat("\n=== 1. Local DiD (near-threshold bandwidths) ===\n")

run_local_did <- function(dt, bw_lower, bw_upper) {
  local_panel <- dt[second_home_share >= bw_lower & second_home_share <= bw_upper]
  local_panel <- local_panel[!is.na(vacancy_rate)]

  n_obs   <- nrow(local_panel)
  n_units <- uniqueN(local_panel$gem_id)

  if (n_obs < 50 || n_units < 10) {
    warning(sprintf("Too few obs/units for bandwidth [%g, %g]: %d obs, %d units",
                    bw_lower, bw_upper, n_obs, n_units))
    return(NULL)
  }

  tryCatch({
    est <- feols(vacancy_rate ~ treated:post | gem_id + year,
                 data = local_panel, cluster = ~canton_id)
    ct  <- coeftable(est)
    data.table(
      coef      = ct[1, "Estimate"],
      se        = ct[1, "Std. Error"],
      pvalue    = ct[1, "Pr(>|t|)"],
      n_obs     = est$nobs,
      n_units   = n_units,
      bandwidth = sprintf("%g-%g", bw_lower, bw_upper)
    )
  }, error = function(e) {
    warning(sprintf("Local DiD failed for [%g, %g]: %s",
                    bw_lower, bw_upper, e$message))
    NULL
  })
}

bandwidths <- list(
  c(10, 30),
  c(5, 35),
  c(15, 25)
)

local_did_results <- rbindlist(
  lapply(bandwidths, function(bw) run_local_did(panel, bw[1], bw[2]))
)

if (nrow(local_did_results) > 0) {
  fwrite(local_did_results, file.path(data_dir, "local_did.csv"))
  cat("  Local DiD results:\n")
  print(local_did_results[, .(bandwidth,
                               coef   = round(coef, 4),
                               se     = round(se, 4),
                               pvalue = round(pvalue, 4),
                               n_obs, n_units)])
} else {
  warning("No local DiD results produced.")
}

# ==============================================================================
# 2. FORMAL JOINT PRE-TRENDS TEST (Wald test)
# ==============================================================================
cat("\n=== 2. Joint Pre-Trends Test ===\n")

# Run event study on full panel
es_panel <- panel[!is.na(vacancy_rate)]

tryCatch({
  es_model <- feols(vacancy_rate ~ i(rel_year, treated, ref = -1) | gem_id + year,
                    data = es_panel, cluster = ~canton_id)

  cat("  Event study coefficients:\n")
  print(coeftable(es_model))

  # Identify pre-treatment coefficient names (rel_year < 0, excluding ref = -1)
  coef_names <- names(coef(es_model))
  # Pre-treatment coefficients: those with negative rel_year (excluding -1 which is ref)
  pre_coefs <- grep("rel_year::(-[0-9]+):treated", coef_names, value = TRUE)
  # Keep only those that are actually pre-treatment (negative rel_year, not -1)
  pre_coefs <- pre_coefs[!grepl("::-1:", pre_coefs)]
  cat(sprintf("  Pre-treatment coefficients for Wald test: %s\n",
              paste(pre_coefs, collapse = ", ")))

  if (length(pre_coefs) > 0) {
    # Wald test: H0: all pre-treatment coefficients = 0
    wt <- wald(es_model, pre_coefs)

    # Extract test statistics from wald output
    # wald() returns an object; print it to see structure
    cat("  Wald test output:\n")
    print(wt)

    # The wald function returns a list with stat, p, df1, df2
    pretrends_test <- data.table(
      f_stat  = wt$stat,
      df1     = wt$df1,
      df2     = wt$df2,
      p_value = wt$p
    )

    fwrite(pretrends_test, file.path(data_dir, "pretrends_test.csv"))
    cat(sprintf("  Joint F-test: F(%d, %d) = %.3f, p = %.4f\n",
                pretrends_test$df1, pretrends_test$df2,
                pretrends_test$f_stat, pretrends_test$p_value))
  } else {
    warning("No pre-treatment coefficients found for Wald test.")
  }
}, error = function(e) {
  cat(sprintf("  Event study / Wald test failed: %s\n", e$message))
})

# ==============================================================================
# 3. CANTON-BY-YEAR FIXED EFFECTS
# ==============================================================================
cat("\n=== 3. Canton-by-Year Fixed Effects ===\n")

canton_panel <- panel[!is.na(vacancy_rate)]

tryCatch({
  est_canton <- feols(vacancy_rate ~ treated:post | gem_id + canton_id^year,
                      data = canton_panel, cluster = ~canton_id)
  ct <- coeftable(est_canton)

  canton_year_fe <- data.table(
    coef      = ct[1, "Estimate"],
    se        = ct[1, "Std. Error"],
    t_stat    = ct[1, "t value"],
    pvalue    = ct[1, "Pr(>|t|)"],
    n_obs     = est_canton$nobs,
    n_units   = uniqueN(canton_panel$gem_id),
    r2_within = tryCatch(fitstat(est_canton, "wr2")[[1]], error = function(e) NA_real_)
  )

  fwrite(canton_year_fe, file.path(data_dir, "canton_year_fe.csv"))
  cat("  Canton-by-year FE results:\n")
  print(canton_year_fe[, .(coef   = round(coef, 4),
                            se     = round(se, 4),
                            pvalue = round(pvalue, 4),
                            n_obs, n_units)])
}, error = function(e) {
  cat(sprintf("  Canton-by-year FE failed: %s\n", e$message))
})

# ==============================================================================
# SUMMARY
# ==============================================================================
cat("\n=== 04b Revision Robustness Complete ===\n")
output_files <- c("local_did.csv", "pretrends_test.csv", "canton_year_fe.csv")
for (f in output_files) {
  fp <- file.path(data_dir, f)
  if (file.exists(fp)) {
    cat(sprintf("  [OK] %s\n", f))
  } else {
    cat(sprintf("  [MISSING] %s\n", f))
  }
}
cat("Done.\n")
