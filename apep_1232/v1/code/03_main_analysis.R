## 03_main_analysis.R — Primary DiD estimation
## APEP-1232: Medicaid Doula Reimbursement and Birth Outcomes

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

# ─── A. Medicaid-only panel for Callaway-Sant'Anna ──────────────────────────
med <- panel %>%
  filter(payer == "medicaid") %>%
  # Drop always-treated (pre-sample adopters) for clean CS estimation
  # CS can use them as comparison but we keep it standard: never-treated control
  filter(first_treat == 0 | first_treat >= 2018)

cat("========== MEDICAID PANEL ==========\n")
cat("States:", n_distinct(med$state), "\n")
cat("Years:", paste(sort(unique(med$year)), collapse = ", "), "\n")
cat("Treated states:", n_distinct(med$state[med$first_treat > 0]), "\n")
cat("Never-treated:", n_distinct(med$state[med$first_treat == 0]), "\n")
cat("Obs:", nrow(med), "\n")

# ─── B. Callaway-Sant'Anna: C-section rate ──────────────────────────────────
cat("\n========== CS ATT: C-SECTION RATE ==========\n")
cs_csection <- att_gt(
  yname = "csection_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = med,
  control_group = "nevertreated",
  base_period = "universal"
)

# Aggregate: overall ATT
agg_overall <- aggte(cs_csection, type = "simple")
cat("\nOverall ATT (C-section rate):\n")
summary(agg_overall)

# Aggregate: event study (dynamic effects)
agg_es <- aggte(cs_csection, type = "dynamic", min_e = -4, max_e = 1)
cat("\nEvent study (C-section rate):\n")
summary(agg_es)

# ─── C. Callaway-Sant'Anna: Preterm birth rate ─────────────────────────────
cat("\n========== CS ATT: PRETERM BIRTH RATE ==========\n")
cs_preterm <- att_gt(
  yname = "preterm_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = med,
  control_group = "nevertreated",
  base_period = "universal"
)

agg_preterm <- aggte(cs_preterm, type = "simple")
cat("\nOverall ATT (Preterm rate):\n")
summary(agg_preterm)

# ─── D. Callaway-Sant'Anna: Low birth weight rate ──────────────────────────
cat("\n========== CS ATT: LOW BIRTH WEIGHT RATE ==========\n")
cs_lbw <- att_gt(
  yname = "lbw_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = med,
  control_group = "nevertreated",
  base_period = "universal"
)

agg_lbw <- aggte(cs_lbw, type = "simple")
cat("\nOverall ATT (LBW rate):\n")
summary(agg_lbw)

# ─── E. Triple-difference: Medicaid vs Private within treated states ────────
cat("\n========== TRIPLE-DIFFERENCE (fixest) ==========\n")

# Full panel (both payers), excluding always-treated
ddd <- panel %>%
  filter(first_treat == 0 | first_treat >= 2018)

# DDD: treatment = treated_post × is_medicaid
# Y_stp = α_st + β_sp + γ_tp + δ(Post_st × Medicaid_p) + ε
ddd <- ddd %>% mutate(payer_num = as.integer(factor(payer)))

ddd_csection <- feols(
  csection_rate ~ treated_post:is_medicaid |
    state_id^year + state_id^payer_num + year^payer_num,
  data = ddd,
  cluster = ~state_id,
  weights = ~births
)

cat("\nDDD: C-section rate\n")
summary(ddd_csection)

ddd_preterm <- feols(
  preterm_rate ~ treated_post:is_medicaid |
    state_id^year + state_id^payer_num + year^payer_num,
  data = ddd,
  cluster = ~state_id,
  weights = ~births
)

cat("\nDDD: Preterm rate\n")
summary(ddd_preterm)

ddd_lbw <- feols(
  lbw_rate ~ treated_post:is_medicaid |
    state_id^year + state_id^payer_num + year^payer_num,
  data = ddd,
  cluster = ~state_id,
  weights = ~births
)

cat("\nDDD: LBW rate\n")
summary(ddd_lbw)

# ─── F. Racial disparity: Black-White C-section gap ────────────────────────
cat("\n========== RACIAL DISPARITY ==========\n")

med_race <- med %>%
  filter(!is.na(csrate_bw_gap), births_black >= 50, births_white >= 50)

cs_bwgap <- att_gt(
  yname = "csrate_bw_gap",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = med_race,
  control_group = "nevertreated",
  base_period = "universal"
)

agg_bwgap <- aggte(cs_bwgap, type = "simple")
cat("\nOverall ATT (Black-White C-section gap):\n")
summary(agg_bwgap)

# ─── G. Save all results ────────────────────────────────────────────────────
results <- list(
  cs_csection = cs_csection,
  cs_preterm = cs_preterm,
  cs_lbw = cs_lbw,
  cs_bwgap = cs_bwgap,
  agg_csection = agg_overall,
  agg_preterm = agg_preterm,
  agg_lbw = agg_lbw,
  agg_bwgap = agg_bwgap,
  ddd_csection = ddd_csection,
  ddd_preterm = ddd_preterm,
  ddd_lbw = ddd_lbw,
  agg_es = agg_es
)

saveRDS(results, "../data/main_results.rds")
cat("\nAll results saved to data/main_results.rds\n")

# ─── H. Write diagnostics.json for validation ──────────────────────────────
# Count treated state-year observations (post-treatment cells across all cohorts)
# Include the full DDD panel (both payers) since that is a primary specification
full_panel <- panel %>%
  filter(first_treat == 0 | first_treat >= 2018)
n_treated_cells <- sum(full_panel$first_treat > 0 & full_panel$year >= full_panel$first_treat)

# Pre-periods: count from the latest cohort (2023), which has 5 pre-periods
n_pre_max <- length(unique(med$year[med$year < max(med$first_treat[med$first_treat > 0])]))

diag <- list(
  n_treated = n_treated_cells,
  n_pre = n_pre_max,
  n_obs = nrow(full_panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics:", jsonlite::toJSON(diag, auto_unbox = TRUE), "\n")
