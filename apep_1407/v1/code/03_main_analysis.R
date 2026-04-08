## 03_main_analysis.R — Main DiD regressions
## apep_1407: The Insurance Denominator

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(file.path(data_dir, "fema_analysis.rds"))
cat(sprintf("Analysis dataset: %s obs\n", format(nrow(df), big.mark = ",")))

## ============================================================
## A. First Stage: Premium Impact of RR2.0 on Grandfathered
## ============================================================

## Basic DiD
m1_prem <- feols(log_premium_w ~ grandfathered:post_rr2 | county_fe + yq,
                 data = df, cluster = ~county_fe)

## With controls
m2_prem <- feols(log_premium_w ~ grandfathered:post_rr2 + mandatory + primary_res |
                   county_fe + yq,
                 data = df, cluster = ~county_fe)

## With flood zone FE
m3_prem <- feols(log_premium_w ~ grandfathered:post_rr2 + mandatory + primary_res |
                   county_fe + yq + floodZoneCurrent,
                 data = df, cluster = ~county_fe)

cat("\n=== First Stage: Log Premium ===\n")
etable(m1_prem, m2_prem, m3_prem)

## ============================================================
## B. Main Outcome: Policy Lapse
## ============================================================

m1_lapse <- feols(lapsed ~ grandfathered:post_rr2 | county_fe + yq,
                  data = df, cluster = ~county_fe)

m2_lapse <- feols(lapsed ~ grandfathered:post_rr2 + mandatory + primary_res |
                    county_fe + yq,
                  data = df, cluster = ~county_fe)

m3_lapse <- feols(lapsed ~ grandfathered:post_rr2 + mandatory + primary_res |
                    county_fe + yq + floodZoneCurrent,
                  data = df, cluster = ~county_fe)

cat("\n=== Main Outcome: Lapse ===\n")
etable(m1_lapse, m2_lapse, m3_lapse)

## ============================================================
## C. Coverage Adequacy
## ============================================================

df_cov <- df |> filter(!is.na(coverage_ratio), coverage_ratio > 0, coverage_ratio < 5)

m1_cov <- feols(coverage_ratio ~ grandfathered:post_rr2 | county_fe + yq,
                data = df_cov, cluster = ~county_fe)

m2_cov <- feols(coverage_ratio ~ grandfathered:post_rr2 + mandatory + primary_res |
                  county_fe + yq + floodZoneCurrent,
                data = df_cov, cluster = ~county_fe)

cat("\n=== Coverage Ratio ===\n")
etable(m1_cov, m2_cov)

## ============================================================
## D. Event Study
## ============================================================

## Create event-time dummies (relative to 2021Q4)
## Bin endpoints: ≤-8 and ≥+8
df <- df |>
  mutate(event_q_binned = pmax(pmin(event_q, 8), -8))

## Use -2 as reference (last available pre-treatment quarter: 2021Q2)
ref_q <- -2

m_es_prem <- feols(log_premium_w ~ i(event_q_binned, grandfathered, ref = ref_q) |
                     county_fe + yq,
                   data = df, cluster = ~county_fe)

m_es_lapse <- feols(lapsed ~ i(event_q_binned, grandfathered, ref = ref_q) |
                      county_fe + yq,
                    data = df, cluster = ~county_fe)

cat("\n=== Event Study: Premium ===\n")
summary(m_es_prem)

cat("\n=== Event Study: Lapse ===\n")
summary(m_es_lapse)

## ============================================================
## E. Heterogeneity: Mandatory vs Voluntary
## ============================================================

m_het_mand <- feols(lapsed ~ grandfathered:post_rr2 | county_fe + yq,
                    data = df |> filter(mandatory == 1), cluster = ~county_fe)

m_het_vol <- feols(lapsed ~ grandfathered:post_rr2 | county_fe + yq,
                   data = df |> filter(mandatory == 0), cluster = ~county_fe)

cat("\n=== Heterogeneity: Mandatory ===\n")
etable(m_het_mand, m_het_vol)

## Heterogeneity: Primary residence vs investment
m_het_prim <- feols(lapsed ~ grandfathered:post_rr2 | county_fe + yq,
                    data = df |> filter(primary_res == 1), cluster = ~county_fe)

m_het_inv <- feols(lapsed ~ grandfathered:post_rr2 | county_fe + yq,
                   data = df |> filter(primary_res == 0), cluster = ~county_fe)

cat("\n=== Heterogeneity: Primary Residence ===\n")
etable(m_het_prim, m_het_inv)

## ============================================================
## F. Save model objects and diagnostics
## ============================================================

models <- list(
  first_stage = list(m1 = m1_prem, m2 = m2_prem, m3 = m3_prem),
  lapse = list(m1 = m1_lapse, m2 = m2_lapse, m3 = m3_lapse),
  coverage = list(m1 = m1_cov, m2 = m2_cov),
  event_study = list(premium = m_es_prem, lapse = m_es_lapse),
  heterogeneity = list(mand = m_het_mand, vol = m_het_vol,
                       prim = m_het_prim, inv = m_het_inv)
)

saveRDS(models, file.path(data_dir, "model_objects.rds"))

## Write diagnostics.json for validator
n_treated <- n_distinct(df$county_fe[df$grandfathered == 1])
n_pre <- length(unique(df$yq[df$post_rr2 == 0]))
n_obs <- nrow(df)

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
), file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat(sprintf("\n=== Diagnostics: n_treated=%d, n_pre=%d, n_obs=%s ===\n",
            n_treated, n_pre, format(n_obs, big.mark = ",")))
cat("=== Main analysis complete ===\n")
