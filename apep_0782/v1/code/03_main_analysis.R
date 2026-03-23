## 03_main_analysis.R — Main DiD and event study regressions
## APEP paper apep_0782: MSHA 2007 Penalty Reform

library(data.table)
library(fixest)
library(jsonlite)

cat("=== 03_main_analysis.R: Main analysis ===\n")

data_dir <- here::here("output", "apep_0782", "v1", "data")
panel <- readRDS(file.path(data_dir, "panel.rds"))

## --- Ensure clean data ---
panel <- panel[!is.na(treat_intensity) & !is.na(injury_rate)]
cat(sprintf("Panel: %s obs, %s mines\n",
            format(nrow(panel), big.mark = ","),
            format(uniqueN(panel$MINE_ID), big.mark = ",")))

## --- Standardize treatment for interpretability ---
# treat_intensity = mean pre-reform S&S penalty / 100
# So a 1-unit increase = $100 more in mean pre-reform S&S penalty
# Also create z-scored version
panel[, treat_z := (treat_intensity - mean(treat_intensity)) / sd(treat_intensity)]

## ===========================================================================
## 1. Main DiD specification
## ===========================================================================
cat("\n--- Main DiD ---\n")

# Spec 1: No fixed effects (baseline)
m1 <- feols(injury_rate ~ treat_intensity * post,
            data = panel, cluster = ~MINE_ID)

# Spec 2: Mine + quarter FE
m2 <- feols(injury_rate ~ treat_intensity:post | MINE_ID + yq,
            data = panel, cluster = ~MINE_ID)

# Spec 3: Mine + state-quarter FE (absorbs state-specific shocks)
panel[, state_yq := paste0(state, "_", yq)]
m3 <- feols(injury_rate ~ treat_intensity:post | MINE_ID + state_yq,
            data = panel, cluster = ~MINE_ID)

# Spec 4: Mine + mine-type x quarter FE
panel[, type_yq := paste0(mine_type, "_", yq)]
m4 <- feols(injury_rate ~ treat_intensity:post | MINE_ID + type_yq,
            data = panel, cluster = ~MINE_ID)

# Spec 5: Serious injuries only
m5 <- feols(serious_rate ~ treat_intensity:post | MINE_ID + yq,
            data = panel, cluster = ~MINE_ID)

# Spec 6: Days lost rate
m6 <- feols(days_lost_rate ~ treat_intensity:post | MINE_ID + yq,
            data = panel, cluster = ~MINE_ID)

cat("\n--- Main results ---\n")
cat(sprintf("Spec 1 (OLS):       coef=%.4f, se=%.4f, p=%.4f\n",
            coef(m1)["treat_intensity:post"], se(m1)["treat_intensity:post"],
            fixest::pvalue(m1)["treat_intensity:post"]))
cat(sprintf("Spec 2 (Mine+Q FE): coef=%.4f, se=%.4f, p=%.4f\n",
            coef(m2)["treat_intensity:post"], se(m2)["treat_intensity:post"],
            fixest::pvalue(m2)["treat_intensity:post"]))
cat(sprintf("Spec 3 (Mine+SQ):   coef=%.4f, se=%.4f, p=%.4f\n",
            coef(m3)["treat_intensity:post"], se(m3)["treat_intensity:post"],
            fixest::pvalue(m3)["treat_intensity:post"]))
cat(sprintf("Spec 4 (Mine+TQ):   coef=%.4f, se=%.4f, p=%.4f\n",
            coef(m4)["treat_intensity:post"], se(m4)["treat_intensity:post"],
            fixest::pvalue(m4)["treat_intensity:post"]))
cat(sprintf("Spec 5 (Serious):   coef=%.4f, se=%.4f, p=%.4f\n",
            coef(m5)["treat_intensity:post"], se(m5)["treat_intensity:post"],
            fixest::pvalue(m5)["treat_intensity:post"]))
cat(sprintf("Spec 6 (Days lost): coef=%.4f, se=%.4f, p=%.4f\n",
            coef(m6)["treat_intensity:post"], se(m6)["treat_intensity:post"],
            fixest::pvalue(m6)["treat_intensity:post"]))

## ===========================================================================
## 2. Event study
## ===========================================================================
cat("\n--- Event Study ---\n")

# Year indicators (reference = 2006)
panel[, year := as.factor(CAL_YR)]
panel[, year := relevel(year, ref = "2006")]

es1 <- feols(injury_rate ~ i(CAL_YR, treat_intensity, ref = 2006) | MINE_ID + yq,
             data = panel, cluster = ~MINE_ID)

cat("Event study coefficients:\n")
es_coefs <- coeftable(es1)
print(es_coefs)

## ===========================================================================
## 3. Save results and diagnostics
## ===========================================================================

# Save model objects
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6, es1 = es1),
        file.path(data_dir, "main_models.rds"))

# Diagnostics JSON
diagnostics <- list(
  n_obs           = nrow(panel),
  n_mines         = uniqueN(panel$MINE_ID),
  n_states        = uniqueN(panel$state),
  n_quarters      = uniqueN(panel$yq),
  mean_injury_rate = mean(panel$injury_rate),
  sd_injury_rate  = sd(panel$injury_rate),
  mean_treat      = mean(panel$treat_intensity),
  sd_treat        = sd(panel$treat_intensity),
  main_coef       = as.numeric(coef(m2)["treat_intensity:post"]),
  main_se         = as.numeric(se(m2)["treat_intensity:post"]),
  main_pvalue     = as.numeric(fixest::pvalue(m2)["treat_intensity:post"]),
  main_nobs       = m2$nobs,
  serious_coef    = as.numeric(coef(m5)["treat_intensity:post"]),
  serious_se      = as.numeric(se(m5)["treat_intensity:post"]),
  serious_pvalue  = as.numeric(fixest::pvalue(m5)["treat_intensity:post"])
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics written to diagnostics.json\n")

cat("=== 03_main_analysis.R: DONE ===\n")
