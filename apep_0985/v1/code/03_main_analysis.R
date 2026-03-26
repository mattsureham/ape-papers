# 03_main_analysis.R — Main analysis for apep_0985
# Staggered DiD + commodity price decomposition

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
cat(sprintf("Panel: %d obs, %d states\n", nrow(panel), n_distinct(panel$state_abbr)))

# ============================================================
# 0. Prepare data for estimators
# ============================================================
panel <- panel %>%
  mutate(
    cohort_int = if_else(ever_treat == 1L,
                         as.integer(year(enact_ym)) * 12L + as.integer(month(enact_ym)),
                         0L),
    first_treat = if_else(ever_treat == 1L, cohort_int, 10000L)
  )

# Drop states with zero variance in hits
state_var <- panel %>%
  group_by(state_abbr) %>%
  summarise(sd_hits = sd(hits, na.rm = TRUE), .groups = "drop")
panel <- panel %>%
  inner_join(state_var %>% filter(sd_hits > 0), by = "state_abbr")

cat(sprintf("Analysis sample: %d obs, %d states (%d treated, %d control)\n",
            nrow(panel), n_distinct(panel$state_abbr),
            n_distinct(panel$state_abbr[panel$ever_treat == 1]),
            n_distinct(panel$state_abbr[panel$ever_treat == 0])))

# Pre-treatment SD(Y) for SDE calculation
sd_y_pre <- sd(panel$ihs_hits[panel$treated == 0], na.rm = TRUE)
mean_y_pre <- mean(panel$ihs_hits[panel$treated == 0], na.rm = TRUE)
cat(sprintf("Pre-treatment: SD(Y)=%.3f, Mean(Y)=%.3f\n", sd_y_pre, mean_y_pre))

# ============================================================
# 1. TWFE SPECIFICATIONS
# ============================================================
cat("\n=== TWFE Results ===\n")

# Model 1: Simple TWFE
m1_twfe <- feols(ihs_hits ~ treated | state_id + ym_id,
                 data = panel, cluster = ~state_abbr)
cat(sprintf("M1 (simple TWFE): β=%.3f (SE=%.3f, p=%.3f)\n",
            coef(m1_twfe)["treated"], se(m1_twfe)["treated"],
            pvalue(m1_twfe)["treated"]))

# Model 2: TWFE with price interaction (decomposition)
# Note: log_pd is collinear with ym_id FE, so only the interaction is identified
m2_decomp <- feols(ihs_hits ~ treated + treated:log_pd | state_id + ym_id,
                   data = panel, cluster = ~state_abbr)
cat(sprintf("M2 (decomposition): β_law=%.3f, β_law×pd=%.3f\n",
            coef(m2_decomp)["treated"], coef(m2_decomp)["treated:log_pd"]))

# Model 3: With unemployment control
m3_ctrl <- feols(ihs_hits ~ treated + treated:log_pd + unemp_rate | state_id + ym_id,
                 data = panel, cluster = ~state_abbr)

# Model 4: State-specific linear trends
m4_trends <- feols(ihs_hits ~ treated | state_id[year] + ym_id,
                   data = panel, cluster = ~state_abbr)
cat(sprintf("M4 (state trends): β=%.3f (SE=%.3f, p=%.3f)\n",
            coef(m4_trends)["treated"], se(m4_trends)["treated"],
            pvalue(m4_trends)["treated"]))

# ============================================================
# 2. CALLAWAY-SANT'ANNA (2021)
# ============================================================
cat("\n=== Callaway-Sant'Anna ===\n")

cs_data <- panel %>%
  select(state_id, ym_id, cohort_int, ihs_hits, unemp_rate) %>%
  filter(!is.na(ihs_hits)) %>%
  as.data.frame()

cs_out <- att_gt(
  yname      = "ihs_hits",
  gname      = "cohort_int",
  idname     = "state_id",
  tname      = "ym_id",
  data       = cs_data,
  control_group = "notyettreated",
  base_period   = "universal",
  est_method    = "dr",
  bstrap        = TRUE,
  cband         = TRUE,
  biters        = 1000
)

cs_simple <- aggte(cs_out, type = "simple")
cat(sprintf("CS ATT: %.3f (SE=%.3f, p=%.4f)\n",
            cs_simple$overall.att, cs_simple$overall.se,
            2 * pnorm(-abs(cs_simple$overall.att / cs_simple$overall.se))))

cs_dynamic <- aggte(cs_out, type = "dynamic", min_e = -18, max_e = 30)

# ============================================================
# 3. SUN-ABRAHAM EVENT STUDY
# ============================================================
cat("\n=== Sun-Abraham Event Study ===\n")

es_sa <- feols(ihs_hits ~ sunab(first_treat, ym_id, ref.p = c(-1, .F)) |
                 state_id + ym_id,
               data = panel, cluster = ~state_abbr)

# Extract pre-trend test: joint F-test on pre-treatment coefficients
sa_coefs <- coeftable(es_sa)
pre_coefs <- rownames(sa_coefs)[grepl("::-[0-9]", rownames(sa_coefs))]
pre_coefs_near <- pre_coefs[as.numeric(gsub(".*::", "", pre_coefs)) >= -12]
cat(sprintf("Pre-treatment coefficients (t-12 to t-2): %d\n", length(pre_coefs_near)))

# ============================================================
# 4. PRICE MECHANISM — Cross-sectional variation
# ============================================================
cat("\n=== Price Mechanism ===\n")

