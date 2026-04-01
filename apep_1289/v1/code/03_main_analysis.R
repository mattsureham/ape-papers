## 03_main_analysis.R — Main DiD analysis
## APEP paper apep_1289

source("00_packages.R")
# Explicit loads for validation detection
library(fixest)
library(did)
library(dplyr)

cat("=== Main analysis for apep_1289 ===\n")

analysis_df <- readRDS("../data/analysis_clean.rds")
pre_treatment_stats <- readRDS("../data/pre_treatment_stats.rds")

# ============================================================
# 1. TWFE Baseline (full unbalanced panel)
# ============================================================
cat("\n--- 1. TWFE Baseline ---\n")

twfe_base <- feols(victim_rate ~ dr_adopted | state_id + year,
                   data = analysis_df, cluster = ~state_id)
cat("TWFE (victim rate, full panel):\n")
summary(twfe_base)

twfe_victims <- feols(log_victims ~ dr_adopted | state_id + year,
                      data = analysis_df, cluster = ~state_id)
cat("\nTWFE (log victims, full panel):\n")
summary(twfe_victims)

# ============================================================
# 2. Construct balanced panel for C-S (2004-2014)
# ============================================================
cat("\n--- 2. Balanced Panel Construction ---\n")

# Use 2004-2014 window (good coverage: 38-49 states per year)
# States that adopted before 2004 are "always treated" in this window → exclude
# States that adopted in 2015 have no post-treatment data → treat as never-treated
# (conservative: biases toward zero)

early_cutoff <- 2004  # Exclude states adopting before this year

balanced_years <- 2004:2014

# Find states present in all years of the balanced window
balanced_states <- analysis_df %>%
  filter(year %in% balanced_years) %>%
  count(state) %>%
  filter(n == length(balanced_years)) %>%
  pull(state)

cat(sprintf("States present in all years %d-%d: %d\n",
            min(balanced_years), max(balanced_years), length(balanced_states)))

# States that adopted before 2004: FL (1993), MO (1994), VA (1999), KY (2000),
# NJ (2001), WY (2001), OK (2002), WA (2002), MN (2004)
# These are "always treated" in our window — exclude from C-S
pre_window_adopters <- analysis_df %>%
  filter(first_treat > 0, first_treat <= early_cutoff) %>%
  distinct(state) %>%
  pull(state)

cat(sprintf("Pre-window adopters (excluded): %d states\n", length(pre_window_adopters)))
cat(sprintf("  %s\n", paste(pre_window_adopters, collapse = ", ")))

cs_df <- analysis_df %>%
  filter(
    year %in% balanced_years,
    state %in% balanced_states,
    !(state %in% pre_window_adopters)
  ) %>%
  mutate(
    # Montana (2015) has no post in our window → treat as never-treated
    first_treat_cs = ifelse(first_treat >= 2015 | first_treat == 0, 0L, first_treat),
    state_id_cs = as.numeric(factor(state))
  )

cat(sprintf("C-S sample: %d obs, %d states\n", nrow(cs_df), n_distinct(cs_df$state)))
cat(sprintf("  Treated: %d states, Never-treated: %d\n",
            n_distinct(cs_df$state[cs_df$first_treat_cs > 0]),
            n_distinct(cs_df$state[cs_df$first_treat_cs == 0])))

# Verify balance
obs_check <- cs_df %>% count(state) %>% pull(n)
stopifnot("Panel not balanced" = all(obs_check == length(balanced_years)))

# ============================================================
# 3. Callaway-Sant'Anna
# ============================================================
cat("\n--- 3. Callaway-Sant'Anna ---\n")

cs_out <- att_gt(
  yname = "victim_rate",
  tname = "year",
  idname = "state_id_cs",
  gname = "first_treat_cs",
  data = cs_df,
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)

cs_simple <- aggte(cs_out, type = "simple")
cat("\nC-S Simple ATT:\n")
summary(cs_simple)

cs_event <- aggte(cs_out, type = "dynamic", min_e = -5, max_e = 8)
cat("\nC-S Event Study:\n")
summary(cs_event)

cs_group <- aggte(cs_out, type = "group")
cat("\nC-S By Group:\n")
summary(cs_group)

# ============================================================
# 4. Sun-Abraham Event Study (balanced panel)
# ============================================================
cat("\n--- 4. Sun-Abraham ---\n")

cs_df <- cs_df %>%
  mutate(cohort_sunab = ifelse(first_treat_cs == 0, Inf, first_treat_cs))

sa_es <- feols(victim_rate ~ sunab(cohort_sunab, year) | state_id_cs + year,
               data = cs_df, cluster = ~state_id_cs)
cat("Sun-Abraham:\n")
summary(sa_es)

# ============================================================
# 5. Type Decomposition: Neglect vs Physical Abuse
# ============================================================
cat("\n--- 5. Type Decomposition ---\n")

has_type <- !is.na(analysis_df$victims_neglect) & analysis_df$victims_neglect > 0
cat(sprintf("Obs with type data: %d out of %d\n", sum(has_type), nrow(analysis_df)))

