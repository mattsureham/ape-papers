## 03_main_analysis.R — Main DiD regressions
## apep_1054: Mexico DST Abolition and Crime

source("00_packages.R")

cat("=== Loading Analysis Panel ===\n")
df <- fread("../data/analysis_panel.csv")
df[, date := as.Date(date)]

cat("Obs:", nrow(df), "| Municipalities:", uniqueN(df$muni_id), "\n")
cat("Border:", uniqueN(df[border == 1]$muni_id),
    "| Non-border:", uniqueN(df[border == 0]$muni_id), "\n")

## ---------------------------------------------------------------
## 1. Main DiD: Total Crime
## ---------------------------------------------------------------
cat("\n=== Main DiD Specification ===\n")
cat("Y = IHS(total_crime) | municipality + state×year-month FE\n")
cat("Treatment: non-border × post-reform\n\n")

## Primary specification: Triple-diff — NonBorder × Post × DSTActive
## This aligns the treatment with the actual institutional mechanism:
## the 1-hour sunset difference only exists during DST-active months (March-October)

m1_total <- feols(ihs_total ~ treat_post_dst + treat_post + treated:dst_active |
                   muni_id + state_ym,
                   data = df, cluster = ~muni_id)

## Street crime (darkness-sensitive) — KEY OUTCOME
m1_street <- feols(ihs_street ~ treat_post_dst + treat_post + treated:dst_active |
                    muni_id + state_ym,
                    data = df, cluster = ~muni_id)

## Property crime (robbery)
m1_property <- feols(ihs_property ~ treat_post_dst + treat_post + treated:dst_active |
                      muni_id + state_ym,
                      data = df, cluster = ~muni_id)

## Violent crime
m1_violent <- feols(ihs_violent ~ treat_post_dst + treat_post + treated:dst_active |
                     muni_id + state_ym,
                     data = df, cluster = ~muni_id)

## White-collar crime (PLACEBO — should be null)
m1_wc <- feols(ihs_whitecollar ~ treat_post_dst + treat_post + treated:dst_active |
                muni_id + state_ym,
                data = df, cluster = ~muni_id)

## Also keep simple DiD for robustness
m1_street_simple <- feols(ihs_street ~ treat_post | muni_id + state_ym,
                           data = df, cluster = ~muni_id)

cat("=== Main Results (Triple-Diff: NonBorder × Post × DSTActive) ===\n")
cat("Total crime:     β =", round(coef(m1_total)["treat_post_dst"], 4),
    " SE =", round(se(m1_total)["treat_post_dst"], 4),
    " p =", round(pvalue(m1_total)["treat_post_dst"], 4), "\n")
cat("Street crime:    β =", round(coef(m1_street)["treat_post_dst"], 4),
    " SE =", round(se(m1_street)["treat_post_dst"], 4),
    " p =", round(pvalue(m1_street)["treat_post_dst"], 4), "\n")
cat("Property crime:  β =", round(coef(m1_property)["treat_post_dst"], 4),
    " SE =", round(se(m1_property)["treat_post_dst"], 4),
    " p =", round(pvalue(m1_property)["treat_post_dst"], 4), "\n")
cat("Violent crime:   β =", round(coef(m1_violent)["treat_post_dst"], 4),
    " SE =", round(se(m1_violent)["treat_post_dst"], 4),
    " p =", round(pvalue(m1_violent)["treat_post_dst"], 4), "\n")
cat("White-collar:    β =", round(coef(m1_wc)["treat_post_dst"], 4),
    " SE =", round(se(m1_wc)["treat_post_dst"], 4),
    " p =", round(pvalue(m1_wc)["treat_post_dst"], 4), " (placebo)\n")

## ---------------------------------------------------------------
## 2. Triple-Difference: DST-Active Months Only
## ---------------------------------------------------------------
cat("\n=== Triple-Difference: DST-Active Months ===\n")
cat("The treatment contrast only exists March-October (DST months)\n")
cat("November-February: both groups on standard time (no contrast)\n\n")

## Restricted to DST-active months
m2_dst <- feols(ihs_street ~ treat_post | muni_id + state_ym,
                 data = df[dst_active == 1], cluster = ~muni_id)

## Restricted to non-DST months (TEMPORAL PLACEBO)
m2_nodst <- feols(ihs_street ~ treat_post | muni_id + state_ym,
                   data = df[dst_active == 0], cluster = ~muni_id)

cat("Street crime (DST months Mar-Oct): β =", round(coef(m2_dst), 4),
    " SE =", round(se(m2_dst), 4),
    " p =", round(pvalue(m2_dst), 4), "\n")
cat("Street crime (non-DST Nov-Feb):    β =", round(coef(m2_nodst), 4),
    " SE =", round(se(m2_nodst), 4),
    " p =", round(pvalue(m2_nodst), 4), " (temporal placebo)\n")

## Full triple-difference
m2_triple <- feols(ihs_street ~ treat_post + treat_post:dst_active +
                    treated:dst_active + post:dst_active |
                    muni_id + state_ym,
                   data = df, cluster = ~muni_id)

cat("Triple-diff (treated×post×DST): β =", round(coef(m2_triple)["treat_post:dst_active"], 4),
    " SE =", round(se(m2_triple)["treat_post:dst_active"], 4), "\n")

## ---------------------------------------------------------------
## 3. Event Study
## ---------------------------------------------------------------
cat("\n=== Event Study ===\n")

## Event study using annual bins for cleaner display
## Create annual relative time (year relative to reform)
df[, reform_year := 2022]
df[, rel_year := year - reform_year]

## Collapse to annual DiD for event study
df_annual <- df[, .(
  ihs_street = mean(ihs_street),
  ihs_total = mean(ihs_total),
  street_crime = mean(street_crime),
  total_crime = mean(total_crime)
), by = .(muni_id, cve_ent, year, rel_year, treated, border)]

df_annual[, state_year := paste0(cve_ent, "_", year)]

## Event study: annual relative time × treated, ref = -1 (2021)
es_street <- feols(ihs_street ~ i(rel_year, treated, ref = -1) |
                    muni_id + state_year,
                   data = df_annual, cluster = ~muni_id)

## Extract coefficients for reporting
es_coefs <- as.data.table(coeftable(es_street), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "t", "p"))
cat("\nEvent study coefficients (annual):\n")
print(es_coefs)

## ---------------------------------------------------------------
## 4. Save results for tables
## ---------------------------------------------------------------
results <- list(
  m1_total = m1_total,
  m1_street = m1_street,
  m1_property = m1_property,
  m1_violent = m1_violent,
  m1_wc = m1_wc,
  m1_street_simple = m1_street_simple,
  m2_dst = m2_dst,
  m2_nodst = m2_nodst,
  m2_triple = m2_triple,
  es_street = es_street
)

saveRDS(results, "../data/main_results.rds")

## ---------------------------------------------------------------
## 5. Diagnostics for validator
## ---------------------------------------------------------------
n_treated <- uniqueN(df[treated == 1]$muni_id)
n_pre <- length(unique(df[post == 0]$ym))
n_obs <- nrow(df)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Diagnostics ===\n")
cat("Treated municipalities:", n_treated, "\n")
cat("Pre-treatment periods:", n_pre, "\n")
cat("Total observations:", n_obs, "\n")
cat("\nResults saved to data/main_results.rds\n")
cat("Diagnostics saved to data/diagnostics.json\n")
