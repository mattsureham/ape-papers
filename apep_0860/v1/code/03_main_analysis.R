# 03_main_analysis.R — Main DiD regressions

library(tidyverse)
library(fixest)
library(did)
library(jsonlite)

data_dir <- file.path(dirname(getwd()), "data")
load(file.path(data_dir, "analysis_panel.RData"))

# ============================================================
# 1. TWFE baseline (for comparison only — will show CS-DiD is primary)
# ============================================================
twfe_estab <- feols(log_estab ~ post | state_fips + year,
                    data = panel,
                    cluster = ~state_fips)

twfe_emp <- feols(log_emp ~ post | state_fips + year,
                  data = panel,
                  cluster = ~state_fips)

cat("=== TWFE Results ===\n")
cat("Log establishments:", round(coef(twfe_estab)["post"], 4),
    "(SE:", round(se(twfe_estab)["post"], 4), ")\n")
cat("Log employment:", round(coef(twfe_emp)["post"], 4),
    "(SE:", round(se(twfe_emp)["post"], 4), ")\n")

# ============================================================
# 2. Callaway-Sant'Anna (primary specification)
# ============================================================

# CS-DiD for establishments
cs_estab <- att_gt(
  yname = "log_estab",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

# Aggregate: simple ATT
agg_estab <- aggte(cs_estab, type = "simple")
cat("\n=== CS-DiD: Log Establishments ===\n")
summary(agg_estab)

# Aggregate: dynamic (event study)
es_estab <- aggte(cs_estab, type = "dynamic", min_e = -4, max_e = 2)
cat("\n=== Event Study: Log Establishments ===\n")
summary(es_estab)

# CS-DiD for employment
cs_emp <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

agg_emp <- aggte(cs_emp, type = "simple")
cat("\n=== CS-DiD: Log Employment ===\n")
summary(agg_emp)

es_emp <- aggte(cs_emp, type = "dynamic", min_e = -4, max_e = 2)
cat("\n=== Event Study: Log Employment ===\n")
summary(es_emp)

# ============================================================
# 3. Palladium price decomposition
# ============================================================

# Interaction: law effect conditional on palladium price
twfe_price <- feols(log_estab ~ post + pd_std + post:pd_std | state_fips + year,
                    data = panel,
                    cluster = ~state_fips)

cat("\n=== Palladium Price Decomposition ===\n")
summary(twfe_price)

# ============================================================
# 4. Law type heterogeneity
# ============================================================
panel <- panel %>%
  mutate(
    dealer_reg = if_else(!is.na(law_type) & grepl("dealer", law_type), 1L, 0L),
    post_dealer = post * dealer_reg,
    post_penalty = post * (1L - dealer_reg)
  )

# Only among treated states in post period
twfe_hetero <- feols(log_estab ~ post_dealer + post_penalty | state_fips + year,
                     data = panel,
                     cluster = ~state_fips)

cat("\n=== Heterogeneity by Law Type ===\n")
summary(twfe_hetero)

# ============================================================
# 5. Write diagnostics.json for validator
# ============================================================
diagnostics <- list(
  n_treated = sum(panel$treated & panel$year == 2023),
  n_pre = length(unique(panel$year[panel$year < 2022])),
  n_obs = nrow(panel),
  n_states = n_distinct(panel$state_fips),
  n_never_treated = sum(!panel$treated & panel$year == 2023),
  att_estab = round(agg_estab$overall.att, 4),
  se_estab = round(agg_estab$overall.se, 4),
  att_emp = round(agg_emp$overall.att, 4),
  se_emp = round(agg_emp$overall.se, 4)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

# Save results for tables
save(twfe_estab, twfe_emp, cs_estab, cs_emp,
     agg_estab, agg_emp, es_estab, es_emp,
     twfe_price, twfe_hetero, diagnostics,
     file = file.path(data_dir, "main_results.RData"))
cat("Results saved.\n")
