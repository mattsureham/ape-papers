# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# Marijuana legalization and labor market firm dynamics
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
agg_panel <- results$agg_panel

# ---------------------------------------------------------------------------
# 1. Placebo outcomes: Healthcare and Education (TWFE)
#    These sectors should be unaffected by marijuana legalization
# ---------------------------------------------------------------------------
cat("Placebo test: Healthcare employment (TWFE)...\n")

health_panel <- panel %>%
  filter(industry == "62") %>%
  mutate(log_emp = log(pmax(emp, 1))) %>%
  filter(!is.na(log_emp))

twfe_health <- feols(log_emp ~ post | state_id + time_id,
                     data = health_panel, cluster = ~state_fips)
cat("Placebo ATT (healthcare):", coef(twfe_health)["post"],
    "SE:", se(twfe_health)["post"], "\n")

cat("Placebo test: Education employment (TWFE)...\n")

edu_panel <- panel %>%
  filter(industry == "61") %>%
  mutate(log_emp = log(pmax(emp, 1))) %>%
  filter(!is.na(log_emp))

twfe_edu <- feols(log_emp ~ post | state_id + time_id,
                  data = edu_panel, cluster = ~state_fips)
cat("Placebo ATT (education):", coef(twfe_edu)["post"],
    "SE:", se(twfe_edu)["post"], "\n")

# ---------------------------------------------------------------------------
# 2. Alternative control group: not-yet-treated (CS-DiD)
# ---------------------------------------------------------------------------
cat("Alternative control: not-yet-treated...\n")

cs_nyt <- att_gt(
  yname = "log_emp",
  tname = "time_id",
  idname = "state_id",
  gname = "g_time",
  data = agg_panel,
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)

overall_nyt <- aggte(cs_nyt, type = "simple")
cat("ATT (not-yet-treated):", overall_nyt$overall.att,
    "SE:", overall_nyt$overall.se, "\n")

# ---------------------------------------------------------------------------
# 3. Leave-one-state-out: drop each treated state
# ---------------------------------------------------------------------------
cat("Leave-one-state-out for log(emp)...\n")

treated_states <- unique(agg_panel$state_fips[agg_panel$g_time > 0])
loo_results <- data.frame(
  dropped_state = numeric(),
  att = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (st in treated_states) {
  loo_data <- agg_panel %>% filter(state_fips != st)
  cs_loo <- tryCatch(
    att_gt(
      yname = "log_emp",
      tname = "time_id",
      idname = "state_id",
      gname = "g_time",
      data = loo_data,
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "varying"
    ),
    error = function(e) NULL
  )
  if (!is.null(cs_loo)) {
    agg_loo <- aggte(cs_loo, type = "simple")
    loo_results <- bind_rows(loo_results, data.frame(
      dropped_state = st,
      att = agg_loo$overall.att,
      se = agg_loo$overall.se
    ))
  }
}

cat("LOO range: [", min(loo_results$att), ",", max(loo_results$att), "]\n")

# ---------------------------------------------------------------------------
# 4. Sun-Abraham event study (fixest)
# ---------------------------------------------------------------------------
cat("Sun-Abraham event study...\n")

agg_panel_sa <- agg_panel %>%
  mutate(cohort = if_else(g_time == 0, 10000L, as.integer(g_time)))

sa_emp <- feols(
  log_emp ~ sunab(cohort, time_id, ref.p = -1) | state_id + time_id,
  data = agg_panel_sa,
  cluster = ~state_fips
)

# ---------------------------------------------------------------------------
# 5. Pre-trend test from CS-DiD event study
# ---------------------------------------------------------------------------
cat("Pre-trend test...\n")

es_emp <- results$es_emp
pre_atts <- es_emp$att.egt[es_emp$egt < 0]
pre_ses <- es_emp$se.egt[es_emp$egt < 0]

valid <- !is.na(pre_atts) & !is.na(pre_ses) & pre_ses > 0
pre_atts_v <- pre_atts[valid]
pre_ses_v <- pre_ses[valid]

if (length(pre_atts_v) > 0) {
  wald_stat <- sum((pre_atts_v / pre_ses_v)^2)
  wald_df <- length(pre_atts_v)
  wald_p <- 1 - pchisq(wald_stat, df = wald_df)
  cat("Pre-trend Wald test: chi2(", wald_df, ") =", round(wald_stat, 2),
      ", p =", round(wald_p, 4), "\n")
} else {
  wald_stat <- NA
  wald_df <- 0
  wald_p <- NA
  cat("No valid pre-trend coefficients for Wald test.\n")
}

# ---------------------------------------------------------------------------
# 6. Firm dynamics by sector (TWFE)
# ---------------------------------------------------------------------------
cat("Firm dynamics by sector (TWFE)...\n")

sectors <- c("44-45", "72", "62", "31-33", "54")
sector_labels <- c("Retail", "Accomm/Food", "Healthcare", "Manufacturing", "Professional")

sector_fd <- tibble()
for (i in seq_along(sectors)) {
  sec_data <- panel %>%
    filter(industry == sectors[i], !is.na(net_firm_jb))

  twfe_sec <- tryCatch(
    feols(net_firm_jb ~ post | state_id + time_id, data = sec_data,
          cluster = ~state_fips),
    error = function(e) NULL
  )

  if (!is.null(twfe_sec)) {
    sector_fd <- bind_rows(sector_fd, tibble(
      industry = sectors[i],
      label = sector_labels[i],
      att = coef(twfe_sec)["post"],
      se = se(twfe_sec)["post"]
    ))
  }
}

cat("Sector firm dynamics:\n")
print(as.data.frame(sector_fd))

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------
rob_results <- list(
  placebo_health_att = coef(twfe_health)["post"],
  placebo_health_se = se(twfe_health)["post"],
  placebo_edu_att = coef(twfe_edu)["post"],
  placebo_edu_se = se(twfe_edu)["post"],
  overall_nyt = overall_nyt,
  loo_results = loo_results,
  sa_emp = sa_emp,
  wald_stat = wald_stat, wald_df = wald_df, wald_p = wald_p,
  sector_fd = sector_fd
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("Robustness results saved.\n")