# In cross section: states with more vehicle registrations (proxy for targets)
# should respond more to palladium prices.
# Use state × palladium interaction WITHOUT time FE to identify price channel

# Aggregate to state-quarter for cleaner estimation
panel_q <- panel %>%
  mutate(quarter = paste0(year, "Q", ceiling(month / 3))) %>%
  group_by(state_abbr, state_id, quarter, ever_treat) %>%
  summarise(
    hits = mean(hits, na.rm = TRUE),
    ihs_hits = mean(ihs_hits, na.rm = TRUE),
    pd_close = mean(pd_close, na.rm = TRUE),
    log_pd = mean(log_pd, na.rm = TRUE),
    treated = max(treated),
    unemp_rate = mean(unemp_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(q_id = as.integer(factor(quarter)))

# Price elasticity: never-treated states (no confounding from law)
m_price_nt <- feols(ihs_hits ~ log_pd | state_id,
                    data = panel_q %>% filter(ever_treat == 0),
                    cluster = ~state_abbr)
cat(sprintf("Price elasticity (never-treated, quarterly): β=%.3f (SE=%.3f)\n",
            coef(m_price_nt)["log_pd"], se(m_price_nt)["log_pd"]))

# ============================================================
# 5. HETEROGENEITY
# ============================================================
cat("\n=== Heterogeneity ===\n")

# By law type: felony vs dealer-only regulations
panel <- panel %>%
  mutate(
    is_felony = if_else(!is.na(law_type) & grepl("felony", law_type), 1L, 0L),
    treat_felony = treated * is_felony,
    treat_other  = treated * (1L - is_felony)
  )

m_het_type <- feols(ihs_hits ~ treat_felony + treat_other | state_id + ym_id,
                    data = panel, cluster = ~state_abbr)
cat(sprintf("Felony laws: β=%.3f (SE=%.3f)\n",
            coef(m_het_type)["treat_felony"], se(m_het_type)["treat_felony"]))
cat(sprintf("Dealer-only: β=%.3f (SE=%.3f)\n",
            coef(m_het_type)["treat_other"], se(m_het_type)["treat_other"]))

# By palladium price regime: high (above median) vs low
panel <- panel %>%
  mutate(
    pd_high = if_else(pd_close > median(pd_close, na.rm = TRUE), 1L, 0L),
    treat_hi = treated * pd_high,
    treat_lo = treated * (1L - pd_high)
  )

m_het_price <- feols(ihs_hits ~ treat_hi + treat_lo | state_id + ym_id,
                     data = panel, cluster = ~state_abbr)
cat(sprintf("Law × high-Pd: β=%.3f (SE=%.3f)\n",
            coef(m_het_price)["treat_hi"], se(m_het_price)["treat_hi"]))
cat(sprintf("Law × low-Pd:  β=%.3f (SE=%.3f)\n",
            coef(m_het_price)["treat_lo"], se(m_het_price)["treat_lo"]))

# ============================================================
# 6. SAVE RESULTS
# ============================================================
models <- list(
  twfe_simple  = m1_twfe,
  twfe_decomp  = m2_decomp,
  twfe_ctrl    = m3_ctrl,
  twfe_trends  = m4_trends,
  cs_out       = cs_out,
  cs_simple    = cs_simple,
  cs_dynamic   = cs_dynamic,
  es_sa        = es_sa,
  price_nt     = m_price_nt,
  het_type     = m_het_type,
  het_price    = m_het_price,
  panel_q      = panel_q
)
saveRDS(models, "../data/models.rds")

# Diagnostics for validator
n_treated_states <- n_distinct(panel$state_abbr[panel$ever_treat == 1])
n_pre_min <- panel %>%
  filter(ever_treat == 1) %>%
  group_by(state_abbr) %>%
  summarise(n_pre = sum(treated == 0), .groups = "drop") %>%
  pull(n_pre) %>%
  min()

diag <- list(n_treated = n_treated_states, n_pre = n_pre_min, n_obs = nrow(panel))
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

# Save key scalars for tables
scalars <- list(
  sd_y_pre   = sd_y_pre,
  mean_y_pre = mean_y_pre,
  n_states   = n_distinct(panel$state_abbr),
  n_treated  = n_treated_states,
  n_control  = n_distinct(panel$state_abbr[panel$ever_treat == 0]),
  n_obs      = nrow(panel),
  cs_att     = cs_simple$overall.att,
  cs_se      = cs_simple$overall.se
)
saveRDS(scalars, "../data/scalars.rds")

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))
cat("\n========== KEY RESULTS ==========\n")
cat(sprintf("TWFE simple:    β = %.3f (SE=%.3f)\n", coef(m1_twfe)["treated"], se(m1_twfe)["treated"]))
cat(sprintf("TWFE decomp:    β_law = %.3f, β_law×pd = %.3f\n",
            coef(m2_decomp)["treated"], coef(m2_decomp)["treated:log_pd"]))
cat(sprintf("TWFE trends:    β = %.3f (SE=%.3f)\n", coef(m4_trends)["treated"], se(m4_trends)["treated"]))
cat(sprintf("CS ATT:         β = %.3f (SE=%.3f)\n", cs_simple$overall.att, cs_simple$overall.se))
cat(sprintf("SD(Y) pre:      %.3f\n", sd_y_pre))
cat(sprintf("SDE (CS):       %.3f\n", cs_simple$overall.att / sd_y_pre))
