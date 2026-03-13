## 03_main_analysis.R — Main DiD analysis
## apep_0662: Clean Slate Laws and Statistical Discrimination

source("00_packages.R")
load("data/clean_data.RData")

cat("=== Main Analysis ===\n")

# =========================================================
# 1. Callaway-Sant'Anna: Unemployment Rate
# =========================================================
cat("\n--- CS-DiD: Unemployment Rate ---\n")

cs_urate <- att_gt(
  yname = "urate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = bls_annual %>% filter(year >= 2014),
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_id"
)

cat("CS-DiD ATT(g,t) for unemployment rate:\n")
summary(cs_urate)

# Aggregate: simple ATT
cs_urate_agg <- aggte(cs_urate, type = "simple")
cat("\nOverall ATT (unemployment rate):\n")
summary(cs_urate_agg)

# Event study
cs_urate_es <- aggte(cs_urate, type = "dynamic", min_e = -5, max_e = 5)
cat("\nEvent study (unemployment rate):\n")
summary(cs_urate_es)

# =========================================================
# 2. CS-DiD: E-pop Ratio
# =========================================================
cat("\n--- CS-DiD: E-pop Ratio ---\n")

cs_epop <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = bls_annual %>% filter(year >= 2014),
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_id"
)

cs_epop_agg <- aggte(cs_epop, type = "simple")
cat("\nOverall ATT (E-pop ratio):\n")
summary(cs_epop_agg)

cs_epop_es <- aggte(cs_epop, type = "dynamic", min_e = -5, max_e = 5)

# =========================================================
# 3. CS-DiD: Black E-pop
# =========================================================
cat("\n--- CS-DiD: Black E-pop ---\n")

cs_black <- att_gt(
  yname = "black_epop",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = acs_clean %>% filter(year >= 2012, !is.na(black_epop)),
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_id"
)

cs_black_agg <- aggte(cs_black, type = "simple")
cat("\nOverall ATT (Black E-pop):\n")
summary(cs_black_agg)

# =========================================================
# 4. CS-DiD: White E-pop
# =========================================================
cat("\n--- CS-DiD: White E-pop ---\n")

cs_white <- att_gt(
  yname = "white_epop",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = acs_clean %>% filter(year >= 2012, !is.na(white_epop)),
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_id"
)

cs_white_agg <- aggte(cs_white, type = "simple")
cat("\nOverall ATT (White E-pop):\n")
summary(cs_white_agg)

# =========================================================
# 5. CS-DiD: Racial Employment Gap
# =========================================================
cat("\n--- CS-DiD: White-Black Employment Gap ---\n")

cs_gap <- att_gt(
  yname = "bw_gap",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = acs_clean %>% filter(year >= 2012, !is.na(bw_gap)),
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_id"
)

cs_gap_agg <- aggte(cs_gap, type = "simple")
cat("\nOverall ATT (White-Black E-pop gap):\n")
summary(cs_gap_agg)

cs_gap_es <- aggte(cs_gap, type = "dynamic", min_e = -4, max_e = 4)

# =========================================================
# 6. TWFE Regressions (fixest) for table presentation
# =========================================================
cat("\n--- TWFE Regressions ---\n")

# Create post indicator
bls_annual <- bls_annual %>%
  mutate(post = ifelse(first_treat > 0 & year >= first_treat, 1, 0))

acs_clean <- acs_clean %>%
  mutate(post = ifelse(first_treat > 0 & year >= first_treat, 1, 0))

# Sun-Abraham event study (fixest)
bls_annual <- bls_annual %>%
  mutate(
    first_treat_sa = ifelse(first_treat == 0, 10000, first_treat),
    rel_year = year - first_treat_sa
  )

# TWFE baselines
twfe_urate <- feols(urate ~ post | state_id + year, data = bls_annual, cluster = ~state_id)
twfe_epop <- feols(log_emp ~ post | state_id + year,
                   data = bls_annual %>% filter(!is.na(log_emp)),
                   cluster = ~state_id)
twfe_gap <- feols(bw_gap ~ post | state_id + year,
                  data = acs_clean %>% filter(!is.na(bw_gap)),
                  cluster = ~state_id)
twfe_black <- feols(black_epop ~ post | state_id + year,
                    data = acs_clean %>% filter(!is.na(black_epop)),
                    cluster = ~state_id)
twfe_white <- feols(white_epop ~ post | state_id + year,
                    data = acs_clean %>% filter(!is.na(white_epop)),
                    cluster = ~state_id)

cat("\nTWFE Results:\n")
cat("  Urate: ", round(coef(twfe_urate)["post"], 3),
    " (", round(se(twfe_urate)["post"], 3), ")\n")
cat("  E-pop: ", round(coef(twfe_epop)["post"], 3),
    " (", round(se(twfe_epop)["post"], 3), ")\n")
cat("  B-W gap: ", round(coef(twfe_gap)["post"], 3),
    " (", round(se(twfe_gap)["post"], 3), ")\n")
cat("  Black E-pop: ", round(coef(twfe_black)["post"], 3),
    " (", round(se(twfe_black)["post"], 3), ")\n")
cat("  White E-pop: ", round(coef(twfe_white)["post"], 3),
    " (", round(se(twfe_white)["post"], 3), ")\n")

# Sun-Abraham event study
sa_urate <- feols(urate ~ sunab(first_treat_sa, year) | state_id + year,
                  data = bls_annual, cluster = ~state_id)
sa_epop <- feols(log_emp ~ sunab(first_treat_sa, year) | state_id + year,
                 data = bls_annual %>% filter(!is.na(log_emp)),
                 cluster = ~state_id)

cat("\nSun-Abraham event study coefficients (urate):\n")
print(summary(sa_urate))

# =========================================================
# 7. Save results
# =========================================================

# Diagnostics for validator
# n_treated = number of treated state-year observations (post-treatment)
n_treated <- sum(bls_annual$post == 1)
n_pre <- length(unique(bls_annual$year[bls_annual$year < 2018]))
n_obs <- nrow(bls_annual)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs
  ),
  "data/diagnostics.json",
  auto_unbox = TRUE
)

save(
  cs_urate, cs_urate_agg, cs_urate_es,
  cs_epop, cs_epop_agg, cs_epop_es,
  cs_black, cs_black_agg,
  cs_white, cs_white_agg,
  cs_gap, cs_gap_agg, cs_gap_es,
  twfe_urate, twfe_epop, twfe_gap, twfe_black, twfe_white,
  sa_urate, sa_epop,
  bls_annual, acs_clean,
  file = "data/analysis_results.RData"
)

cat("\n=== Main analysis complete ===\n")
cat("Diagnostics: n_treated=", n_treated, ", n_pre=", n_pre, ", n_obs=", n_obs, "\n")
