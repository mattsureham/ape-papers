## 03_main_analysis.R — Main DiD analysis
## Paper: apep_0687 — Nutrient Neutrality and Housing Supply

source("00_packages.R")

panel <- readRDS("data/panel_quarterly.rds")
annual <- readRDS("data/panel_annual.rds")

cat("Panel: ", nrow(panel), " obs, ", n_distinct(panel$lpa_name), " LPAs\n")
cat("Treated: ", sum(panel$treated_ever & !duplicated(panel$lpa_name)), "\n")

# ============================================================
# 1. RESTRICT SAMPLE & PREPARE VARIABLES
# ============================================================
# Focus on 2010-2025 to have a tractable panel with consistent LA boundaries
# This gives 9+ years pre-Wave 1 and 12+ years pre-Wave 2

df <- panel |>
  filter(year >= 2010, year <= 2025) |>
  # Create LPA numeric ID
  mutate(lpa_id = as.integer(factor(lpa_name))) |>
  # Log outcomes (add 1 to handle zeros)
  mutate(
    log_decided = log(apps_decided + 1),
    log_received = log(apps_received + 1)
  )

# Create first_treat variable for Callaway-Sant'Anna
# CS-DiD needs: first_treat = first period of treatment (0 for never-treated)
# Our time variable is qid (quarter ID from 1996Q1)
df <- df |>
  mutate(
    first_treat_q = case_when(
      is.na(wave) ~ 0L,     # Never treated
      wave == 1 ~ as.integer(min(qid[wave == 1 & treated == 1], na.rm = TRUE)),
      wave == 2 ~ as.integer(min(qid[wave == 2 & treated == 1], na.rm = TRUE))
    )
  )

# Recompute first_treat correctly per group
w1_first <- df |> filter(wave == 1, treated == 1) |> pull(qid) |> min()
w2_first <- df |> filter(wave == 2, treated == 1) |> pull(qid) |> min()
cat("Wave 1 first treated quarter (qid):", w1_first, "\n")
cat("Wave 2 first treated quarter (qid):", w2_first, "\n")

df <- df |>
  mutate(
    first_treat_q = case_when(
      is.na(wave) ~ 0L,
      wave == 1 ~ as.integer(w1_first),
      wave == 2 ~ as.integer(w2_first)
    )
  )

cat("Sample: ", nrow(df), " obs, ", n_distinct(df$lpa_name), " LPAs\n")
cat("  Wave 1 LPAs:", n_distinct(df$lpa_name[df$wave == 1 & !is.na(df$wave)]), "\n")
cat("  Wave 2 LPAs:", n_distinct(df$lpa_name[df$wave == 2 & !is.na(df$wave)]), "\n")
cat("  Control LPAs:", n_distinct(df$lpa_name[is.na(df$wave)]), "\n")

# ============================================================
# 2. CALLAWAY-SANT'ANNA STAGGERED DiD
# ============================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")

cs_out <- att_gt(
  yname = "apps_decided",
  tname = "qid",
  idname = "lpa_id",
  gname = "first_treat_q",
  data = as.data.frame(df),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

cat("CS-DiD complete.\n")

# Aggregate to ATT
cs_att <- aggte(cs_out, type = "simple")
cat("\nOverall ATT:\n")
summary(cs_att)

# Dynamic/event study aggregation
cs_es <- aggte(cs_out, type = "dynamic", min_e = -12, max_e = 12)
cat("\nEvent study aggregation:\n")
summary(cs_es)

# ============================================================
# 3. TWFE EVENT STUDY (fixest)
# ============================================================
cat("\n=== TWFE Event Study (fixest) ===\n")

# Create relative time to treatment
df <- df |>
  mutate(
    rel_time = case_when(
      is.na(wave) ~ NA_integer_,
      wave == 1 ~ qid - w1_first,
      wave == 2 ~ qid - w2_first
    )
  )

# Sun-Abraham decomposition using sunab()
sa_model <- feols(
  apps_decided ~ sunab(first_treat_q, qid) | lpa_id + qid,
  data = df |> filter(first_treat_q > 0 | first_treat_q == 0),
  cluster = ~lpa_id
)

cat("Sun-Abraham model:\n")
print(summary(sa_model))

# Simple TWFE for comparison
twfe_model <- feols(
  apps_decided ~ treated | lpa_id + qid,
  data = df,
  cluster = ~lpa_id
)

cat("\nSimple TWFE:\n")
print(summary(twfe_model))

# ============================================================
# 4. LOG SPECIFICATION
# ============================================================
cat("\n=== Log specification ===\n")

twfe_log <- feols(
  log_decided ~ treated | lpa_id + qid,
  data = df,
  cluster = ~lpa_id
)

cat("Log TWFE:\n")
print(summary(twfe_log))

# ============================================================
# 5. ANNUAL ANALYSIS — NET ADDITIONAL DWELLINGS
# ============================================================
cat("\n=== Annual: Net Additional Dwellings ===\n")

annual_df <- annual |>
  filter(year >= 2010, year <= 2024) |>
  filter(!is.na(net_additions)) |>
  mutate(
    lpa_id = as.integer(factor(lpa_name)),
    log_additions = log(net_additions + 1)
  )

if (nrow(annual_df) > 0 && sum(annual_df$treated) > 0) {
  twfe_dwellings <- feols(
    net_additions ~ treated | lpa_id + year,
    data = annual_df,
    cluster = ~lpa_id
  )
  cat("Net additions TWFE:\n")
  print(summary(twfe_dwellings))

  twfe_dwellings_log <- feols(
    log_additions ~ treated | lpa_id + year,
    data = annual_df,
    cluster = ~lpa_id
  )
  cat("\nLog net additions TWFE:\n")
  print(summary(twfe_dwellings_log))

  saveRDS(twfe_dwellings, "data/twfe_dwellings.rds")
  saveRDS(twfe_dwellings_log, "data/twfe_dwellings_log.rds")
} else {
  cat("  No annual data with treatment variation — skipping.\n")
}

# ============================================================
# 6. SAVE RESULTS
# ============================================================
saveRDS(cs_out, "data/cs_results.rds")
saveRDS(cs_att, "data/cs_att.rds")
saveRDS(cs_es, "data/cs_es.rds")
saveRDS(sa_model, "data/sa_model.rds")
saveRDS(twfe_model, "data/twfe_model.rds")
saveRDS(twfe_log, "data/twfe_log.rds")
saveRDS(df, "data/analysis_sample.rds")

# Write diagnostics.json for validator
n_treated_units <- n_distinct(df$lpa_name[df$treated_ever])
n_pre_w1 <- length(unique(df$qid[df$qid < w1_first & df$year >= 2010]))
n_obs <- nrow(df)

diag <- list(
  n_treated = n_treated_units,
  n_pre = n_pre_w1,
  n_obs = n_obs
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics:\n")
cat("  n_treated:", n_treated_units, "\n")
cat("  n_pre (quarters before Wave 1):", n_pre_w1, "\n")
cat("  n_obs:", n_obs, "\n")

cat("\nMain analysis complete. Results saved to data/\n")
