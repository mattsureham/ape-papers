# ==============================================================================
# 03_main_analysis.R — DDD and staggered DiD regressions
# apep_1211: Medicaid Reimbursement and Black-White Nursing Home Earnings Gap
# ==============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")

# ==============================================================================
# PART A: Triple-Difference (DDD) with fixest
# ==============================================================================
# DDD: (Black vs White) × (Nursing homes vs Ambulatory) × (Post rate increase)
# This is the main specification.

cat("=== PART A: DDD Regressions ===\n")

# Restrict to NAICS 623 (nursing homes) and 621 (ambulatory care)
ddd_df <- df |>
  filter(industry %in% c("623", "621"))

# Annualize: collapse to state-year-race-industry (average across quarters)
ddd_annual <- ddd_df |>
  group_by(state_fips, year, race, race_label, black, industry, nursing_home,
           treat_year, post, ind_label) |>
  summarise(
    EarnS = weighted.mean(EarnS, Emp, na.rm = TRUE),
    Emp = sum(Emp, na.rm = TRUE),
    log_earn = log(weighted.mean(EarnS, Emp, na.rm = TRUE)),
    .groups = "drop"
  ) |>
  mutate(
    state_year = paste(state_fips, year, sep = "_"),
    state_ind = paste(state_fips, industry, sep = "_"),
    state_race = paste(state_fips, race, sep = "_"),
    ind_race = paste(industry, race, sep = "_")
  )

cat(sprintf("DDD panel: %d obs (annual, state × year × race × industry)\n", nrow(ddd_annual)))

# --- Main DDD specification ---
# Y_syrj = β₁(Post × Black × NH) + β₂(Post × NH) + β₃(Post × Black) + FEs + ε
# FEs: state×year, industry×race, state×industry, state×race

# Model 1: Basic DDD
m1 <- feols(
  log_earn ~ post:black:nursing_home + post:nursing_home + post:black |
    state_fips^year + industry^race + state_fips^industry + state_fips^race,
  data = ddd_annual,
  cluster = ~state_fips
)

cat("\n--- Model 1: Basic DDD ---\n")
summary(m1)

# Model 2: DDD with state×year×industry and state×year×race FEs
m2 <- feols(
  log_earn ~ post:black:nursing_home |
    state_fips^year^industry + state_fips^year^race + industry^race,
  data = ddd_annual,
  cluster = ~state_fips
)

cat("\n--- Model 2: Saturated DDD ---\n")
summary(m2)

# Model 3: DDD in levels (dollars)
m3 <- feols(
  EarnS ~ post:black:nursing_home + post:nursing_home + post:black |
    state_fips^year + industry^race + state_fips^industry + state_fips^race,
  data = ddd_annual,
  cluster = ~state_fips
)

cat("\n--- Model 3: DDD in Levels ---\n")
summary(m3)

# ==============================================================================
# PART B: Callaway-Sant'Anna Staggered DiD (within Nursing Homes)
# ==============================================================================
# Focus: Black vs White earnings gap within NAICS 623, using staggered treatment

cat("\n=== PART B: Callaway-Sant'Anna Event Study ===\n")

# Prepare CS data: annual, NAICS 623 only
cs_df <- df |>
  filter(industry == "623") |>
  group_by(state_fips, year, race, black, treat_year) |>
  summarise(
    EarnS = weighted.mean(EarnS, Emp, na.rm = TRUE),
    Emp = sum(Emp, na.rm = TRUE),
    .groups = "drop"
  )

# Black workers: staggered DiD on Black earnings in nursing homes
cs_black <- cs_df |>
  filter(race == "A2") |>
  mutate(
    id = state_fips,
    first_treat = ifelse(treat_year == 0L, 0L, treat_year)
  )

cat(sprintf("CS Black panel: %d obs, %d states, %d treated\n",
            nrow(cs_black), n_distinct(cs_black$id),
            n_distinct(cs_black$id[cs_black$first_treat > 0])))

# Run CS estimation
cs_out_black <- att_gt(
  yname = "EarnS",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = as.data.frame(cs_black),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)

cat("\n--- CS ATT(g,t) for Black Workers ---\n")
summary(cs_out_black)

# Aggregate to event study
es_black <- aggte(cs_out_black, type = "dynamic", min_e = -5, max_e = 4)
cat("\n--- Event Study (Black Workers) ---\n")
summary(es_black)

# Overall ATT
att_black <- aggte(cs_out_black, type = "simple")
cat("\n--- Overall ATT (Black Workers) ---\n")
summary(att_black)

# White workers: staggered DiD
cs_white <- cs_df |>
  filter(race == "A1") |>
  mutate(
    id = state_fips,
    first_treat = ifelse(treat_year == 0L, 0L, treat_year)
  )

cs_out_white <- att_gt(
  yname = "EarnS",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = as.data.frame(cs_white),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)

es_white <- aggte(cs_out_white, type = "dynamic", min_e = -5, max_e = 4)
att_white <- aggte(cs_out_white, type = "simple")

cat("\n--- Overall ATT (White Workers) ---\n")
summary(att_white)

# ==============================================================================
# PART C: Differential effect (Black vs White)
# ==============================================================================

# Within nursing homes: DD = Black × Post
cat("\n=== PART C: Differential Effect Within Nursing Homes ===\n")

nh_annual <- df |>
  filter(industry == "623") |>
  group_by(state_fips, year, race, black, treat_year, post) |>
  summarise(
    EarnS = weighted.mean(EarnS, Emp, na.rm = TRUE),
    Emp = sum(Emp, na.rm = TRUE),
    log_earn = log(weighted.mean(EarnS, Emp, na.rm = TRUE)),
    .groups = "drop"
  )

# DD within nursing homes: Black × Post
m4 <- feols(
  log_earn ~ post:black |
    state_fips^year + state_fips^race,
  data = nh_annual,
  cluster = ~state_fips
)

cat("\n--- Model 4: DD (Black × Post) within Nursing Homes ---\n")
summary(m4)

# ==============================================================================
# PART D: Save results for tables
# ==============================================================================

# Collect key results
results <- list(
  ddd_basic = m1,
  ddd_saturated = m2,
  ddd_levels = m3,
  dd_within_nh = m4,
  cs_black = cs_out_black,
  cs_white = cs_out_white,
  es_black = es_black,
  es_white = es_white,
  att_black = att_black,
  att_white = att_white
)

saveRDS(results, "../data/main_results.rds")

# --- Diagnostics for validator -----------------------------------------------
diagnostics <- list(
  n_treated = n_distinct(df$state_fips[df$treat_year > 0]),
  n_pre = min(df$treat_year[df$treat_year > 0]) - min(df$year),
  n_obs = nrow(ddd_annual)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Results saved ===\n")
cat(sprintf("DDD coefficient (log): %.4f (SE: %.4f)\n",
            coef(m1)["post:black:nursing_home"],
            se(m1)["post:black:nursing_home"]))
cat(sprintf("ATT Black: $%.0f (SE: $%.0f)\n", att_black$overall.att, att_black$overall.se))
cat(sprintf("ATT White: $%.0f (SE: $%.0f)\n", att_white$overall.att, att_white$overall.se))
cat(sprintf("Differential: $%.0f\n", att_black$overall.att - att_white$overall.att))
