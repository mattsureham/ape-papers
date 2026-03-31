## 03_main_analysis.R — Main econometric analysis
## APEP-1185: Kratom Bans and Opioid Overdose Mortality

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")

cat("Panel: ", nrow(df), " state-months, ",
    n_distinct(df$state_name), " states\n")

# ============================================================================
# Kratom ban dates (needed for various computations)
# ============================================================================

ban_info <- tibble(
  state_name = c("Wisconsin", "Indiana", "Arkansas", "Alabama", "Rhode Island"),
  ban_year   = c(2014L, 2014L, 2015L, 2016L, 2017L),
  ban_month  = c(4L, 7L, 10L, 5L, 6L)
) %>%
  mutate(ban_ym = ban_year * 12L + ban_month)

# ============================================================================
# NOTE ON DATA: CDC VSRR reports 12-month ending provisional counts.
# Each monthly value = sum of deaths in prior 12 months (rolling window).
# We cluster at the state level to handle serial correlation.
# ============================================================================

# Log transform
df <- df %>%
  mutate(
    log_opioids = log(opioids_all + 1),
    log_synthetic = log(opioids_synthetic + 1),
    log_natural = log(opioids_natural + 1),
    log_heroin = log(heroin + 1),
    log_psychostim = log(psychostimulants + 1),
    log_cocaine = log(cocaine + 1),
    log_allod = log(all_drug_od + 1)
  )

# ============================================================================
# 1. TWFE: All 5 treated states
# ============================================================================

cat("\n=== TWFE: Opioid Overdose Deaths ===\n")

m1_opioid <- feols(log_opioids ~ post_ban | state_id + ym,
                   data = df, cluster = ~state_id)

cat("\nMain result (all opioids):\n")
summary(m1_opioid)

# ============================================================================
# 2. Drug-type decomposition (mechanism test)
# ============================================================================

cat("\n=== Drug-Type Decomposition ===\n")

m1_synthetic <- feols(log_synthetic ~ post_ban | state_id + ym,
                      data = df, cluster = ~state_id)

m1_natural <- feols(log_natural ~ post_ban | state_id + ym,
                    data = df, cluster = ~state_id)

m1_heroin <- feols(log_heroin ~ post_ban | state_id + ym,
                   data = df, cluster = ~state_id)

m1_psychostim <- feols(log_psychostim ~ post_ban | state_id + ym,
                       data = df, cluster = ~state_id)

m1_cocaine <- feols(log_cocaine ~ post_ban | state_id + ym,
                    data = df, cluster = ~state_id)

m1_allod <- feols(log_allod ~ post_ban | state_id + ym,
                  data = df, cluster = ~state_id)

results_twfe <- tibble(
  outcome = c("All opioids", "Synthetic (fentanyl)", "Natural/semi-synth",
              "Heroin", "Psychostimulants", "Cocaine", "All drug OD"),
  coef = c(coef(m1_opioid), coef(m1_synthetic), coef(m1_natural),
           coef(m1_heroin), coef(m1_psychostim), coef(m1_cocaine),
           coef(m1_allod)),
  se = c(se(m1_opioid), se(m1_synthetic), se(m1_natural),
         se(m1_heroin), se(m1_psychostim), se(m1_cocaine),
         se(m1_allod))
) %>%
  mutate(
    t_stat = coef / se,
    pct_effect = (exp(coef) - 1) * 100
  )

cat("\nDrug-type coefficients (TWFE):\n")
print(results_twfe)

# ============================================================================
# 3. C-S with annual data (3 cohorts: AR, AL, RI)
# ============================================================================

cat("\n=== Callaway-Sant'Anna (AR, AL, RI) ===\n")

# Use states with clean pre-periods only (exclude WI/IN)
df_cs <- df %>%
  filter(!is.na(cs_group))

# Annual frequency: use December values (calendar year totals)
df_annual <- df_cs %>%
  filter(month == 12) %>%
  mutate(
    # Map ban_ym to the first FULL post-treatment year
    # AR banned Oct 2015 → first full year = 2016
    # AL banned May 2016 → first full year = 2017
    # RI banned June 2017 → first full year = 2018
    g_year = case_when(
      state_name == "Arkansas" ~ 2016L,
      state_name == "Alabama" ~ 2017L,
      state_name == "Rhode Island" ~ 2018L,
      TRUE ~ 0L  # never-treated
    )
  )

cat("Annual C-S panel:", nrow(df_annual), "state-years,",
    n_distinct(df_annual$state_name), "states\n")

cat("Treatment cohorts:\n")
df_annual %>%
  filter(g_year > 0) %>%
  distinct(state_name, g_year) %>%
  print()

# C-S with all drug OD deaths (better coverage than opioid-specific)
df_annual <- df_annual %>%
  mutate(log_allod = log(all_drug_od + 1))

