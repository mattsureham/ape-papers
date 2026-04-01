# =============================================================================
# 03_main_analysis.R — Main DiD analysis
# Paper: apep_1283 — Prevailing Wage Repeals and the Racial Earnings Gap
# =============================================================================

source("00_packages.R")

df_state  <- readRDS("../data/analysis_state.rds")
df_sector <- readRDS("../data/analysis_sector.rds")

# ---------------------------------------------------------------------------
# 1. Callaway-Sant'Anna: Main effect on B/W earnings ratio
# ---------------------------------------------------------------------------
cat("=== Callaway-Sant'Anna: Construction B/W Earnings Ratio ===\n")

# Need unique state ID
df_state <- df_state %>%
  mutate(state_id = as.integer(factor(state_abbr)))

cs_main <- att_gt(
  yname = "bw_ratio",
  tname = "period",
  idname = "state_id",
  gname = "first_treat_period",
  data = df_state,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

# Overall ATT
cs_agg <- aggte(cs_main, type = "simple")
cat("\nOverall ATT on B/W ratio:\n")
summary(cs_agg)

# Dynamic/event study
cs_es <- aggte(cs_main, type = "dynamic", min_e = -12, max_e = 16)
cat("\nEvent study:\n")
summary(cs_es)

# ---------------------------------------------------------------------------
# 2. TWFE with fixest for comparison and robustness
# ---------------------------------------------------------------------------
cat("\n=== TWFE (fixest): Construction B/W Ratio ===\n")

df_state <- df_state %>%
  mutate(post_repeal = as.integer(treated_state & period >= first_treat_period))

twfe_main <- feols(
  bw_ratio ~ post_repeal | state_id + period,
  data = df_state,
  cluster = ~state_id
)
cat("\nTWFE main result:\n")
summary(twfe_main)

# Sun-Abraham for heterogeneity-robust event study
df_state <- df_state %>%
  mutate(
    first_treat_sa = ifelse(first_treat_period == 0, 10000L, first_treat_period)
  )

sa_es <- feols(
  bw_ratio ~ sunab(first_treat_sa, period) | state_id + period,
  data = df_state,
  cluster = ~state_id
)
cat("\nSun-Abraham event study:\n")
summary(sa_es)

# ---------------------------------------------------------------------------
# 3. Mechanism test: NAICS 237 vs 236/238
# ---------------------------------------------------------------------------
cat("\n=== Mechanism Test: Public (237) vs Private (236/238) ===\n")

df_sector <- df_sector %>%
  mutate(
    state_id = as.integer(factor(state_abbr)),
    post_repeal = as.integer(treated_state & period >= first_treat_period),
    state_industry = paste0(state_abbr, "_", industry_int)
  )

# NAICS 237 (public construction)
twfe_237 <- feols(
  bw_ratio ~ post_repeal | state_id + period,
  data = df_sector %>% filter(industry_int == 237),
  cluster = ~state_id
)

# NAICS 236 (building/private construction)
twfe_236 <- feols(
  bw_ratio ~ post_repeal | state_id + period,
  data = df_sector %>% filter(industry_int == 236),
  cluster = ~state_id
)

# NAICS 238 (specialty trades)
twfe_238 <- feols(
  bw_ratio ~ post_repeal | state_id + period,
  data = df_sector %>% filter(industry_int == 238),
  cluster = ~state_id
)

cat("\nNAICS 237 (Heavy/Civil - public):\n")
summary(twfe_237)
cat("\nNAICS 236 (Building - private):\n")
summary(twfe_236)
cat("\nNAICS 238 (Specialty Trades):\n")
summary(twfe_238)

# Triple-difference: is_public × post_repeal within treated states
# df_sector is already filtered to construction in 02_clean_data.R
df_sector_constr <- df_sector

triple_did <- feols(
  bw_ratio ~ post_repeal * is_public_construction |
    state_id + period + industry_int,
  data = df_sector_constr,
  cluster = ~state_id
)
cat("\nTriple-difference (public × post_repeal):\n")
summary(triple_did)

# ---------------------------------------------------------------------------
# 4. Callaway-Sant'Anna on log earnings separately
# ---------------------------------------------------------------------------
cat("\n=== CS: Black and White Earnings Separately ===\n")

# Black earnings
cs_black <- att_gt(
  yname = "ln_bw_gap",
  tname = "period",
  idname = "state_id",
  gname = "first_treat_period",
  data = df_state,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)
cs_black_agg <- aggte(cs_black, type = "simple")
cat("\nCS ATT on log(Black/White) gap:\n")
summary(cs_black_agg)

# ---------------------------------------------------------------------------
# 5. Save results
# ---------------------------------------------------------------------------
results <- list(
  cs_main = cs_main,
  cs_agg = cs_agg,
  cs_es = cs_es,
  twfe_main = twfe_main,
  sa_es = sa_es,
  twfe_237 = twfe_237,
  twfe_236 = twfe_236,
  twfe_238 = twfe_238,
  triple_did = triple_did,
  cs_black_agg = cs_black_agg
)

saveRDS(results, "../data/main_results.rds")

# Write diagnostics.json for validator
n_treated_states <- n_distinct(df_state$state_abbr[df_state$treated_state])
n_pre <- min(df_state$first_treat_period[df_state$treated_state]) - min(df_state$period)
n_obs <- nrow(df_state)

jsonlite::write_json(
  list(
    n_treated = n_treated_states,
    n_pre = n_pre,
    n_obs = n_obs
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

cat("\nAll main results saved.\n")
cat("Diagnostics: n_treated =", n_treated_states, ", n_pre =", n_pre, ", n_obs =", n_obs, "\n")
