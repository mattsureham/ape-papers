# =============================================================================
# 04_robustness.R — Robustness checks for apep_0779
# =============================================================================

source("00_packages.R")

cat("Loading analysis panel...\n")
panel <- readRDS("../data/analysis_panel.rds")

# -------------------------------------------------------------------------
# 1. Callaway-Sant'Anna on Female 25-34 subsample (DD)
# -------------------------------------------------------------------------
cat("\n=== Callaway-Sant'Anna (Female 25-34, DD) ===\n")

cs_data <- panel %>%
  filter(female == 1, young == 1) %>%
  mutate(
    # CS needs: id (state), time (integer period), group (first treated period, 0 = never)
    id = state_fips,
    time = t_int,
    # g: first treated period as t_int value
    g_cs = case_when(
      is.na(treat_year) ~ 0L,
      TRUE ~ (treat_year - 2000L) * 4L + 1L  # Q1 of treatment year
    )
  )

cat("CS data: N =", nrow(cs_data), ", states =", length(unique(cs_data$id)), "\n")
cat("Treatment groups:\n")
print(table(cs_data$g_cs[!duplicated(paste(cs_data$id, cs_data$time))]))

# Run CS estimator
cs_out <- tryCatch({
  att_gt(
    yname = "sep_rate",
    gname = "g_cs",
    idname = "id",
    tname = "time",
    data = cs_data,
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "varying"
  )
}, error = function(e) {
  cat("CS estimator error:", e$message, "\n")
  NULL
})

if (!is.null(cs_out)) {
  cs_agg <- aggte(cs_out, type = "simple")
  cat("CS ATT (simple):", cs_agg$overall.att, "\n")
  cat("CS SE:", cs_agg$overall.se, "\n")

  # Event study aggregation
  cs_es <- tryCatch({
    aggte(cs_out, type = "dynamic", min_e = -8, max_e = 12)
  }, error = function(e) {
    cat("CS event study error:", e$message, "\n")
    NULL
  })

  if (!is.null(cs_es)) {
    cat("\nCS Event Study (dynamic):\n")
    es_df <- data.frame(
      e = cs_es$egt,
      att = cs_es$att.egt,
      se = cs_es$se.egt
    )
    print(es_df)
  }
} else {
  cat("CS estimator failed — skipping.\n")
  cs_agg <- NULL
  cs_es <- NULL
}

# -------------------------------------------------------------------------
# 2. Placebo: Male 25-34 (should be null — men don't breastfeed)
# -------------------------------------------------------------------------
cat("\n=== Placebo: Male 25-34 DDD ===\n")

# Create a "placebo DDD" = male x young x post (should be zero by construction
# since DDD already controls for this, but run DD on male subsample)
male_young <- panel %>% filter(sex == 1, young == 1)

m_placebo_male <- feols(
  sep_rate ~ post_treat | state_fips + t_int,
  data = male_young,
  cluster = ~state_fips
)
cat("Placebo (male 25-34) coefficient:", coef(m_placebo_male)["post_treat"], "\n")
cat("SE:", se(m_placebo_male)["post_treat"], "\n")
cat("p-value:", pvalue(m_placebo_male)["post_treat"], "\n")

# -------------------------------------------------------------------------
# 3. Placebo: Female 45-54 (should be null — past childbearing)
# -------------------------------------------------------------------------
cat("\n=== Placebo: Female 45-54 DD ===\n")

female_old <- panel %>% filter(sex == 2, young == 0)

m_placebo_female_old <- feols(
  sep_rate ~ post_treat | state_fips + t_int,
  data = female_old,
  cluster = ~state_fips
)
cat("Placebo (female 45-54) coefficient:", coef(m_placebo_female_old)["post_treat"], "\n")
cat("SE:", se(m_placebo_female_old)["post_treat"], "\n")
cat("p-value:", pvalue(m_placebo_female_old)["post_treat"], "\n")

# -------------------------------------------------------------------------
# 4. Exclude early adopters (pre-2001) — TX, UT, MN, GA, HI
# -------------------------------------------------------------------------
cat("\n=== Exclude Early Adopters (treat_year < 2001) ===\n")

panel_no_early <- panel %>%
  filter(is.na(treat_year) | treat_year >= 2001)

m_no_early <- feols(
  sep_rate ~ ddd + female_post + young_post + female_young |
    state_fips^sex^agegrp + sex^agegrp^t_int + state_fips^t_int,
  data = panel_no_early,
  cluster = ~state_fips
)
cat("DDD (excl. early adopters):", coef(m_no_early)["ddd"], "\n")
cat("SE:", se(m_no_early)["ddd"], "\n")
cat("p-value:", pvalue(m_no_early)["ddd"], "\n")
cat("N:", nobs(m_no_early), "\n")

# -------------------------------------------------------------------------
# 5. Alternative outcomes
# -------------------------------------------------------------------------
cat("\n=== Alternative Outcome: Hire Rate DDD (already in main) ===\n")
cat("See main_analysis.R for hire rate, log employment, log earnings results.\n")

# -------------------------------------------------------------------------
# 6. Event study (leads and lags via fixest)
# -------------------------------------------------------------------------
cat("\n=== Event Study (fixest sunab) ===\n")

# Create relative time to treatment
panel_es <- panel %>%
  filter(female == 1, young == 1) %>%
  mutate(
    cohort = ifelse(is.na(treat_year), 10000L, treat_year),
    rel_time = year - cohort
  )

# Sun-Abraham event study via fixest sunab
m_es <- tryCatch({
  feols(
    sep_rate ~ sunab(cohort, year, ref.p = -1) | state_fips + t_int,
    data = panel_es,
    cluster = ~state_fips
  )
}, error = function(e) {
  cat("Event study error:", e$message, "\n")
  NULL
})

if (!is.null(m_es)) {
  cat("Event study coefficients:\n")
  print(summary(m_es, agg = "att"))
}

# -------------------------------------------------------------------------
# Save robustness results
# -------------------------------------------------------------------------
cat("\n=== Saving Robustness Results ===\n")

robustness <- list(
  cs_att = if (!is.null(cs_agg)) list(att = cs_agg$overall.att, se = cs_agg$overall.se) else NULL,
  cs_es = if (!is.null(cs_es)) data.frame(e = cs_es$egt, att = cs_es$att.egt, se = cs_es$se.egt) else NULL,
  placebo_male = list(
    beta = unname(coef(m_placebo_male)["post_treat"]),
    se = unname(se(m_placebo_male)["post_treat"]),
    pvalue = unname(pvalue(m_placebo_male)["post_treat"])
  ),
  placebo_female_old = list(
    beta = unname(coef(m_placebo_female_old)["post_treat"]),
    se = unname(se(m_placebo_female_old)["post_treat"]),
    pvalue = unname(pvalue(m_placebo_female_old)["post_treat"])
  ),
  no_early_adopters = list(
    beta = unname(coef(m_no_early)["ddd"]),
    se = unname(se(m_no_early)["ddd"]),
    pvalue = unname(pvalue(m_no_early)["ddd"]),
    n = nobs(m_no_early)
  ),
  event_study = m_es
)

saveRDS(robustness, "../data/robustness_results.rds")
saveRDS(
  list(
    m_placebo_male = m_placebo_male,
    m_placebo_female_old = m_placebo_female_old,
    m_no_early = m_no_early,
    cs_out = cs_out,
    m_es = m_es
  ),
  "../data/robustness_models.rds"
)

cat("Saved robustness_results.rds and robustness_models.rds\n")
cat("Done.\n")
