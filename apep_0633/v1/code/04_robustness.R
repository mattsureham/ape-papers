## 04_robustness.R — Robustness checks and heterogeneity
## apep_0633: Marijuana tax earmarking and education spending fungibility

source("00_packages.R")

data_dir <- "../data/"
panel <- read_csv(file.path(data_dir, "analysis_panel.csv"), show_col_types = FALSE)
panel <- panel %>% mutate(state_id = as.numeric(factor(state_abbr)))

## ──────────────────────────────────────────────────
## 1. Exclude Alaska (outlier with extreme per-pupil spending)
## ──────────────────────────────────────────────────

cat("=== Robustness: Exclude Alaska ===\n")

panel_no_ak <- panel %>% filter(state_abbr != "AK")

cs_exp_no_ak <- att_gt(
  yname = "exp_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel_no_ak %>% filter(!is.na(exp_pp)),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_exp_no_ak <- aggte(cs_exp_no_ak, type = "simple")
cat("ATT (excl. Alaska):\n")
summary(agg_exp_no_ak)

## ──────────────────────────────────────────────────
## 2. Log outcomes (scale-invariant)
## ──────────────────────────────────────────────────

cat("\n=== Robustness: Log Total Expenditure ===\n")

panel <- panel %>%
  mutate(
    log_exp_pp = log(exp_pp),
    log_rev_pp = log(rev_pp),
    log_st_rev_pp = log(st_rev_pp)
  )

cs_log_exp <- att_gt(
  yname = "log_exp_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel %>% filter(!is.na(log_exp_pp)),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_log_exp <- aggte(cs_log_exp, type = "simple")
cat("ATT (log exp PP):\n")
summary(agg_log_exp)

es_log_exp <- aggte(cs_log_exp, type = "dynamic", min_e = -6, max_e = 8)

## ──────────────────────────────────────────────────
## 3. Heterogeneity: Earmark vs No-Earmark states
## ──────────────────────────────────────────────────

cat("\n=== Heterogeneity: Earmark Education States ===\n")

# Earmark states: CO, OR, NV, IL, MI, VT, MD
earmark_states <- panel %>%
  filter(earmark_education == TRUE) %>%
  pull(state_abbr) %>%
  unique()
cat("Earmark states:", paste(earmark_states, collapse = ", "), "\n")

panel_earmark <- panel %>%
  filter(earmark_education == TRUE | treatment_year == 0)

cs_earmark <- att_gt(
  yname = "exp_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel_earmark %>% filter(!is.na(exp_pp)),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_earmark <- aggte(cs_earmark, type = "simple")
cat("ATT (earmark states only):\n")
summary(agg_earmark)

cat("\n=== Heterogeneity: No-Earmark States (Placebo) ===\n")

no_earmark_states <- panel %>%
  filter(treatment_year > 0 & earmark_education == FALSE) %>%
  pull(state_abbr) %>%
  unique()
cat("No-earmark states:", paste(no_earmark_states, collapse = ", "), "\n")

panel_no_earmark <- panel %>%
  filter(earmark_education == FALSE | treatment_year == 0) %>%
  # Remove earmark states from treated set
  filter(!(state_abbr %in% earmark_states & treatment_year > 0))

cs_no_earmark <- att_gt(
  yname = "exp_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel_no_earmark %>% filter(!is.na(exp_pp)),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_no_earmark <- aggte(cs_no_earmark, type = "simple")
cat("ATT (no-earmark states only):\n")
summary(agg_no_earmark)

## ──────────────────────────────────────────────────
## 4. Capital outlay per pupil (mechanism check)
## ──────────────────────────────────────────────────

cat("\n=== Mechanism: Capital Outlay Per Pupil ===\n")

cs_cap <- att_gt(
  yname = "cap_exp_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel %>% filter(!is.na(cap_exp_pp)),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_cap <- aggte(cs_cap, type = "simple")
cat("ATT (capital outlay PP):\n")
summary(agg_cap)

## ──────────────────────────────────────────────────
## 5. Exclude early COVID years (2020-2021) — CARES Act confound
## ──────────────────────────────────────────────────

cat("\n=== Robustness: Exclude 2020-2021 ===\n")

panel_no_covid <- panel %>% filter(!(year %in% c(2020, 2021)))

cs_exp_no_covid <- att_gt(
  yname = "exp_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel_no_covid %>% filter(!is.na(exp_pp), treatment_year < 2020 | treatment_year == 0),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_exp_no_covid <- aggte(cs_exp_no_covid, type = "simple")
cat("ATT (excl. 2020-2021, pre-COVID cohorts only):\n")
summary(agg_exp_no_covid)

## ──────────────────────────────────────────────────
## 6. Fungibility rate calculation
## ──────────────────────────────────────────────────

cat("\n=== Fungibility Rate ===\n")

# For earmark states with marijuana revenue data, compute:
# Fungibility Rate = 1 - (ATT_exp / avg_mj_rev_pp)
# If FR = 1: full passthrough (no fungibility)
# If FR = 0: zero passthrough (complete fungibility)

mj_rev_summary <- panel %>%
  filter(treatment_year > 0, post == TRUE, !is.na(mj_rev_pp), mj_rev_pp > 0) %>%
  group_by(earmark_education) %>%
  summarise(
    n_state_years = n(),
    mean_mj_rev_pp = mean(mj_rev_pp, na.rm = TRUE),
    sd_mj_rev_pp = sd(mj_rev_pp, na.rm = TRUE),
    .groups = "drop"
  )

cat("Marijuana revenue per pupil (post-treatment periods with data):\n")
print(mj_rev_summary)

# Average MJ revenue per pupil across all treated states
avg_mj_rev_pp <- panel %>%
  filter(treatment_year > 0, post == TRUE, !is.na(mj_rev_pp), mj_rev_pp > 0) %>%
  summarise(mean = mean(mj_rev_pp)) %>%
  pull(mean)

cat(sprintf("\nAvg marijuana rev per pupil (all treated): $%.0f\n", avg_mj_rev_pp))

# Point estimate of fungibility rate
# ATT of total expenditure PP / avg MJ revenue PP
att_val <- agg_exp_no_ak$overall.att  # use no-Alaska estimate
se_val <- agg_exp_no_ak$overall.se

passthrough_rate <- att_val / avg_mj_rev_pp
passthrough_se <- se_val / avg_mj_rev_pp

cat(sprintf("Passthrough rate: %.2f (SE: %.2f)\n", passthrough_rate, passthrough_se))
cat(sprintf("Fungibility rate: %.2f\n", 1 - passthrough_rate))
cat(sprintf("95%% CI for passthrough: [%.2f, %.2f]\n",
            passthrough_rate - 1.96 * passthrough_se,
            passthrough_rate + 1.96 * passthrough_se))

## ──────────────────────────────────────────────────
## 7. Save all robustness results
## ──────────────────────────────────────────────────

robustness <- list(
  agg_exp_no_ak = agg_exp_no_ak,
  agg_log_exp = agg_log_exp,
  es_log_exp = es_log_exp,
  agg_earmark = agg_earmark,
  agg_no_earmark = agg_no_earmark,
  agg_cap = agg_cap,
  agg_exp_no_covid = agg_exp_no_covid,
  avg_mj_rev_pp = avg_mj_rev_pp,
  passthrough_rate = passthrough_rate,
  passthrough_se = passthrough_se
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness analysis complete ===\n")
