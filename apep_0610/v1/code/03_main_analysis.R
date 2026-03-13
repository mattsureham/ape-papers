## 03_main_analysis.R — Callaway-Sant'Anna DiD and event studies
## apep_0610: The Marginal Birth

library(data.table)
library(did)
library(fixest)
library(jsonlite)

panel <- fread("data/analysis_panel.csv")
cat(sprintf("Panel: %d obs, %d states, %d years\n",
            nrow(panel), uniqueN(panel$state_abbr), uniqueN(panel$year)))

# ====================================================================
# Outcome definitions
# ====================================================================
outcomes <- list(
  list(var = "log_births",      label = "Log Total Births"),
  list(var = "unmarried_share", label = "Unmarried Birth Share"),
  list(var = "lbw_share",       label = "Low Birthweight Share"),
  list(var = "preterm_share",   label = "Preterm Birth Share"),
  list(var = "teen_share",      label = "Teen Birth Share")
)

# ====================================================================
# Recode for CS-DiD: states with first_treat > max(year) are never-treated
# in this sample (did package requires observed treatment periods)
# ====================================================================
max_year <- max(panel$year)
panel[, first_treat_cs := as.numeric(first_treat)]
panel[first_treat_cs > max_year, first_treat_cs := 0]
cat(sprintf("CS-DiD coding: %d states treated in sample, %d not-yet-treated recoded as control\n",
            uniqueN(panel[first_treat_cs > 0]$state_abbr),
            uniqueN(panel[first_treat > 0 & first_treat_cs == 0]$state_abbr)))

# ====================================================================
# 1. CALLAWAY-SANT'ANNA (primary estimator)
# ====================================================================
cat("\n=== CALLAWAY-SANT'ANNA DiD ===\n\n")

cs_results <- list()

for (o in outcomes) {
  yvar <- o$var
  cat(sprintf("CS-DiD: %s (%s)\n", yvar, o$label))

  df <- panel[!is.na(get(yvar))]

  tryCatch({
    cs_out <- att_gt(
      yname      = yvar,
      tname      = "year",
      idname     = "state_id",
      gname      = "first_treat_cs",
      data       = as.data.frame(df),
      control_group = "nevertreated",
      anticipation = 0,
      clustervars = "state_id"
    )

    att_overall <- aggte(cs_out, type = "simple")
    cat(sprintf("  ATT = %.4f (SE = %.4f, p = %.3f)\n",
                att_overall$overall.att,
                att_overall$overall.se,
                2 * pnorm(-abs(att_overall$overall.att / att_overall$overall.se))))

    att_dynamic <- aggte(cs_out, type = "dynamic")

    cs_results[[yvar]] <- list(
      cs_out      = cs_out,
      att_overall = att_overall,
      att_dynamic = att_dynamic,
      outcome     = o
    )
  }, error = function(e) {
    cat(sprintf("  ERROR: %s\n", e$message))
  })
}

saveRDS(cs_results, "data/cs_results.rds")

# ====================================================================
# 2. TWFE FIXED EFFECTS (for comparison / robustness)
# ====================================================================
cat("\n=== TWFE FIXED EFFECTS (comparison) ===\n\n")

twfe_results <- list()

for (o in outcomes) {
  yvar <- o$var
  cat(sprintf("TWFE: %s\n", yvar))

  df <- panel[!is.na(get(yvar))]

  fml <- as.formula(paste0(yvar, " ~ treated | state_id + year"))
  fit <- feols(fml, data = df, cluster = ~state_id)

  cat(sprintf("  Coef = %.4f (SE = %.4f, p = %.3f)\n",
              coef(fit)["treated"],
              se(fit)["treated"],
              pvalue(fit)["treated"]))

  twfe_results[[yvar]] <- fit
}

saveRDS(twfe_results, "data/twfe_results.rds")

# ====================================================================
# 3. SUN-ABRAHAM (heterogeneity-robust TWFE)
# ====================================================================
cat("\n=== SUN-ABRAHAM ===\n\n")

sa_results <- list()

for (o in outcomes) {
  yvar <- o$var
  cat(sprintf("Sun-Abraham: %s\n", yvar))

  df <- panel[!is.na(get(yvar))]

  fml <- as.formula(paste0(yvar, " ~ sunab(first_treat, year) | state_id + year"))
  tryCatch({
    fit <- feols(fml, data = df, cluster = ~state_id)
    cat(sprintf("  ATT = %.4f\n", summary(fit, agg = "ATT")$coeftable[1, 1]))
    sa_results[[yvar]] <- fit
  }, error = function(e) {
    cat(sprintf("  ERROR: %s\n", e$message))
  })
}

saveRDS(sa_results, "data/sa_results.rds")

# ====================================================================
# 4. HETEROGENEITY: Total bans vs. Gestational limits
# ====================================================================
cat("\n=== HETEROGENEITY: Ban type ===\n\n")

hetero_results <- list()

for (o in outcomes) {
  yvar <- o$var
  cat(sprintf("Heterogeneity: %s\n", yvar))

  df <- panel[!is.na(get(yvar))]

  # Total bans only
  df_narrow <- df[ban_type %in% c("total_ban", "none")]
  fml <- as.formula(paste0(yvar, " ~ treated | state_id + year"))
  fit_total <- feols(fml, data = df_narrow, cluster = ~state_id)

  # Gestational limits only
  df_gest <- df[ban_type %in% c("gest_limit", "none")]
  df_gest[, treated_gest := as.integer(first_treat > 0 & year >= first_treat)]
  fml_gest <- as.formula(paste0(yvar, " ~ treated_gest | state_id + year"))
  fit_gest <- feols(fml_gest, data = df_gest, cluster = ~state_id)

  hetero_results[[yvar]] <- list(
    total_ban = fit_total,
    gest_limit = fit_gest
  )

  cat(sprintf("  Total ban:    Coef = %.4f (SE = %.4f)\n",
              coef(fit_total)["treated"], se(fit_total)["treated"]))
  cat(sprintf("  Gest. limit:  Coef = %.4f (SE = %.4f)\n",
              coef(fit_gest)["treated_gest"], se(fit_gest)["treated_gest"]))
}

saveRDS(hetero_results, "data/hetero_results.rds")

# ====================================================================
# 5. DIAGNOSTICS (for validate_v1.py)
# ====================================================================
n_treated_states <- uniqueN(panel[first_treat > 0]$state_abbr)
n_pre_years <- length(unique(panel[year < min(panel[first_treat > 0]$first_treat)]$year))

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre     = n_pre_years,
  n_obs     = nrow(panel),
  n_states  = uniqueN(panel$state_abbr),
  years     = sort(unique(panel$year)),
  total_births = sum(panel$total_births)
)

write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("\nDiagnostics written: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_states, n_pre_years, nrow(panel)))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
