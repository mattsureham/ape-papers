# 03_main_analysis.R — Main DiD analysis
# APEP-1441: Swiss cantonal minimum wages

source("00_packages.R")

panel <- read_csv("../data/panel.csv", show_col_types = FALSE)
udemo <- read_csv("../data/udemo_panel.csv", show_col_types = FALSE)

# ============================================================================
# 1. Callaway & Sant'Anna (2021) — Staggered DiD
# ============================================================================

# Sector-level analysis: high-bite sectors only
high_bite <- panel %>%
  filter(high_bite) %>%
  group_by(canton, year) %>%
  summarise(
    employment = sum(employment, na.rm = TRUE),
    establishments = sum(establishments, na.rm = TRUE),
    fte = sum(fte, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(
    panel %>% select(canton, year, first_treat, treated_canton) %>% distinct(),
    by = c("canton", "year")
  ) %>%
  mutate(
    log_emp = log(employment + 1),
    log_est = log(establishments + 1),
    log_fte = log(fte + 1),
    canton_id = as.integer(factor(canton))
  )

cat("=== Callaway & Sant'Anna: High-Bite Sectors ===\n")
cat("Treated cantons:", sum(high_bite$treated_canton & high_bite$year == 2015), "\n")
cat("Control cantons:", sum(!high_bite$treated_canton & high_bite$year == 2015), "\n")

# CS for log employment (high-bite sectors)
cs_emp <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "canton_id",
  gname = "first_treat",
  data = high_bite,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

cat("\nGroup-time ATTs (log employment, high-bite):\n")
summary(cs_emp)

# Aggregate: overall ATT
agg_emp <- aggte(cs_emp, type = "simple")
cat("\nOverall ATT (log employment):\n")
summary(agg_emp)

# Dynamic event study
es_emp <- aggte(cs_emp, type = "dynamic", min_e = -5, max_e = 5)
cat("\nEvent study (log employment):\n")
summary(es_emp)

# CS for log establishments
cs_est <- att_gt(
  yname = "log_est",
  tname = "year",
  idname = "canton_id",
  gname = "first_treat",
  data = high_bite,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_est <- aggte(cs_est, type = "simple")
es_est <- aggte(cs_est, type = "dynamic", min_e = -5, max_e = 5)

# CS for log FTE
cs_fte <- att_gt(
  yname = "log_fte",
  tname = "year",
  idname = "canton_id",
  gname = "first_treat",
  data = high_bite,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_fte <- aggte(cs_fte, type = "simple")
es_fte <- aggte(cs_fte, type = "dynamic", min_e = -5, max_e = 5)

# ============================================================================
# 2. Total employment (all sectors)
# ============================================================================
cat("\n=== Callaway & Sant'Anna: All Sectors ===\n")

total <- panel %>%
  filter(noga == "total") %>%
  mutate(canton_id = as.integer(factor(canton)))

cs_total <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "canton_id",
  gname = "first_treat",
  data = total,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_total <- aggte(cs_total, type = "simple")
es_total <- aggte(cs_total, type = "dynamic", min_e = -5, max_e = 5)
cat("Overall ATT (total employment):\n")
summary(agg_total)

# ============================================================================
# 3. TWFE (for comparison / Bacon decomposition)
# ============================================================================
cat("\n=== TWFE Comparison ===\n")

# TWFE on high-bite sectors
twfe_emp <- feols(log_emp ~ treat_post | canton_id + year,
                  data = high_bite %>% mutate(treat_post = treated_canton * (year >= first_treat)),
                  cluster = ~canton_id)

cat("TWFE coefficient (log emp, high-bite):", coef(twfe_emp), "\n")
cat("CS ATT:", agg_emp$overall.att, "\n")

# Sun & Abraham
high_bite <- high_bite %>%
  mutate(first_treat_sa = ifelse(first_treat == 0, 10000, first_treat))

sa_emp <- feols(log_emp ~ sunab(first_treat_sa, year) | canton_id + year,
                data = high_bite,
                cluster = ~canton_id)

cat("\nSun & Abraham ATT:", summary(sa_emp)$coeftable[1, 1], "\n")

# ============================================================================
# 4. Triple-Difference: High-bite vs Low-bite
# ============================================================================
cat("\n=== Triple-Difference ===\n")

# Canton-sector-year panel (excluding total)
sector_panel <- panel %>%
  filter(sector_type %in% c("high_bite", "low_bite")) %>%
  group_by(canton, year, sector_type, first_treat, treated_canton) %>%
  summarise(
    employment = sum(employment, na.rm = TRUE),
    establishments = sum(establishments, na.rm = TRUE),
    fte = sum(fte, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    log_emp = log(employment + 1),
    log_est = log(establishments + 1),
    canton_id = as.integer(factor(canton)),
    high = as.integer(sector_type == "high_bite"),
    post = as.integer(year >= first_treat & treated_canton),
    ddd = treated_canton * post * high
  )

# Triple-diff
ddd_emp <- feols(log_emp ~ ddd + treated_canton:post + treated_canton:high + post:high |
                   canton_id + year + sector_type,
                 data = sector_panel,
                 cluster = ~canton_id)

cat("DDD coefficient:", coef(ddd_emp)["ddd"], "\n")
summary(ddd_emp)

# ============================================================================
# 5. Firm demographics
# ============================================================================
cat("\n=== Firm Demographics (UDEMO) ===\n")

udemo <- udemo %>%
  mutate(canton_id = as.integer(factor(canton)))

cs_births <- att_gt(
  yname = "log_births",
  tname = "year",
  idname = "canton_id",
  gname = "first_treat",
  data = udemo,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_births <- aggte(cs_births, type = "simple")
cat("Overall ATT (log firm births):\n")
summary(agg_births)

# ============================================================================
# 6. Save results
# ============================================================================
results <- list(
  cs_emp = cs_emp,
  agg_emp = agg_emp,
  es_emp = es_emp,
  cs_est = cs_est,
  agg_est = agg_est,
  es_est = es_est,
  cs_fte = cs_fte,
  agg_fte = agg_fte,
  es_fte = es_fte,
  cs_total = cs_total,
  agg_total = agg_total,
  es_total = es_total,
  twfe_emp = twfe_emp,
  sa_emp = sa_emp,
  ddd_emp = ddd_emp,
  cs_births = cs_births,
  agg_births = agg_births
)

saveRDS(results, "../data/results.rds")
cat("\nAll results saved to data/results.rds\n")

# ============================================================================
# 7. Diagnostics for validation
# ============================================================================
n_treated <- length(unique(high_bite$canton[high_bite$treated_canton]))
n_pre <- length(unique(high_bite$year[high_bite$year < min(high_bite$first_treat[high_bite$treated_canton])]))
n_obs <- nrow(high_bite)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  att_emp = agg_emp$overall.att,
  se_emp = agg_emp$overall.se,
  att_est = agg_est$overall.att,
  se_est = agg_est$overall.se,
  att_fte = agg_fte$overall.att,
  se_fte = agg_fte$overall.se
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics saved. n_treated=", n_treated, ", n_pre=", n_pre, ", n_obs=", n_obs, "\n")
