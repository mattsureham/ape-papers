# =============================================================================
# 03_main_analysis.R — Callaway-Sant'Anna DiD + TWFE
# Paper: apep_0879 — MW and racial composition of hiring
# =============================================================================

source("00_packages.R")
library(fixest)
library(did)

df <- readRDS("../data/analysis_lowwage.rds")
df_triple <- readRDS("../data/analysis_triple.rds")

# Ensure county numeric ID for CS DiD
df <- df %>%
  mutate(county_id = as.integer(factor(county_fips)))

# =============================================================================
# A. Callaway-Sant'Anna: Black share of new hires
# =============================================================================
cat("Running CS DiD for Black hire share...\n")

cs_bhs <- att_gt(
  yname = "black_hire_share",
  tname = "year",
  idname = "county_id",
  gname = "first_treat_year",
  data = df %>% filter(first_treat_year != 0 | treated == 0),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)

# Aggregate: overall ATT
cs_bhs_agg <- aggte(cs_bhs, type = "simple")
cat(sprintf("  CS ATT (Black hire share): %.4f (SE: %.4f)\n",
            cs_bhs_agg$overall.att, cs_bhs_agg$overall.se))

# Event study
cs_bhs_es <- aggte(cs_bhs, type = "dynamic", min_e = -5, max_e = 10)

# =============================================================================
# B. Callaway-Sant'Anna: B-W earnings ratio
# =============================================================================
cat("Running CS DiD for B-W earnings ratio...\n")

df_earn <- df %>%
  filter(!is.na(bw_earn_ratio), first_treat_year != 0 | treated == 0)

cs_bwer <- att_gt(
  yname = "bw_earn_ratio",
  tname = "year",
  idname = "county_id",
  gname = "first_treat_year",
  data = df_earn,
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)

cs_bwer_agg <- aggte(cs_bwer, type = "simple")
cat(sprintf("  CS ATT (B-W earnings ratio): %.4f (SE: %.4f)\n",
            cs_bwer_agg$overall.att, cs_bwer_agg$overall.se))

cs_bwer_es <- aggte(cs_bwer, type = "dynamic", min_e = -5, max_e = 10)

# =============================================================================
# C. TWFE baseline (for comparison with CS)
# =============================================================================
cat("Running TWFE regressions...\n")

twfe_bhs <- feols(
  black_hire_share ~ post | county_fips + year,
  data = df,
  cluster = ~state_fips
)

twfe_bwer <- feols(
  bw_earn_ratio ~ post | county_fips + year,
  data = df %>% filter(!is.na(bw_earn_ratio)),
  cluster = ~state_fips
)

cat(sprintf("  TWFE (Black hire share): %.4f (SE: %.4f)\n",
            coef(twfe_bhs)["post"], se(twfe_bhs)["post"]))
cat(sprintf("  TWFE (B-W earnings ratio): %.4f (SE: %.4f)\n",
            coef(twfe_bwer)["post"], se(twfe_bwer)["post"]))

# =============================================================================
# D. Triple-difference: MW-exposed vs non-exposed industries
# =============================================================================
cat("Running triple-difference...\n")

df_triple <- df_triple %>%
  mutate(county_id = as.integer(factor(county_fips)))

twfe_triple <- feols(
  black_hire_share ~ post:mw_exposed | county_fips^industry + year^industry + county_fips^year,
  data = df_triple,
  cluster = ~state_fips
)

cat(sprintf("  Triple-diff (post × exposed): %.4f (SE: %.4f)\n",
            coef(twfe_triple)[1], se(twfe_triple)[1]))

# =============================================================================
# E. Mechanism: Black separation rate
# =============================================================================
cat("Running separation rate analysis...\n")

df_sep <- df %>% filter(!is.na(black_sep_rate))

cs_bsr <- att_gt(
  yname = "black_sep_rate",
  tname = "year",
  idname = "county_id",
  gname = "first_treat_year",
  data = df_sep %>% filter(first_treat_year != 0 | treated == 0),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)

cs_bsr_agg <- aggte(cs_bsr, type = "simple")
cat(sprintf("  CS ATT (Black sep rate): %.4f (SE: %.4f)\n",
            cs_bsr_agg$overall.att, cs_bsr_agg$overall.se))

# =============================================================================
# F. Diagnostics JSON for validator
# =============================================================================
n_treated <- n_distinct(df$county_fips[df$treated == 1])
n_pre <- length(unique(df$year[df$year < min(df$first_treat_year[df$first_treat_year > 0])]))
n_obs <- nrow(df)

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))

# =============================================================================
# G. Save all results
# =============================================================================
results <- list(
  cs_bhs = cs_bhs,
  cs_bhs_agg = cs_bhs_agg,
  cs_bhs_es = cs_bhs_es,
  cs_bwer = cs_bwer,
  cs_bwer_agg = cs_bwer_agg,
  cs_bwer_es = cs_bwer_es,
  cs_bsr_agg = cs_bsr_agg,
  twfe_bhs = twfe_bhs,
  twfe_bwer = twfe_bwer,
  twfe_triple = twfe_triple
)

saveRDS(results, "../data/main_results.rds")
cat("\nMain analysis complete.\n")
