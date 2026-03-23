# =============================================================================
# 03_main_analysis.R — DDD regressions: Fair Workweek x Race x Food Service
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/panel.rds")

# ---------------------------------------------------------------------------
# 1. NAICS 72 (food service) — main DDD specification
# ---------------------------------------------------------------------------

df72 <- df %>% filter(industry == "72")

cat("=== MAIN ANALYSIS: NAICS 72 Food Service ===\n")
cat(sprintf("Obs: %s | Counties: %d | Treated: %d | States: %d\n",
            format(nrow(df72), big.mark = ","),
            n_distinct(df72$fips), n_distinct(df72$fips[df72$treated_ever]),
            n_distinct(df72$state_fips)))

# --- A. TWFE DDD (full sample) ---
# Y_cqr = β(Treat_cq × Black_r) + FE(county×race) + FE(quarter×race) + FE(state×quarter)
m1_emp <- feols(ln_emp ~ treat_post_black + treat_post + black:i(t) |
                  fips^race + t^race + state_fips^t,
                data = df72, cluster = ~state_fips)

m1_earn <- feols(ln_earn ~ treat_post_black + treat_post + black:i(t) |
                   fips^race + t^race + state_fips^t,
                 data = df72, cluster = ~state_fips)

m1_sep <- feols(ln_sep ~ treat_post_black + treat_post + black:i(t) |
                  fips^race + t^race + state_fips^t,
                data = df72, cluster = ~state_fips)

m1_hir <- feols(ln_hir ~ treat_post_black + treat_post + black:i(t) |
                  fips^race + t^race + state_fips^t,
                data = df72, cluster = ~state_fips)

m1_turn <- feols(TurnOvrS ~ treat_post_black + treat_post + black:i(t) |
                   fips^race + t^race + state_fips^t,
                 data = df72, cluster = ~state_fips)

cat("\n--- Full Sample TWFE DDD ---\n")
cat(sprintf("ln(Employment): DDD = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m1_emp)["treat_post_black"],
            se(m1_emp)["treat_post_black"],
            fixest::pvalue(m1_emp)["treat_post_black"]))
cat(sprintf("ln(Earnings):   DDD = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m1_earn)["treat_post_black"],
            se(m1_earn)["treat_post_black"],
            fixest::pvalue(m1_earn)["treat_post_black"]))
cat(sprintf("ln(Separations):DDD = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m1_sep)["treat_post_black"],
            se(m1_sep)["treat_post_black"],
            fixest::pvalue(m1_sep)["treat_post_black"]))
cat(sprintf("ln(Hires):      DDD = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m1_hir)["treat_post_black"],
            se(m1_hir)["treat_post_black"],
            fixest::pvalue(m1_hir)["treat_post_black"]))
cat(sprintf("Turnover rate:  DDD = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m1_turn)["treat_post_black"],
            se(m1_turn)["treat_post_black"],
            fixest::pvalue(m1_turn)["treat_post_black"]))

# ---------------------------------------------------------------------------
# 2. Pre-COVID sample (main specification for paper)
# ---------------------------------------------------------------------------

df72_pre <- df72 %>% filter(in_pre_covid_sample)

cat("\n=== PRE-COVID SAMPLE ===\n")
cat(sprintf("Obs: %s | Counties: %d | Treated: %d\n",
            format(nrow(df72_pre), big.mark = ","),
            n_distinct(df72_pre$fips),
            n_distinct(df72_pre$fips[df72_pre$treated_ever])))

m2_emp <- feols(ln_emp ~ treat_post_black + treat_post + black:i(t) |
                  fips^race + t^race + state_fips^t,
                data = df72_pre, cluster = ~state_fips)

m2_earn <- feols(ln_earn ~ treat_post_black + treat_post + black:i(t) |
                   fips^race + t^race + state_fips^t,
                 data = df72_pre, cluster = ~state_fips)

m2_sep <- feols(ln_sep ~ treat_post_black + treat_post + black:i(t) |
                  fips^race + t^race + state_fips^t,
                data = df72_pre, cluster = ~state_fips)

m2_hir <- feols(ln_hir ~ treat_post_black + treat_post + black:i(t) |
                  fips^race + t^race + state_fips^t,
                data = df72_pre, cluster = ~state_fips)

