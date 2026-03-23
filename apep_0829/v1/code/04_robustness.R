## 04_robustness.R — Robustness checks and mechanism tests
## APEP Paper apep_0829: The Goldilocks Examiner

source("00_packages.R")

winsorize <- function(x, probs = c(0.01, 0.99)) {
  q <- quantile(x, probs, na.rm = TRUE)
  pmax(pmin(x, q[2]), q[1])
}

df <- as.data.table(readRDS("../data/analysis_clean.rds"))
cat(sprintf("Loaded %s patents\n", format(nrow(df), big.mark = ",")))

## ====================================================================
## BALANCE TESTS — LOO examiner claims should not predict
## pre-determined (at-filing) characteristics
## ====================================================================
cat("\n=== BALANCE TESTS ===\n")

## Grant lag (time from filing to grant) — examiners who allow more claims may process faster/slower
df[, grant_lag := as.numeric(patent_date - filing_date) / 365.25]
bal_lag <- feols(grant_lag ~ loo_examiner_claims_w | art_unit_year,
                 data = df, cluster = ~examiner_id)

## Number of USPC subclasses — a proxy for patent complexity, should be pre-determined
bal_uspc <- feols(I(nchar(uspc_mainclass_id)) ~ loo_examiner_claims_w | art_unit_year,
                  data = df, cluster = ~examiner_id)

cat("Balance tests:\n")
etable(bal_lag, bal_uspc, se = "cluster",
       headers = c("Grant Lag (years)", "USPC Class Length"))

## ====================================================================
## ALTERNATIVE CELL DEFINITIONS
## ====================================================================
cat("\n=== ALTERNATIVE CELLS ===\n")

## Broader: USPC class only (no year interaction)
rf_broad <- feols(ln_other_cites ~ loo_examiner_claims_w | uspc_mainclass_id,
                  data = df, cluster = ~examiner_id)

## Narrower: Art group × year
df[, artgroup_year := paste0(art_group, "_", filing_year)]
## Recompute LOO for this cell
df[, ag_n := .N, by = .(examiner_id, artgroup_year)]
df[, ag_sum := sum(num_claims), by = .(examiner_id, artgroup_year)]
df[, loo_ag := (ag_sum - num_claims) / pmax(ag_n - 1, 1)]
df_ag <- df[ag_n >= 10]
df_ag[, loo_ag_w := winsorize(loo_ag)]

rf_narrow <- feols(ln_other_cites ~ loo_ag_w | artgroup_year,
                   data = df_ag, cluster = ~examiner_id)

cat("Alternative cells:\n")
etable(rf_broad, rf_narrow, se = "cluster",
       headers = c("Broad (Class only)", "Narrow (ArtGroup×Year)"))

## ====================================================================
## HETEROGENEITY: Technology crowdedness
## ====================================================================
cat("\n=== HETEROGENEITY: Technology Crowdedness ===\n")

class_density <- df[, .(class_patents = .N), by = uspc_mainclass_id]
med_density <- median(class_density$class_patents)
df <- merge(df, class_density, by = "uspc_mainclass_id")
df[, crowded := class_patents > med_density]

rf_crowded <- feols(ln_other_cites ~ loo_examiner_claims_w | art_unit_year,
                    data = df[crowded == TRUE], cluster = ~examiner_id)
rf_uncrowded <- feols(ln_other_cites ~ loo_examiner_claims_w | art_unit_year,
                      data = df[crowded == FALSE], cluster = ~examiner_id)

cat("Crowded vs uncrowded:\n")
etable(rf_crowded, rf_uncrowded, se = "cluster",
       headers = c("Crowded", "Uncrowded"))

## ====================================================================
## HETEROGENEITY: Filing year cohorts
## ====================================================================
cat("\n=== HETEROGENEITY: Early vs Late Cohorts ===\n")

rf_early <- feols(ln_other_cites ~ loo_examiner_claims_w | art_unit_year,
                  data = df[filing_year <= 2010], cluster = ~examiner_id)
rf_late <- feols(ln_other_cites ~ loo_examiner_claims_w | art_unit_year,
                 data = df[filing_year > 2010], cluster = ~examiner_id)

cat("Early (2005-2010) vs Late (2011-2015):\n")
etable(rf_early, rf_late, se = "cluster",
       headers = c("2005-2010", "2011-2015"))

## ====================================================================
## Save
## ====================================================================
rob_results <- list(
  bal_lag_coef = coef(bal_lag)["loo_examiner_claims_w"],
  bal_lag_pval = pvalue(bal_lag)["loo_examiner_claims_w"],
  rf_crowded_coef = coef(rf_crowded)["loo_examiner_claims_w"],
  rf_crowded_se = se(rf_crowded)["loo_examiner_claims_w"],
  rf_uncrowded_coef = coef(rf_uncrowded)["loo_examiner_claims_w"],
  rf_uncrowded_se = se(rf_uncrowded)["loo_examiner_claims_w"]
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nSaved data/robustness_results.rds\n")
