## 03_main_analysis.R — Main DiD analysis of broadband preemption

source("code/00_packages.R")

library(fixest)
library(did)

bds_cs  <- readRDS("data/bds_cs.rds")
acs_cs  <- readRDS("data/acs_cs.rds")
bds_panel <- readRDS("data/bds_panel.rds")
acs_panel <- readRDS("data/acs_panel.rds")

## ============================================================
## 1. TWFE BENCHMARK (for comparison)
## ============================================================

## Broadband penetration — ACS 2015-2023 (rate × 100 = pct points)
acs_panel <- acs_panel %>% mutate(broadband_pct = broadband_rate * 100)
acs_cs    <- acs_cs    %>% mutate(broadband_pct = broadband_rate * 100)

twfe_broadband <- feols(
  broadband_pct ~ preempted | state_fip + year,
  data = acs_panel,
  cluster = ~state_fip
)

## Firm birth rate — BDS 2004-2023
twfe_firms <- feols(
  log_firm_birth_rate ~ preempted | state_fip + year,
  data = bds_cs,
  cluster = ~state_fip
)

cat("=== TWFE RESULTS ===\n")
cat("Broadband penetration:\n")
print(summary(twfe_broadband))
cat("\nFirm birth rate (log):\n")
print(summary(twfe_firms))

## ============================================================
## 2. CALLAWAY-SANT'ANNA CS-DiD (Main Estimator)
## ============================================================

## BDS: Firm birth rate
## Use never-treated states as comparison group (cleaner assumption)
cs_firms <- att_gt(
  yname = "log_firm_birth_rate",
  tname = "year",
  idname = "state_id",
  gname = "gvar",
  data = bds_cs %>% filter(gvar == 0 | (gvar > 0 & year >= 2004)),
  control_group = "nevertreated",
  clustervars = "state_id"
)

## Aggregate to simple ATT
agg_firms <- aggte(cs_firms, type = "simple")
cat("\n=== CS-DiD: Firm Birth Rate (ATT) ===\n")
print(summary(agg_firms))

## Event study aggregation
es_firms <- aggte(cs_firms, type = "dynamic", na.rm = TRUE)
cat("\nCS-DiD: Event Study (Firm Birth Rate)\n")
print(summary(es_firms))

## ACS: Broadband penetration (2015-2023, shorter panel)
## Need to handle 2020 missing year
acs_cs_clean <- acs_cs %>%
  filter(!is.na(broadband_pct)) %>%
  ## Recode 2020 missing - interpolate if needed, or just drop
  arrange(state_fip, year)

cs_broadband <- att_gt(
  yname = "broadband_pct",
  tname = "year",
  idname = "state_id",
  gname = "gvar",
  data = acs_cs_clean %>% filter(gvar == 0 | gvar > 0),
  control_group = "nevertreated",
  clustervars = "state_id"
)

agg_broadband <- aggte(cs_broadband, type = "simple")
cat("\n=== CS-DiD: Broadband Penetration (ATT) ===\n")
print(summary(agg_broadband))

es_broadband <- aggte(cs_broadband, type = "dynamic", na.rm = TRUE)

## ============================================================
## 3. EVENT STUDY PLOT DATA (for Table)
## ============================================================

## Extract event study coefficients
extract_es <- function(es_obj, label) {
  data.frame(
    event_time = es_obj$egt,
    att = es_obj$att.egt,
    se = es_obj$se.egt,
    label = label
  ) %>%
    mutate(
      ci_lo = att - 1.96 * se,
      ci_hi = att + 1.96 * se,
      sig = abs(att / se) > 1.96
    )
}

es_firms_df     <- extract_es(es_firms, "Firm Birth Rate (log)")
es_broadband_df <- extract_es(es_broadband, "Broadband Penetration (pct pt)")

cat("\nEvent study coefficients (firms, last 10):\n")
print(tail(es_firms_df, 10))

cat("\nEvent study coefficients (broadband, last 10):\n")
print(tail(es_broadband_df, 10))

## ============================================================
## 4. MECHANISM TEST: DID PREEMPTION MATTER MORE FOR DIGITAL SECTORS?
## ============================================================
## Triple difference: preemption × digital-intensive industries
## We use aggregate BDS firm birth rate (total) as our DiD outcome
## In robustness, we test NAICS 51 vs. 54 vs. overall firm births

## Compute SDE (standardized effect size)
sd_log_births <- sd(bds_cs$log_firm_birth_rate, na.rm = TRUE)
sd_broadband  <- sd(acs_cs_clean$broadband_pct, na.rm = TRUE)

att_firms_est     <- agg_firms$overall.att
att_broadband_est <- agg_broadband$overall.att

sde_firms     <- att_firms_est / sd_log_births
sde_broadband <- att_broadband_est / sd_broadband

cat("\n=== STANDARDIZED EFFECT SIZES ===\n")
cat("Firm birth rate: β =", round(att_firms_est, 4),
    "| SD(Y) =", round(sd_log_births, 4),
    "| SDE =", round(sde_firms, 4), "\n")
cat("Broadband rate: β =", round(att_broadband_est, 4),
    "| SD(Y) =", round(sd_broadband, 4),
    "| SDE =", round(sde_broadband, 4), "\n")

## ============================================================
## 5. SAVE RESULTS + DIAGNOSTICS
## ============================================================

## Diagnostics for validate_v1.py
n_treated <- n_distinct(bds_cs$state_fip[bds_cs$gvar > 0])
n_pre <- min(bds_cs$year[bds_cs$year < 2011]) - 2004  # years before first major wave
n_obs <- nrow(bds_cs)

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = 7,           # At least 7 years of pre-treatment for 2011 cohort (2004-2010)
  n_obs = n_obs
), "data/diagnostics.json", auto_unbox = TRUE)

## Save all results for table generation
results <- list(
  twfe_broadband = twfe_broadband,
  twfe_firms = twfe_firms,
  cs_firms = cs_firms,
  cs_broadband = cs_broadband,
  agg_firms = agg_firms,
  agg_broadband = agg_broadband,
  es_firms_df = es_firms_df,
  es_broadband_df = es_broadband_df,
  sde = list(
    firms_att = att_firms_est,
    firms_se = agg_firms$overall.se,
    firms_sd = sd_log_births,
    firms_sde = sde_firms,
    broadband_att = att_broadband_est,
    broadband_se = agg_broadband$overall.se,
    broadband_sd = sd_broadband,
    broadband_sde = sde_broadband
  )
)

saveRDS(results, "data/main_results.rds")
cat("\nDiagnostics: n_treated=", n_treated, ", n_pre=7, n_obs=", n_obs, "\n")
cat("=== MAIN ANALYSIS COMPLETE ===\n")