m2_turn <- feols(TurnOvrS ~ treat_post_black + treat_post + black:i(t) |
                   fips^race + t^race + state_fips^t,
                 data = df72_pre, cluster = ~state_fips)

cat("\n--- Pre-COVID TWFE DDD ---\n")
cat(sprintf("ln(Employment): DDD = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m2_emp)["treat_post_black"],
            se(m2_emp)["treat_post_black"],
            fixest::pvalue(m2_emp)["treat_post_black"]))
cat(sprintf("ln(Earnings):   DDD = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m2_earn)["treat_post_black"],
            se(m2_earn)["treat_post_black"],
            fixest::pvalue(m2_earn)["treat_post_black"]))
cat(sprintf("ln(Separations):DDD = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m2_sep)["treat_post_black"],
            se(m2_sep)["treat_post_black"],
            fixest::pvalue(m2_sep)["treat_post_black"]))
cat(sprintf("ln(Hires):      DDD = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m2_hir)["treat_post_black"],
            se(m2_hir)["treat_post_black"],
            fixest::pvalue(m2_hir)["treat_post_black"]))
cat(sprintf("Turnover rate:  DDD = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m2_turn)["treat_post_black"],
            se(m2_turn)["treat_post_black"],
            fixest::pvalue(m2_turn)["treat_post_black"]))

# ---------------------------------------------------------------------------
# 3. Event study — dynamic DDD (pre-COVID sample)
# ---------------------------------------------------------------------------

# Relative time to treatment (in quarters)
df72_pre <- df72_pre %>%
  mutate(
    rel_q = ifelse(treated_ever, round((yq - cohort_yq) * 4), NA_integer_)
  )

# Event study: bin at -8 and +8 quarters, exclude -1
df72_es <- df72_pre %>%
  filter(treated_ever | !treated_ever) %>%
  mutate(
    rel_q_bin = case_when(
      is.na(rel_q) ~ NA_integer_,
      rel_q <= -8  ~ -8L,
      rel_q >= 8   ~ 8L,
      TRUE         ~ as.integer(rel_q)
    )
  )

# For never-treated units, set rel_q_bin = 0 (they serve as controls via FE)
# fixest's i() handles this automatically with ref = -1

m_es_emp <- feols(ln_emp ~ i(rel_q_bin, black, ref = -1) + i(rel_q_bin, ref = -1) |
                    fips^race + t^race + state_fips^t,
                  data = df72_es %>% filter(treated_ever),
                  cluster = ~state_fips)

cat("\n--- Event Study DDD (Employment, treated units only) ---\n")
cat("Relative quarter | DDD coef | SE\n")
es_coefs <- coef(m_es_emp)[grep("rel_q_bin.*:black", names(coef(m_es_emp)))]
es_ses <- se(m_es_emp)[grep("rel_q_bin.*:black", names(se(m_es_emp)))]
for (i in seq_along(es_coefs)) {
  cat(sprintf("  %s: %.4f (%.4f)\n", names(es_coefs)[i], es_coefs[i], es_ses[i]))
}

# ---------------------------------------------------------------------------
# 4. Callaway-Sant'Anna DDD approximation
# ---------------------------------------------------------------------------
# CS does not natively support DDD. We use a "residualized" approach:
# Step 1: Compute Black-All gap in each county-quarter
# Step 2: Apply CS to the gap

gap_panel <- df72_pre %>%
  select(fips, year, quarter, yq, t, race, state_fips,
         ln_emp, ln_earn, ln_sep, first_treat, treated_ever) %>%
  pivot_wider(
    id_cols = c(fips, year, quarter, yq, t, state_fips, first_treat, treated_ever),
    names_from = race,
    values_from = c(ln_emp, ln_earn, ln_sep)
  ) %>%
  mutate(
    gap_emp = ln_emp_A2 - ln_emp_A0,
    gap_earn = ln_earn_A2 - ln_earn_A0,
    gap_sep = ln_sep_A2 - ln_sep_A0
  ) %>%
  filter(!is.na(gap_emp))

