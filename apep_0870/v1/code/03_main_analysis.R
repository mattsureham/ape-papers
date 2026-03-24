# 03_main_analysis.R — Primary regressions
# apep_0870: Upload Filter Tax

source("code/00_packages.R")

df <- fread("data/panel_csdid.csv")

message("Panel: ", nrow(df), " obs, ", uniqueN(df$geo), " regions, ",
        min(df$year), "-", max(df$year))

# ============================================================================
# 1. CALLAWAY & SANT'ANNA (2021) — Main specification
# ============================================================================

message("\n=== Callaway & Sant'Anna DiD ===")

# Main outcome: log NACE J employment
cs_main <- att_gt(
  yname  = "log_emp_j",
  tname  = "year",
  idname = "id",
  gname  = "group",
  data   = as.data.frame(df),
  control_group = "notyettreated",
  anticipation  = 0,
  base_period   = "universal",
  bstrap = TRUE,
  cband  = TRUE,
  biters = 1000
)

message("CS-DiD group-time ATTs estimated:")
print(summary(cs_main))

# Aggregate to overall ATT
cs_agg <- aggte(cs_main, type = "simple")
message("\nOverall ATT:")
print(summary(cs_agg))

# Event study aggregation
cs_event <- aggte(cs_main, type = "dynamic", min_e = -5, max_e = 3)
message("\nEvent study ATTs:")
print(summary(cs_event))

# Save for tables
save(cs_main, cs_agg, cs_event, file = "data/cs_results.RData")

# ============================================================================
# 2. TWFE — Benchmark (for comparison)
# ============================================================================

message("\n=== TWFE Benchmark ===")

twfe_main <- feols(
  log_emp_j ~ treated | geo + year,
  data = df,
  cluster = ~country
)
message("TWFE main:")
print(summary(twfe_main))

# With controls
twfe_ctrl <- feols(
  log_emp_j ~ treated + log(population) + log(gdp_pc + 1) | geo + year,
  data = df[!is.na(gdp_pc) & gdp_pc > 0 & population > 0],
  cluster = ~country
)
message("\nTWFE with controls:")
print(summary(twfe_ctrl))

# ============================================================================
# 3. EMPLOYMENT SHARE — Alternative outcome
# ============================================================================

message("\n=== Employment Share Outcome ===")

cs_share <- att_gt(
  yname  = "share_j",
  tname  = "year",
  idname = "id",
  gname  = "group",
  data   = as.data.frame(df[!is.na(share_j)]),
  control_group = "notyettreated",
  anticipation  = 0,
  base_period   = "universal",
  bstrap = TRUE,
  cband  = TRUE,
  biters = 1000
)

cs_share_agg <- aggte(cs_share, type = "simple")
cs_share_event <- aggte(cs_share, type = "dynamic", min_e = -5, max_e = 3)

message("\nICT Employment Share ATT:")
print(summary(cs_share_agg))

save(cs_share, cs_share_agg, cs_share_event,
     file = "data/cs_share_results.RData")

# ============================================================================
# 4. TRIPLE-DIFFERENCE: NACE J vs NACE K
# ============================================================================

message("\n=== Triple Difference (NACE J vs K) ===")

# Build DDD dataset: region × year × sector
panel_long <- fread("data/panel_long.csv")
ddd <- panel_long[nace %in% c("J", "K")]
ddd[, is_j := as.integer(nace == "J")]
ddd[, post := as.integer(!is.na(transposition_year) & year >= transposition_year)]
ddd[, is_eu := as.integer(!country %in% c("NO", "CH", "IS"))]

# DDD: region FE + year FE + sector FE + interactions
ddd_est <- feols(
  log_emp ~ is_j:post:is_eu + is_j:post + is_j:is_eu + post:is_eu |
    geo^nace + year^nace,
  data = ddd,
  cluster = ~country
)
message("\nDDD (NACE J vs K, EU vs EEA, pre vs post):")
print(summary(ddd_est))

save(twfe_main, twfe_ctrl, ddd_est, file = "data/twfe_results.RData")

# ============================================================================
# 5. DIAGNOSTICS
# ============================================================================

n_treated <- uniqueN(df[group > 0, id])
n_pre <- uniqueN(df[year < min(df[group > 0, group]), year])
n_obs <- nrow(df)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_regions = uniqueN(df$geo),
  n_countries = uniqueN(df$country),
  cs_att = cs_agg$overall.att,
  cs_se = cs_agg$overall.se,
  twfe_coef = coef(twfe_main)["treated"],
  twfe_se = sqrt(vcov(twfe_main)["treated", "treated"]),
  ddd_coef = coef(ddd_est)[grep("is_j:post:is_eu", names(coef(ddd_est)))],
  sd_y_pre = sd(df[group == 0 | year < group, log_emp_j], na.rm = TRUE)
)

jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
message("\nDiagnostics saved to data/diagnostics.json")
message("  n_treated: ", diagnostics$n_treated)
message("  n_pre: ", diagnostics$n_pre)
message("  n_obs: ", diagnostics$n_obs)
message("  CS-DiD ATT: ", round(diagnostics$cs_att, 4),
        " (SE: ", round(diagnostics$cs_se, 4), ")")

message("\n=== Main analysis complete ===")
