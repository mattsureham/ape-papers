## 03_main_analysis.R — Main examiner IV regressions
## APEP Paper apep_0829: The Goldilocks Examiner
##
## Design: LOO examiner average claims (within Art Unit × Year)
##         as instrument for patent scope (num_claims)
##         → forward citations (follow-on innovation)

source("00_packages.R")

df <- readRDS("../data/analysis_clean.rds")
cat(sprintf("Loaded %s patents\n", format(nrow(df), big.mark = ",")))

## ====================================================================
## TABLE 2: First Stage — LOO examiner claims → own num_claims
## ====================================================================
cat("\n=== FIRST STAGE ===\n")

## Column 1: Art Unit × Year FE (main spec)
fs1 <- feols(num_claims_w ~ loo_examiner_claims_w | art_unit_year,
             data = df, cluster = ~examiner_id)

cat("First stage results:\n")
etable(fs1)

## Report F-statistic (t^2 for single instrument)
fs1_t <- coef(fs1)["loo_examiner_claims_w"] / se(fs1)["loo_examiner_claims_w"]
fs1_fstat <- fs1_t^2
cat(sprintf("\nFirst-stage F-stat: %.1f\n", fs1_fstat))

## ====================================================================
## TABLE 3: Reduced Form — LOO examiner claims → forward citations
## ====================================================================
cat("\n=== REDUCED FORM (Main Results) ===\n")

rf_total <- feols(ln_total_cites ~ loo_examiner_claims_w | art_unit_year,
                  data = df, cluster = ~examiner_id)

rf_other <- feols(ln_other_cites ~ loo_examiner_claims_w | art_unit_year,
                  data = df, cluster = ~examiner_id)

rf_self <- feols(ln_self_cites ~ loo_examiner_claims_w | art_unit_year,
                 data = df, cluster = ~examiner_id)

rf_any <- feols(has_citation ~ loo_examiner_claims_w | art_unit_year,
                data = df, cluster = ~examiner_id)

rf_any_other <- feols(has_other_citation ~ loo_examiner_claims_w | art_unit_year,
                      data = df, cluster = ~examiner_id)

cat("Reduced form results:\n")
etable(rf_total, rf_other, rf_self, rf_any, rf_any_other,
       se = "cluster",
       headers = c("ln(Total)", "ln(Other)", "ln(Self)", "Any Cite", "Any Other"))

## ====================================================================
## TABLE: 2SLS IV Estimates
## ====================================================================
cat("\n=== 2SLS IV ESTIMATES ===\n")

iv_total <- feols(ln_total_cites ~ 1 | art_unit_year |
                    num_claims_w ~ loo_examiner_claims_w,
                  data = df, cluster = ~examiner_id)

iv_other <- feols(ln_other_cites ~ 1 | art_unit_year |
                    num_claims_w ~ loo_examiner_claims_w,
                  data = df, cluster = ~examiner_id)

iv_self <- feols(ln_self_cites ~ 1 | art_unit_year |
                   num_claims_w ~ loo_examiner_claims_w,
                 data = df, cluster = ~examiner_id)

cat("2SLS results:\n")
etable(iv_total, iv_other, iv_self,
       se = "cluster",
       headers = c("ln(Total)", "ln(Other)", "ln(Self)"))

## ====================================================================
## Save results
## ====================================================================
results <- list(
  n_patents = nrow(df),
  n_examiners = uniqueN(df$examiner_id),
  n_cells = uniqueN(df$art_unit_year),
  n_examiner_cells = uniqueN(df[, .(examiner_id, art_unit_year)]),
  fs_coef = coef(fs1)["loo_examiner_claims_w"],
  fs_se = se(fs1)["loo_examiner_claims_w"],
  fs_fstat = fs1_fstat,
  rf_total_coef = coef(rf_total)["loo_examiner_claims_w"],
  rf_total_se = se(rf_total)["loo_examiner_claims_w"],
  rf_other_coef = coef(rf_other)["loo_examiner_claims_w"],
  rf_other_se = se(rf_other)["loo_examiner_claims_w"],
  rf_self_coef = coef(rf_self)["loo_examiner_claims_w"],
  rf_self_se = se(rf_self)["loo_examiner_claims_w"],
  rf_any_coef = coef(rf_any)["loo_examiner_claims_w"],
  rf_any_se = se(rf_any)["loo_examiner_claims_w"],
  iv_total_coef = coef(iv_total)["fit_num_claims_w"],
  iv_total_se = se(iv_total)["fit_num_claims_w"],
  iv_other_coef = coef(iv_other)["fit_num_claims_w"],
  iv_other_se = se(iv_other)["fit_num_claims_w"],
  mean_claims = mean(df$num_claims),
  sd_claims = sd(df$num_claims),
  mean_total_cites = mean(df$total_forward_cites_5yr),
  sd_total_cites = sd(df$total_forward_cites_5yr),
  mean_other_cites = mean(df$other_forward_cites_5yr),
  sd_other_cites = sd(df$other_forward_cites_5yr),
  p10_loo = quantile(df$loo_examiner_claims, 0.10),
  p90_loo = quantile(df$loo_examiner_claims, 0.90),
  sd_loo = sd(df$loo_examiner_claims_w),
  sd_ln_total = sd(df$ln_total_cites),
  sd_ln_other = sd(df$ln_other_cites),
  sd_ln_self = sd(df$ln_self_cites),
  sd_has_citation = sd(df$has_citation)
)

saveRDS(results, "../data/main_results.rds")

## ---- Diagnostics for validate_v1.py ----
diag <- list(
  n_treated = uniqueN(df$examiner_id),
  n_pre = length(unique(df$filing_year)),
  n_obs = nrow(df)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nSaved data/main_results.rds and data/diagnostics.json\n")