# CS on the gap (this is the DDD)
# Convert first_treat to integer time periods for CS
gap_panel <- gap_panel %>%
  mutate(
    first_treat_t = ifelse(first_treat == 0, 0, round((first_treat - 2013) * 4) + 1)
  )

cat("\n=== Callaway-Sant'Anna on Black-All Gap (DDD) ===\n")
cat(sprintf("Gap panel: %d obs, %d counties\n", nrow(gap_panel), n_distinct(gap_panel$fips)))

cs_emp <- tryCatch({
  att_gt(
    yname = "gap_emp",
    tname = "t",
    idname = "fips",
    gname = "first_treat_t",
    data = as.data.frame(gap_panel),
    control_group = "nevertreated",
    clustervars = "state_fips",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS estimation error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_emp)) {
  cs_agg <- aggte(cs_emp, type = "simple")
  cat(sprintf("CS ATT (gap employment): %.4f (SE = %.4f)\n",
              cs_agg$overall.att, cs_agg$overall.se))

  cs_dyn <- aggte(cs_emp, type = "dynamic", min_e = -8, max_e = 8)
  cat("\nCS Dynamic (event study):\n")
  for (i in seq_along(cs_dyn$egt)) {
    cat(sprintf("  e=%2d: %.4f (%.4f)\n", cs_dyn$egt[i], cs_dyn$att.egt[i], cs_dyn$se.egt[i]))
  }
}

# CS on earnings gap
cs_earn <- tryCatch({
  att_gt(
    yname = "gap_earn",
    tname = "t",
    idname = "fips",
    gname = "first_treat_t",
    data = as.data.frame(gap_panel %>% filter(!is.na(gap_earn))),
    control_group = "nevertreated",
    clustervars = "state_fips",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS earnings error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_earn)) {
  cs_earn_agg <- aggte(cs_earn, type = "simple")
  cat(sprintf("\nCS ATT (gap earnings): %.4f (SE = %.4f)\n",
              cs_earn_agg$overall.att, cs_earn_agg$overall.se))
}

# CS on separations gap
cs_sep <- tryCatch({
  att_gt(
    yname = "gap_sep",
    tname = "t",
    idname = "fips",
    gname = "first_treat_t",
    data = as.data.frame(gap_panel %>% filter(!is.na(gap_sep))),
    control_group = "nevertreated",
    clustervars = "state_fips",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS separations error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_sep)) {
  cs_sep_agg <- aggte(cs_sep, type = "simple")
  cat(sprintf("CS ATT (gap separations): %.4f (SE = %.4f)\n",
              cs_sep_agg$overall.att, cs_sep_agg$overall.se))
}

# ---------------------------------------------------------------------------
# 5. Save results
# ---------------------------------------------------------------------------

results <- list(
  # TWFE models
  twfe_full = list(emp = m1_emp, earn = m1_earn, sep = m1_sep, hir = m1_hir, turn = m1_turn),
  twfe_precovid = list(emp = m2_emp, earn = m2_earn, sep = m2_sep, hir = m2_hir, turn = m2_turn),
  # Event study
  es_emp = m_es_emp,
  # CS
  cs_emp = cs_emp,
  cs_earn = cs_earn,
  cs_sep = cs_sep,
  # Panel metadata
  meta = list(
    n_obs_full = nrow(df72),
    n_obs_precovid = nrow(df72_pre),
    n_counties_treated = n_distinct(df72$fips[df72$treated_ever]),
    n_counties_control = n_distinct(df72$fips[!df72$treated_ever]),
    n_states = n_distinct(df72$state_fips),
    n_clusters = n_distinct(df72_pre$state_fips),
    pre_periods = sum(unique(df72_pre$yq) < min(df72_pre$cohort_yq[df72_pre$treated_ever], na.rm = TRUE))
  )
)

saveRDS(results, "../data/main_results.rds")

# Write diagnostics.json for validate_v1.py
write_json(list(
  n_treated = n_distinct(df72_pre$fips[df72_pre$treated_ever]),
  n_pre = results$meta$pre_periods,
  n_obs = nrow(df72_pre)
), "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nResults saved to data/main_results.rds\n")
cat("Diagnostics saved to data/diagnostics.json\n")
