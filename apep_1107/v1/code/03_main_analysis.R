## 03_main_analysis.R — Primary DiD and Event Study
## apep_1107: Romania Overnight Payroll Tax Shift

source("00_packages.R")

core_agg <- readRDS("../data/core_agg.rds")
core_sectors <- readRDS("../data/core_sectors.rds")
full_agg <- readRDS("../data/full_agg.rds")

cat("=== Main Analysis: DiD Estimation ===\n")

## ══════════════════════════════════════════════════════════════════════
## TABLE 1: Summary Statistics — Pre-reform levels (2017-Q4)
## ══════════════════════════════════════════════════════════════════════

pre_stats <- core_agg |>
  filter(time == as.Date("2017-10-01")) |>
  select(country, wages, nonwage, total, nonwage_share) |>
  arrange(country)

cat("\n=== Pre-reform summary (2017-Q4, B-S aggregate) ===\n")
print(pre_stats)

## ══════════════════════════════════════════════════════════════════════
## TABLE 2: DiD — Aggregate CEE sample
## ══════════════════════════════════════════════════════════════════════

cat("\n=== DiD: Wages (D11) — CEE aggregate ===\n")

## Model 1: Simple DiD on log wages
m1_wages <- feols(log_wages ~ treat_post | country + time,
                  data = core_agg,
                  cluster = ~country)

## Model 2: Simple DiD on log non-wage costs
m1_nonwage <- feols(log_nonwage ~ treat_post | country + time,
                    data = core_agg,
                    cluster = ~country)

## Model 3: Simple DiD on non-wage share
m1_share <- feols(nonwage_share ~ treat_post | country + time,
                  data = core_agg,
                  cluster = ~country)

cat("Wages model:\n"); print(summary(m1_wages))
cat("Non-wage model:\n"); print(summary(m1_nonwage))
cat("Share model:\n"); print(summary(m1_share))

## ══════════════════════════════════════════════════════════════════════
## TABLE 3: DiD — Sector-level panel (3-way FE)
## ══════════════════════════════════════════════════════════════════════

cat("\n=== DiD: Sector-level panel (3-way FE) ===\n")

## Model with country x sector + quarter FE
## (country x quarter FE would absorb treat_post since it varies at country-time level)
m2_wages <- feols(log_wages ~ treat_post |
                    country_sector + time,
                  data = core_sectors,
                  cluster = ~country)

m2_nonwage <- feols(log_nonwage ~ treat_post |
                      country_sector + time,
                    data = core_sectors,
                    cluster = ~country)

m2_share <- feols(nonwage_share ~ treat_post |
                    country_sector + time,
                  data = core_sectors,
                  cluster = ~country)

cat("Sector wages:\n"); print(summary(m2_wages))
cat("Sector non-wage:\n"); print(summary(m2_nonwage))
cat("Sector share:\n"); print(summary(m2_share))

## ══════════════════════════════════════════════════════════════════════
## EVENT STUDY — Quarter-by-quarter coefficients
## ══════════════════════════════════════════════════════════════════════

cat("\n=== Event Study ===\n")

## Create event time indicators (omit t = -1 as reference)
core_agg <- core_agg |>
  mutate(event_time_fac = factor(event_time))

## Event study: wages
es_wages <- feols(log_wages ~ i(event_time, treated_country, ref = -1) |
                    country + time,
                  data = core_agg,
                  cluster = ~country)

## Event study: non-wage costs
es_nonwage <- feols(log_nonwage ~ i(event_time, treated_country, ref = -1) |
                      country + time,
                    data = core_agg,
                    cluster = ~country)

## Event study: non-wage share
es_share <- feols(nonwage_share ~ i(event_time, treated_country, ref = -1) |
                    country + time,
                  data = core_agg,
                  cluster = ~country)

cat("Event study wages:\n"); print(summary(es_wages))
cat("Event study non-wage:\n"); print(summary(es_nonwage))

## ═══════════════════════════════════════════════════════��══════════════
## Full EU sample (26 countries)
## ══════════════════════════════════════════════════════════════════════

cat("\n=== Full EU sample ===\n")

m3_wages <- feols(log_wages ~ treat_post | country + time,
                  data = full_agg,
                  cluster = ~country)

m3_nonwage <- feols(log_nonwage ~ treat_post | country + time,
                    data = full_agg,
                    cluster = ~country)

cat("Full EU wages:\n"); print(summary(m3_wages))
cat("Full EU non-wage:\n"); print(summary(m3_nonwage))

## ══════════════════════════════════════════════════════════════════════
## Save results for tables
## ══════════════════════════════════════════════════════���═══════════════

results <- list(
  m1_wages = m1_wages,
  m1_nonwage = m1_nonwage,
  m1_share = m1_share,
  m2_wages = m2_wages,
  m2_nonwage = m2_nonwage,
  m2_share = m2_share,
  m3_wages = m3_wages,
  m3_nonwage = m3_nonwage,
  es_wages = es_wages,
  es_nonwage = es_nonwage,
  es_share = es_share,
  pre_stats = pre_stats
)

saveRDS(results, "../data/main_results.rds")

## ── Write diagnostics.json for validator ─────────────────────────────
n_treated_sectors <- core_sectors |>
  filter(country == "RO") |>
  pull(country_sector) |>
  n_distinct()

n_pre <- core_agg |>
  filter(post == 0) |>
  pull(time) |>
  n_distinct()

diag <- list(
  n_treated = n_treated_sectors,
  n_pre = n_pre,
  n_obs = nrow(core_sectors)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("\n=== Main analysis complete ===\n")
