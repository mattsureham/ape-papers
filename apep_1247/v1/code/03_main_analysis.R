# =============================================================================
# 03_main_analysis.R — Main Bartik estimates: ARRA Pell and racial enrollment
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
setDT(panel)

# ---- 1. Static DiD: Bartik dose × Post ----
message("=== Static Bartik DiD ===")

# Primary spec: log enrollment ~ PellShare × Post | institution + year FE
# Cluster SEs at institution level

# Black enrollment
static_black <- feols(log_enroll_black ~ pre_pell_share:post | unitid + year,
                      data = panel, cluster = ~unitid)

# Hispanic enrollment
static_hisp <- feols(log_enroll_hisp ~ pre_pell_share:post | unitid + year,
                     data = panel, cluster = ~unitid)

# White enrollment (placebo)
static_white <- feols(log_enroll_white ~ pre_pell_share:post | unitid + year,
                      data = panel, cluster = ~unitid)

# Total enrollment
static_total <- feols(log_enroll_total ~ pre_pell_share:post | unitid + year,
                      data = panel, cluster = ~unitid)

message("\n--- Black enrollment ---")
print(summary(static_black))
message("\n--- Hispanic enrollment ---")
print(summary(static_hisp))
message("\n--- White enrollment (placebo) ---")
print(summary(static_white))
message("\n--- Total enrollment ---")
print(summary(static_total))

# ---- 2. Event study: Bartik dose × year indicators ----
message("\n=== Event Study ===")

# Create event time relative to 2008 (last pre-treatment year)
panel[, event_time := year - 2008]

# Event study: interact Pell share with year dummies
# Omit 2008 (event_time = 0) as base period
es_black <- feols(log_enroll_black ~ i(event_time, pre_pell_share, ref = 0) | unitid + year,
                  data = panel, cluster = ~unitid)

es_hisp <- feols(log_enroll_hisp ~ i(event_time, pre_pell_share, ref = 0) | unitid + year,
                 data = panel, cluster = ~unitid)

es_white <- feols(log_enroll_white ~ i(event_time, pre_pell_share, ref = 0) | unitid + year,
                  data = panel, cluster = ~unitid)

es_total <- feols(log_enroll_total ~ i(event_time, pre_pell_share, ref = 0) | unitid + year,
                  data = panel, cluster = ~unitid)

message("\n--- Event study: Black ---")
print(summary(es_black))
message("\n--- Event study: White (placebo) ---")
print(summary(es_white))

# ---- 3. ARRA active vs phase-out ----
message("\n=== Active vs Phase-out ===")

# Separate ARRA active period (2009-2011) from phase-out (2012+)
active_black <- feols(log_enroll_black ~ pre_pell_share:arra_active +
                        pre_pell_share:arra_phaseout | unitid + year,
                      data = panel, cluster = ~unitid)

active_hisp <- feols(log_enroll_hisp ~ pre_pell_share:arra_active +
                       pre_pell_share:arra_phaseout | unitid + year,
                     data = panel, cluster = ~unitid)

active_white <- feols(log_enroll_white ~ pre_pell_share:arra_active +
                        pre_pell_share:arra_phaseout | unitid + year,
                      data = panel, cluster = ~unitid)

message("\n--- Active vs Phase-out: Black ---")
print(summary(active_black))

# ---- 4. Racial share outcomes ----
message("\n=== Racial Share Outcomes ===")

share_black <- feols(black_share ~ pre_pell_share:post | unitid + year,
                     data = panel, cluster = ~unitid)
share_hisp <- feols(hisp_share ~ pre_pell_share:post | unitid + year,
                    data = panel, cluster = ~unitid)
share_white <- feols(white_share ~ pre_pell_share:post | unitid + year,
                     data = panel, cluster = ~unitid)

message("\n--- Black share ---")
print(summary(share_black))
message("\n--- Hispanic share ---")
print(summary(share_hisp))
message("\n--- White share ---")
print(summary(share_white))

# ---- 5. Save results ----
results <- list(
  static_black = static_black,
  static_hisp = static_hisp,
  static_white = static_white,
  static_total = static_total,
  es_black = es_black,
  es_hisp = es_hisp,
  es_white = es_white,
  es_total = es_total,
  active_black = active_black,
  active_hisp = active_hisp,
  active_white = active_white,
  share_black = share_black,
  share_hisp = share_hisp,
  share_white = share_white
)
saveRDS(results, "../data/main_results.rds")

# ---- 6. Diagnostics ----
jsonlite::write_json(list(
  n_treated = uniqueN(panel[pre_pell_share > median(panel$pre_pell_share, na.rm = TRUE), unitid]),
  n_pre = length(unique(panel$year[panel$year < 2009])),
  n_obs = nrow(panel),
  n_institutions = uniqueN(panel$unitid),
  mean_pre_pell_share = round(mean(panel$pre_pell_share, na.rm = TRUE), 4),
  sd_pre_pell_share = round(sd(panel$pre_pell_share, na.rm = TRUE), 4),
  outcome_sd_black = round(sd(panel$log_enroll_black, na.rm = TRUE), 4),
  outcome_sd_hisp = round(sd(panel$log_enroll_hisp, na.rm = TRUE), 4),
  outcome_sd_white = round(sd(panel$log_enroll_white, na.rm = TRUE), 4)
), "../data/diagnostics.json", auto_unbox = TRUE)

message("\nResults and diagnostics saved.")