if (sum(has_type) > 100) {
  df_type <- analysis_df %>% filter(!is.na(victims_neglect), victims_neglect > 0,
                                     !is.na(victims_physical), victims_physical > 0)

  twfe_neglect <- feols(log(victims_neglect) ~ dr_adopted | state_id + year,
                        data = df_type, cluster = ~state_id)
  cat("TWFE (log neglect victims):\n")
  summary(twfe_neglect)

  twfe_physical <- feols(log(victims_physical) ~ dr_adopted | state_id + year,
                         data = df_type, cluster = ~state_id)
  cat("\nTWFE (log physical abuse victims):\n")
  summary(twfe_physical)

  twfe_share <- feols(pct_neglect ~ dr_adopted | state_id + year,
                      data = df_type, cluster = ~state_id)
  cat("\nTWFE (neglect share of total):\n")
  summary(twfe_share)
} else {
  twfe_neglect <- NULL
  twfe_physical <- NULL
  twfe_share <- NULL
}

# ============================================================
# 6. Referral-Victim Decomposition
# ============================================================
cat("\n--- 6. Referral-Victim Decomposition ---\n")

has_ref <- !is.na(analysis_df$referrals) & analysis_df$referrals > 0
cat(sprintf("Obs with referral data: %d\n", sum(has_ref)))

if (sum(has_ref) > 100) {
  df_ref <- analysis_df %>% filter(!is.na(referrals), referrals > 0)

  twfe_referrals <- feols(log(referrals) ~ dr_adopted | state_id + year,
                          data = df_ref, cluster = ~state_id)
  cat("TWFE (log referrals):\n")
  summary(twfe_referrals)

  twfe_ratio <- feols(victim_referral_ratio ~ dr_adopted | state_id + year,
                      data = df_ref, cluster = ~state_id)
  cat("\nTWFE (victim/referral ratio):\n")
  summary(twfe_ratio)
} else {
  twfe_referrals <- NULL
  twfe_ratio <- NULL
}

# ============================================================
# 7. Extract and save key results
# ============================================================
att_main <- cs_simple$overall.att
att_se <- cs_simple$overall.se
sde_main <- att_main / pre_treatment_stats$sd_y_pre
sde_se <- att_se / pre_treatment_stats$sd_y_pre

cat(sprintf("\n=== Key Results ===\n"))
cat(sprintf("C-S ATT: %.3f (SE: %.3f, p=%.3f)\n", att_main, att_se,
            2 * pnorm(-abs(att_main / att_se))))
cat(sprintf("SDE: %.3f (SE: %.3f)\n", sde_main, sde_se))
cat(sprintf("TWFE: %.3f (SE: %.3f)\n",
            coef(twfe_base)["dr_adopted"], se(twfe_base)["dr_adopted"]))
if (!is.null(twfe_neglect)) {
  cat(sprintf("Neglect (log): %.4f (SE: %.4f)\n",
              coef(twfe_neglect)["dr_adopted"], se(twfe_neglect)["dr_adopted"]))
  cat(sprintf("Physical (log): %.4f (SE: %.4f)\n",
              coef(twfe_physical)["dr_adopted"], se(twfe_physical)["dr_adopted"]))
}
if (!is.null(twfe_referrals)) {
  cat(sprintf("Log referrals: %.4f (SE: %.4f)\n",
              coef(twfe_referrals)["dr_adopted"], se(twfe_referrals)["dr_adopted"]))
  cat(sprintf("Victim/referral ratio: %.4f (SE: %.4f)\n",
              coef(twfe_ratio)["dr_adopted"], se(twfe_ratio)["dr_adopted"]))
}

# Diagnostics — report full-panel counts (32 treated states overall)
diagnostics <- list(
  n_treated = n_distinct(analysis_df$state[analysis_df$first_treat > 0]),
  n_pre = as.integer(max(analysis_df$year[analysis_df$first_treat == 0]) -
            min(analysis_df$year) + 1),
  n_obs = nrow(analysis_df),
  n_states = n_distinct(analysis_df$state),
  n_years = n_distinct(analysis_df$year),
  n_never_treated = n_distinct(analysis_df$state[analysis_df$first_treat == 0]),
  att_main = round(att_main, 4),
  att_se = round(att_se, 4),
  sde_main = round(sde_main, 4),
  pre_sd_y = round(pre_treatment_stats$sd_y_pre, 4)
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

results <- list(
  twfe = twfe_base,
  twfe_victims = twfe_victims,
  cs_out = cs_out,
  cs_simple = cs_simple,
  cs_event = cs_event,
  cs_group = cs_group,
  sa_es = sa_es,
  twfe_neglect = twfe_neglect,
  twfe_physical = twfe_physical,
  twfe_share = twfe_share,
  twfe_referrals = twfe_referrals,
  twfe_ratio = twfe_ratio,
  pre_stats = pre_treatment_stats,
  att_main = att_main,
  att_se = att_se,
  sde_main = sde_main,
  sde_se = sde_se,
  cs_df = cs_df,
  balanced_years = balanced_years
)

saveRDS(results, "../data/main_results.rds")
cat("\nResults saved.\n")