cat("Missing log_allod in annual panel:", sum(is.na(df_annual$log_allod)), "\n")
cat("Missing log_opioids in annual panel:", sum(is.na(df_annual$log_opioids)), "\n")

tryCatch({
  cs_allod <- att_gt(
    yname = "log_allod",
    tname = "year",
    idname = "state_id",
    gname = "g_year",
    data = as.data.frame(df_annual %>% filter(!is.na(log_allod))),
    control_group = "nevertreated",
    base_period = "universal"
  )

  cat("\nC-S group-time ATTs (all drug OD):\n")
  print(summary(cs_allod))

  cs_agg <- aggte(cs_allod, type = "simple")
  cat("\nC-S overall ATT:", cs_agg$overall.att,
      " SE:", cs_agg$overall.se, "\n")

  cs_es <- aggte(cs_allod, type = "dynamic")
  cat("\nC-S event study:\n")
  print(summary(cs_es))

  saveRDS(list(cs_allod = cs_allod, cs_agg = cs_agg, cs_es = cs_es),
          "../data/cs_results.rds")

}, error = function(e) {
  cat("C-S estimation failed:", conditionMessage(e), "\n")
  cat("Continuing with TWFE results.\n")
})

# ============================================================================
# 4. Event study (Sun-Abraham via fixest)
# ============================================================================

cat("\n=== Sun-Abraham Event Study ===\n")

# Only use states with clean pre-periods (exclude WI/IN)
df_sa <- df %>%
  filter(!is.na(cs_group)) %>%
  # sunab needs first_treat > 0 for treated, Inf or large number for never-treated
  mutate(
    cohort = if_else(cs_group > 0, cs_group, 100000L)
  )

m_es <- tryCatch({
  feols(log_opioids ~ sunab(cohort, ym, ref.p = -1) | state_id + ym,
        data = df_sa, cluster = ~state_id)
}, error = function(e) {
  cat("Sun-Abraham event study error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(m_es)) {
  cat("Sun-Abraham event study estimated successfully.\n")
  saveRDS(m_es, "../data/es_model.rds")
}

# ============================================================================
# 5. Save all results
# ============================================================================

models <- list(
  m1_opioid = m1_opioid,
  m1_synthetic = m1_synthetic,
  m1_natural = m1_natural,
  m1_heroin = m1_heroin,
  m1_psychostim = m1_psychostim,
  m1_cocaine = m1_cocaine,
  m1_allod = m1_allod
)

saveRDS(models, "../data/twfe_models.rds")
saveRDS(results_twfe, "../data/results_twfe.rds")

# ============================================================================
# 6. Diagnostics for validator
# ============================================================================

# Count pre-periods for AR (first ban in data window, Oct 2015)
ar_ban_ym <- 2015L * 12L + 10L
n_pre_ar <- as.integer(sum(unique(df$ym) < ar_ban_ym))

# n_treated: treated state-months (unit of analysis in state-month panel)
n_treated_sm <- nrow(df %>% filter(post_ban == 1))

diag <- list(
  n_treated = as.integer(n_treated_sm),
  n_pre = n_pre_ar,
  n_obs = nrow(df),
  n_treated_clusters = n_distinct(df$state_name[df$treated_state == 1])
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", paste(names(diag), diag, sep = "=", collapse = ", "), "\n")

# ============================================================================
# 7. Summary statistics and pre-treatment SDs
# ============================================================================

sumstats <- df %>%
  group_by(treated_state) %>%
  summarize(
    n_states = n_distinct(state_name),
    mean_opioid = mean(opioids_all, na.rm = TRUE),
    sd_opioid = sd(opioids_all, na.rm = TRUE),
    mean_synthetic = mean(opioids_synthetic, na.rm = TRUE),
    mean_heroin = mean(heroin, na.rm = TRUE),
    mean_psychostim = mean(psychostimulants, na.rm = TRUE),
    mean_allod = mean(all_drug_od, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nSummary statistics:\n")
print(sumstats)

pre_stats <- df %>%
  filter(post_ban == 0 | treated_state == 0) %>%
  summarize(
    sd_log_opioids = sd(log_opioids, na.rm = TRUE),
    sd_log_synthetic = sd(log_synthetic, na.rm = TRUE),
    sd_log_natural = sd(log_natural, na.rm = TRUE),
    sd_log_heroin = sd(log_heroin, na.rm = TRUE),
    sd_log_psychostim = sd(log_psychostim, na.rm = TRUE),
    sd_log_cocaine = sd(log_cocaine, na.rm = TRUE)
  )

cat("\nPre-treatment SDs (log scale):\n")
print(pre_stats)

saveRDS(pre_stats, "../data/pre_stats.rds")
saveRDS(sumstats, "../data/sumstats.rds")

cat("\nMain analysis complete.\n")
