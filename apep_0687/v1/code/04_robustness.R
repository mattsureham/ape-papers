## 04_robustness.R — Robustness checks and placebo tests
## Paper: apep_0687 — Nutrient Neutrality and Housing Supply

source("00_packages.R")

df <- readRDS("data/analysis_sample.rds")
cs_out <- readRDS("data/cs_results.rds")

w1_first <- df |> filter(wave == 1, treated == 1) |> pull(qid) |> min()
w2_first <- df |> filter(wave == 2, treated == 1) |> pull(qid) |> min()

# ============================================================
# 1. HONESTDID — SENSITIVITY TO PT VIOLATIONS
# ============================================================
cat("=== HonestDiD Sensitivity Analysis ===\n")

cs_es <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 8)

tryCatch({
  # Relative magnitudes approach
  honest_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
    betahat = cs_es$att.egt,
    sigma = cs_es$se.egt^2 * diag(length(cs_es$se.egt)),
    numPrePeriods = sum(cs_es$egt < 0),
    numPostPeriods = sum(cs_es$egt >= 0),
    Mbarvec = seq(0, 2, by = 0.5)
  )
  cat("HonestDiD relative magnitudes:\n")
  print(honest_rm)
  saveRDS(honest_rm, "data/honest_rm.rds")
}, error = function(e) {
  cat("HonestDiD failed:", conditionMessage(e), "\n")
  cat("Proceeding without sensitivity analysis.\n")
})

# ============================================================
# 2. WAVE-SPECIFIC ESTIMATES
# ============================================================
cat("\n=== Wave-specific TWFE ===\n")

# Wave 1 only (2019 treatment)
df_w1 <- df |> filter(is.na(wave) | wave == 1)
twfe_w1 <- feols(log(apps_decided + 1) ~ treated | lpa_id + qid,
                 data = df_w1, cluster = ~lpa_id)
cat("Wave 1 only:\n")
print(summary(twfe_w1))

# Wave 2 only (2022 treatment)
df_w2 <- df |> filter(is.na(wave) | wave == 2)
twfe_w2 <- feols(log(apps_decided + 1) ~ treated | lpa_id + qid,
                 data = df_w2, cluster = ~lpa_id)
cat("\nWave 2 only:\n")
print(summary(twfe_w2))

# ============================================================
# 3. PLACEBO: APPLICATIONS RECEIVED
# ============================================================
cat("\n=== Placebo: Applications Received ===\n")

# If nutrient neutrality blocks decisions but not applications,
# we'd see a rise in pending/backlog
twfe_received <- feols(log(apps_received + 1) ~ treated | lpa_id + qid,
                       data = df, cluster = ~lpa_id)
cat("Applications received (log):\n")
print(summary(twfe_received))

# Backlog measure: apps at end of quarter
twfe_backlog <- feols(log(apps_end + 1) ~ treated | lpa_id + qid,
                      data = df |> filter(!is.na(apps_end)),
                      cluster = ~lpa_id)
cat("\nApplications backlog (end of quarter, log):\n")
print(summary(twfe_backlog))

# ============================================================
# 4. ALTERNATIVE CONTROL GROUP: NOT-YET-TREATED
# ============================================================
cat("\n=== Not-yet-treated control group ===\n")

cs_nyt <- att_gt(
  yname = "apps_decided",
  tname = "qid",
  idname = "lpa_id",
  gname = "first_treat_q",
  data = as.data.frame(df),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)

cs_att_nyt <- aggte(cs_nyt, type = "simple")
cat("CS-DiD (not-yet-treated controls):\n")
summary(cs_att_nyt)

# ============================================================
# 5. SAMPLE PERIOD SENSITIVITY
# ============================================================
cat("\n=== Sample period sensitivity ===\n")

# Narrower window: 2015-2025
df_narrow <- df |> filter(year >= 2015)
twfe_narrow <- feols(log(apps_decided + 1) ~ treated | lpa_id + qid,
                     data = df_narrow, cluster = ~lpa_id)
cat("Narrow window (2015-2025):\n")
print(summary(twfe_narrow))

# ============================================================
# 6. DISPLACEMENT TEST: NEIGHBORING LPAs
# ============================================================
cat("\n=== Displacement test ===\n")
# Check if applications increased in neighboring control LPAs
# Region-level clustering as alternative inference
region_effects <- feols(
  log(apps_decided + 1) ~ treated | lpa_id + qid,
  data = df,
  cluster = ~region
)
cat("Region-clustered SEs:\n")
print(summary(region_effects))

# ============================================================
# 7. SAVE ALL ROBUSTNESS RESULTS
# ============================================================
saveRDS(twfe_w1, "data/twfe_w1.rds")
saveRDS(twfe_w2, "data/twfe_w2.rds")
saveRDS(twfe_received, "data/twfe_received.rds")
saveRDS(twfe_backlog, "data/twfe_backlog.rds")
saveRDS(cs_att_nyt, "data/cs_att_nyt.rds")
saveRDS(twfe_narrow, "data/twfe_narrow.rds")

cat("\nRobustness checks complete.\n")
