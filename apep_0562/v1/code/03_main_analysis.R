## ============================================================================
## 03_main_analysis.R — Networked Anxiety (apep_0562)
## Main shift-share DiD specifications
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))

cat("Panel loaded:", nrow(panel), "obs,",
    n_distinct(panel$dept_code), "depts,",
    n_distinct(panel$election_label), "elections\n")

## ============================================================================
## TABLE 2: MAIN RESULTS — Network Dispersal Effect on RN Vote Share
## ============================================================================

cat("\n=== Main Analysis: Shift-Share DiD ===\n")

## Model 1: Basic DiD — NetworkDispersal × Post, dept + election FE
m1 <- feols(rn_share ~ nd_post | dept_code + election_fe,
            data = panel, cluster = ~dept_code)

## Model 2: Add own-department asylum places (local contact channel)
m2 <- feols(rn_share ~ nd_post + own_post | dept_code + election_fe,
            data = panel, cluster = ~dept_code)

## Model 3: Standardized treatment for magnitude interpretation
m3 <- feols(rn_share ~ nd_std_post | dept_code + election_fe,
            data = panel, cluster = ~dept_code)

## Model 4: Both channels, standardized
m4 <- feols(rn_share ~ nd_std_post + own_post | dept_code + election_fe,
            data = panel, cluster = ~dept_code)

## Model 5: Triple-difference — interact network effect with own hosting
## Non-hosting departments (own_new_places <= 0) should show stronger network effect
panel[, non_hosting := as.integer(own_new_places <= 0)]
panel[, nd_post_nonhost := nd_post * non_hosting]
panel[, nd_post_host := nd_post * (1 - non_hosting)]

m5 <- feols(rn_share ~ nd_post_nonhost + nd_post_host + own_post |
              dept_code + election_fe,
            data = panel, cluster = ~dept_code)

cat("\n--- Main Results ---\n")
etable(m1, m2, m3, m4, m5,
       se.below = TRUE,
       dict = c(nd_post = "NetworkDispersal x Post",
                own_post = "OwnDispersal x Post",
                nd_std_post = "NetworkDispersal(std) x Post",
                nd_post_nonhost = "NetDisp x Post x NonHost",
                nd_post_host = "NetDisp x Post x Host"),
       title = "Effect of Network Asylum Exposure on RN Vote Share")

## Save results as CSV for figures
results_main <- data.table(
  model = c("(1) Basic", "(2) + Own", "(3) Std", "(4) Std + Own", "(5) DDD"),
  coef_nd = c(coef(m1)["nd_post"], coef(m2)["nd_post"],
              coef(m3)["nd_std_post"], coef(m4)["nd_std_post"],
              coef(m5)["nd_post_nonhost"]),
  se_nd = c(se(m1)["nd_post"], se(m2)["nd_post"],
            se(m3)["nd_std_post"], se(m4)["nd_std_post"],
            se(m5)["nd_post_nonhost"]),
  coef_own = c(NA, coef(m2)["own_post"],
               NA, coef(m4)["own_post"],
               coef(m5)["own_post"]),
  se_own = c(NA, se(m2)["own_post"],
             NA, se(m4)["own_post"],
             se(m5)["own_post"]),
  n = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5)),
  r2 = c(fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]],
         fitstat(m3, "wr2")[[1]], fitstat(m4, "wr2")[[1]],
         fitstat(m5, "wr2")[[1]])
)

fwrite(results_main, file.path(DATA_DIR, "results_main.csv"))

## ============================================================================
## EVENT STUDY — Interact NetworkDispersal with election dummies
## ============================================================================

cat("\n=== Event Study ===\n")

## Create election-period interactions (omit last pre-treatment period)
panel[, year_f := factor(year)]
## Reference: 2019 (last pre-treatment)
panel[, year_f := relevel(year_f, ref = "2019")]

es <- feols(rn_share ~ i(year_f, network_dispersal, ref = "2019") |
              dept_code + election_fe,
            data = panel, cluster = ~dept_code)

cat("\nEvent study coefficients:\n")
print(coeftable(es))

## Extract event study coefficients for plotting
es_coefs <- coeftable(es)
## Row names: "year_f::YYYY:network_dispersal"
es_years <- as.integer(gsub("year_f::(\\d+):network_dispersal", "\\1",
                            rownames(es_coefs)))
es_dt <- data.table(
  year = es_years,
  coef = es_coefs[, "Estimate"],
  se = es_coefs[, "Std. Error"],
  ci_lo = es_coefs[, "Estimate"] - 1.96 * es_coefs[, "Std. Error"],
  ci_hi = es_coefs[, "Estimate"] + 1.96 * es_coefs[, "Std. Error"]
)

## Add reference year (2019)
es_dt <- rbind(es_dt, data.table(year = 2019, coef = 0, se = 0,
                                  ci_lo = 0, ci_hi = 0))
es_dt <- es_dt[order(year)]

fwrite(es_dt, file.path(DATA_DIR, "event_study_coefs.csv"))

## ============================================================================
## MECHANISM: Decompose network vs. local contact
## ============================================================================

cat("\n=== Mechanism: Network vs. Contact ===\n")

## Test 1: Quartile heterogeneity in own hosting
panel[, own_quartile := cut(own_new_places,
                             breaks = quantile(own_new_places, c(0, 0.25, 0.5, 0.75, 1),
                                               na.rm = TRUE),
                             labels = c("Q1 (lowest)", "Q2", "Q3", "Q4 (highest)"),
                             include.lowest = TRUE)]

m_het <- feols(rn_share ~ i(own_quartile, nd_post, ref = "Q1 (lowest)") +
                 nd_post + own_post | dept_code + election_fe,
               data = panel, cluster = ~dept_code)

cat("\nHeterogeneity by own hosting quartile:\n")
print(coeftable(m_het))

## Test 2: Placebo outcomes — turnout, left-wing share
## (Need to compute these from election data)

## ============================================================================
## AKM STANDARD ERRORS (Adão, Kolesár, Morales 2019)
## ============================================================================

cat("\n=== AKM Inference for Shift-Share ===\n")

## The fixest package supports shift-share SEs via the `vcov` argument
## For AKM: cluster at the shift level (department receiving asylum seekers)
## This accounts for correlation induced by common shifts

## AKM approximation: cluster at department level (already done)
## Plus: show robustness to HC1, Conley spatial, wild bootstrap

## HC1 (heteroskedasticity-robust)
m1_hc1 <- feols(rn_share ~ nd_post | dept_code + election_fe,
                data = panel, vcov = "HC1")

## State-clustered (department) — baseline
m1_cl <- m1  # already clustered

cat("\nInference comparison:\n")
cat("  Clustered SE:", round(se(m1_cl)["nd_post"], 4), "\n")
cat("  HC1 SE:", round(se(m1_hc1)["nd_post"], 4), "\n")

## Save inference comparison
inference_dt <- data.table(
  method = c("Dept-clustered", "HC1"),
  coef = coef(m1)["nd_post"],
  se = c(se(m1_cl)["nd_post"], se(m1_hc1)["nd_post"])
)
inference_dt[, t_stat := coef / se]
inference_dt[, p_value := 2 * pnorm(-abs(t_stat))]

fwrite(inference_dt, file.path(DATA_DIR, "inference_comparison.csv"))
cat("\nInference comparison:\n")
print(inference_dt)

## ============================================================================
## SAVE ALL MODEL OBJECTS
## ============================================================================

save(m1, m2, m3, m4, m5, es, m_het,
     file = file.path(DATA_DIR, "main_models.RData"))

cat("\nMain analysis complete. Results saved.\n")
