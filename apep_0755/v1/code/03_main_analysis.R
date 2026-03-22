## =============================================================================
## 03_main_analysis.R — Main RDD estimation at estrato boundaries
## Paper: Estrato Boundaries and Educational Sorting in Colombia (apep_0755)
## =============================================================================

source("00_packages.R")

cat("=== Main Analysis: RDD at Estrato Boundaries ===\n")

## Load cleaned data
df <- fread("../data/icfes_clean.csv")
school_df <- fread("../data/school_panel.csv")

## -----------------------------------------------------------------------------
## DESIGN 1: Student-level discontinuity at each estrato boundary
##
## For each boundary k|k+1, we restrict to students in estrato k or k+1
## within the same municipality. The identifying assumption is that
## students just across the estrato boundary are comparable after
## conditioning on municipality.
##
## Following Lee & Card (2008) for RDD with discrete running variable:
## - Cluster standard errors at the municipality-estrato level
## - Include municipality FE
## - Test covariate balance at each boundary
## -----------------------------------------------------------------------------

## Create boundary-specific samples and estimate effects
boundaries <- 1:5  # 1|2, 2|3, 3|4, 4|5, 5|6
results_list <- list()
balance_list <- list()

for (k in boundaries) {
  cat(sprintf("\n--- Boundary %d|%d ---\n", k, k + 1))

  ## Restrict to students at this boundary
  bd <- df[estrato %in% c(k, k + 1)]
  bd[, treated := as.integer(estrato == k + 1)]

  ## Need at least 2 municipalities with both estratos
  both_estratos <- bd[, .(
    has_low  = any(estrato == k),
    has_high = any(estrato == k + 1)
  ), by = cole_mcpio_ubicacion]
  valid_munis <- both_estratos[has_low == TRUE & has_high == TRUE, cole_mcpio_ubicacion]

  bd <- bd[cole_mcpio_ubicacion %in% valid_munis]
  cat(sprintf("  Valid municipalities: %d\n", length(valid_munis)))
  cat(sprintf("  Students: %s (estrato %d: %s, estrato %d: %s)\n",
              format(nrow(bd), big.mark = ","),
              k, format(sum(bd$treated == 0), big.mark = ","),
              k + 1, format(sum(bd$treated == 1), big.mark = ",")))

  if (nrow(bd) < 100) {
    cat("  SKIP: too few observations\n")
    next
  }

  ## Create cluster variable
  bd[, cluster_id := paste(cole_mcpio_ubicacion, estrato, sep = "_")]

  ## ----- Main specification: global score with municipality FE -----
  ## Cluster at municipality level (conservative)
  reg_main <- feols(
    punt_global ~ treated | cole_mcpio_ubicacion,
    data = bd,
    cluster = ~cole_mcpio_ubicacion
  )

  ## ----- With student controls -----
  reg_controls <- feols(
    punt_global ~ treated + female + has_internet + has_computer +
      has_car + has_washer + max_parent_educ | cole_mcpio_ubicacion,
    data = bd,
    cluster = ~cole_mcpio_ubicacion
  )

  ## ----- Math score -----
  reg_math <- feols(
    punt_matematicas ~ treated | cole_mcpio_ubicacion,
    data = bd,
    cluster = ~cole_mcpio_ubicacion
  )

  ## ----- Reading score -----
  reg_reading <- feols(
    punt_lectura_critica ~ treated | cole_mcpio_ubicacion,
    data = bd,
    cluster = ~cole_mcpio_ubicacion
  )

  ## Store results
  results_list[[paste0("b", k)]] <- list(
    boundary = paste0(k, "|", k + 1),
    k = k,
    n_obs = nrow(bd),
    n_treated = sum(bd$treated == 1),
    n_control = sum(bd$treated == 0),
    n_munis = length(valid_munis),
    reg_main = reg_main,
    reg_controls = reg_controls,
    reg_math = reg_math,
    reg_reading = reg_reading,
    mean_y_control = mean(bd[treated == 0, punt_global], na.rm = TRUE),
    sd_y_control = sd(bd[treated == 0, punt_global], na.rm = TRUE)
  )

  cat(sprintf("  Main effect: %.2f (SE: %.2f)\n",
              coef(reg_main)["treated"],
              se(reg_main)["treated"]))

  ## ----- Covariate balance tests -----
  covs <- c("female", "has_internet", "has_computer", "has_car",
            "has_washer", "max_parent_educ", "asset_index")

  for (cov in covs) {
    if (cov %in% names(bd) && sum(!is.na(bd[[cov]])) > 50) {
      bal_reg <- feols(
        as.formula(paste(cov, "~ treated | cole_mcpio_ubicacion")),
        data = bd,
        cluster = ~cole_mcpio_ubicacion
      )
      balance_list[[paste0("b", k, "_", cov)]] <- data.table(
        boundary = paste0(k, "|", k + 1),
        covariate = cov,
        coef = coef(bal_reg)["treated"],
        se = se(bal_reg)["treated"],
        pval = pvalue(bal_reg)["treated"]
      )
    }
  }
}

## -----------------------------------------------------------------------------
## Compile main results table
## -----------------------------------------------------------------------------
main_results <- rbindlist(lapply(results_list, function(r) {
  data.table(
    boundary     = r$boundary,
    n_obs        = r$n_obs,
    n_treated    = r$n_treated,
    n_munis      = r$n_munis,
    coef_main    = coef(r$reg_main)["treated"],
    se_main      = se(r$reg_main)["treated"],
    pval_main    = pvalue(r$reg_main)["treated"],
    coef_ctrl    = coef(r$reg_controls)["treated"],
    se_ctrl      = se(r$reg_controls)["treated"],
    coef_math    = coef(r$reg_math)["treated"],
    se_math      = se(r$reg_math)["treated"],
    coef_reading = coef(r$reg_reading)["treated"],
    se_reading   = se(r$reg_reading)["treated"],
    mean_y       = r$mean_y_control,
    sd_y         = r$sd_y_control
  )
}))

cat("\n=== Main Results: Score Discontinuity at Each Boundary ===\n")
print(main_results)

## Compile balance table
balance_results <- rbindlist(balance_list)
cat("\n=== Covariate Balance at Boundaries ===\n")
print(balance_results)

## -----------------------------------------------------------------------------
## DESIGN 2: School-level analysis (aggregated)
## Strengthens the design by averaging out student heterogeneity
## -----------------------------------------------------------------------------
cat("\n=== School-Level Analysis ===\n")

school_results <- list()
for (k in boundaries) {
  sd <- school_df[modal_estrato %in% c(k, k + 1) & n_students >= 10]
  sd[, treated := as.integer(modal_estrato == k + 1)]

  ## Municipality FE
  valid_munis <- sd[, .(has_both = length(unique(modal_estrato)) == 2),
                     by = municipality][has_both == TRUE, municipality]
  sd <- sd[municipality %in% valid_munis]

  if (nrow(sd) < 20) next

  reg_school <- feols(
    mean_global ~ treated | municipality,
    data = sd,
    cluster = ~municipality
  )

  school_results[[paste0("b", k)]] <- data.table(
    boundary = paste0(k, "|", k + 1),
    n_schools = nrow(sd),
    coef = coef(reg_school)["treated"],
    se = se(reg_school)["treated"],
    pval = pvalue(reg_school)["treated"]
  )
}

school_results_dt <- rbindlist(school_results)
cat("\nSchool-level results:\n")
print(school_results_dt)

## -----------------------------------------------------------------------------
## Write diagnostics.json for validation
## -----------------------------------------------------------------------------
diag <- list(
  n_treated = sum(sapply(results_list, function(r) r$n_treated)),
  n_pre = length(unique(df$year)),  # years as repeated cross-sections
  n_obs = nrow(df)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

## Save results for table generation
saveRDS(results_list, "../data/main_results.rds")
saveRDS(balance_results, "../data/balance_results.rds")
saveRDS(school_results_dt, "../data/school_results.rds")
saveRDS(main_results, "../data/main_results_dt.rds")

cat("\n=== Main analysis complete ===\n")
