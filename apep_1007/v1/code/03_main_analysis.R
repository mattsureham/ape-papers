## 03_main_analysis.R — Callaway-Sant'Anna DiD + TWFE event studies
## apep_1007: Banking the Unbanked by Mandate

source("00_packages.R")

cat("=== Loading analysis panels ===\n")

# Primary outcome: Internet banking
panel <- fread("../data/panel_internet_banking.csv")
cat("Internet banking panel:", nrow(panel), "obs,",
    uniqueN(panel$country_code), "countries,",
    uniqueN(panel$year), "years\n")

# Check treatment group distribution
cat("\n--- Treatment groups ---\n")
panel[, .(countries = paste(unique(country_code), collapse = ", "),
          n_countries = uniqueN(country_code)),
      by = group][order(group)] |> print()

# ------------------------------------------------------------------
# 1. CALLAWAY-SANT'ANNA GROUP-TIME ATT
# ------------------------------------------------------------------
cat("\n=== 1. Callaway-Sant'Anna ATT ===\n")

# Ensure proper types
panel[, year := as.integer(year)]
panel[, group := as.integer(group)]
panel[, country_id := as.integer(country_id)]

# CS-DiD with not-yet-treated + never-treated as comparison
cs_out <- att_gt(
  yname = "internet_banking_pct",
  tname = "year",
  idname = "country_id",
  gname = "group",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",  # doubly robust
  base_period = "varying",
  clustervars = "country_id",
  print_details = FALSE
)

cat("CS-DiD estimated. Number of group-time ATTs:", length(cs_out$att), "\n")

# Aggregate to dynamic event study
cs_es <- aggte(cs_out, type = "dynamic", min_e = -5, max_e = 7, na.rm = TRUE)
cat("\nDynamic ATT (event study):\n")
summary(cs_es)

# Aggregate to overall ATT
cs_overall <- aggte(cs_out, type = "group", na.rm = TRUE)
cat("\nOverall ATT by group:\n")
summary(cs_overall)

# Simple overall
cs_simple <- aggte(cs_out, type = "simple", na.rm = TRUE)
cat("\nSimple ATT:\n")
summary(cs_simple)

# Save CS results
saveRDS(cs_out, "../data/cs_results.rds")
saveRDS(cs_es, "../data/cs_event_study.rds")
saveRDS(cs_simple, "../data/cs_simple.rds")

# ------------------------------------------------------------------
# 2. TWFE (for comparison — expected to show heterogeneity bias)
# ------------------------------------------------------------------
cat("\n=== 2. TWFE Comparison ===\n")

twfe_main <- feols(internet_banking_pct ~ treated | country_id + year,
                    data = panel, cluster = ~country_id)
cat("TWFE coefficient:", coef(twfe_main)["treated"],
    "SE:", sqrt(vcov(twfe_main)["treated", "treated"]), "\n")

# Sun-Abraham for comparison
panel[, cohort := fifelse(group == 0, 10000L, group)]  # large number for never-treated
sa_main <- feols(internet_banking_pct ~ sunab(cohort, year) | country_id + year,
                  data = panel, cluster = ~country_id)
cat("\nSun-Abraham results:\n")
summary(sa_main)

# ------------------------------------------------------------------
# 3. TWFE EVENT STUDY (relative time indicators)
# ------------------------------------------------------------------
cat("\n=== 3. TWFE Event Study ===\n")

# Relative time to treatment
panel[group > 0, rel_time := year - group]
panel[group == 0, rel_time := NA_integer_]

# Bin endpoints
panel[!is.na(rel_time) & rel_time < -5, rel_time_binned := -5L]
panel[!is.na(rel_time) & rel_time > 7, rel_time_binned := 7L]
panel[!is.na(rel_time) & rel_time >= -5 & rel_time <= 7, rel_time_binned := rel_time]
panel[is.na(rel_time), rel_time_binned := NA_integer_]

# TWFE event study (omitting t = -1)
twfe_es <- feols(internet_banking_pct ~ i(rel_time_binned, ref = -1) |
                   country_id + year,
                  data = panel[!is.na(rel_time_binned)],
                  cluster = ~country_id)
cat("TWFE event study:\n")
summary(twfe_es)

saveRDS(twfe_es, "../data/twfe_event_study.rds")

# ------------------------------------------------------------------
# 4. FINDEX ANALYSIS (sparse panel)
# ------------------------------------------------------------------
cat("\n=== 4. Global Findex Analysis ===\n")

findex_panel <- fread("../data/panel_findex.csv")
cat("Findex panel:", nrow(findex_panel), "obs,",
    uniqueN(findex_panel$country_code), "countries\n")

# Simple TWFE on Findex (CS-DiD needs more periods for meaningful event study)
findex_twfe <- feols(account_pct ~ treated | country_id + year,
                      data = findex_panel, cluster = ~country_id)
cat("Findex TWFE:", coef(findex_twfe)["treated"],
    "SE:", sqrt(vcov(findex_twfe)["treated", "treated"]), "\n")

# CS-DiD on Findex
findex_panel[, year := as.integer(year)]
findex_panel[, group := as.integer(group)]

cs_findex <- tryCatch({
  att_gt(
    yname = "account_pct",
    tname = "year",
    idname = "country_id",
    gname = "group",
    data = as.data.frame(findex_panel),
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "varying",
    clustervars = "country_id",
    print_details = FALSE
  )
}, error = function(e) {
  cat("  CS-DiD on Findex failed (sparse panel):", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_findex)) {
  cs_findex_simple <- aggte(cs_findex, type = "simple", na.rm = TRUE)
  cat("Findex CS-DiD simple ATT:\n")
  summary(cs_findex_simple)
  saveRDS(cs_findex, "../data/cs_findex.rds")
}

# ------------------------------------------------------------------
# 5. FINANCIAL HARDSHIP ANALYSIS
# ------------------------------------------------------------------
cat("\n=== 5. Financial Hardship (Mechanism) ===\n")

if (file.exists("../data/panel_hardship.csv")) {
  panel_hard <- fread("../data/panel_hardship.csv")
  hard_twfe <- feols(unable_expense_pct ~ treated | country_id + year,
                      data = panel_hard, cluster = ~country_id)
  cat("Hardship TWFE:", coef(hard_twfe)["treated"],
      "SE:", sqrt(vcov(hard_twfe)["treated", "treated"]), "\n")
  saveRDS(hard_twfe, "../data/hardship_twfe.rds")

  # CS-DiD on hardship
  panel_hard[, year := as.integer(year)]
  panel_hard[, group := as.integer(group)]
  cs_hard <- tryCatch({
    att_gt(
      yname = "unable_expense_pct",
      tname = "year",
      idname = "country_id",
      gname = "group",
      data = as.data.frame(panel_hard),
      control_group = "notyettreated",
      anticipation = 0,
      est_method = "dr",
      base_period = "varying",
      clustervars = "country_id",
      print_details = FALSE
    )
  }, error = function(e) {
    cat("  CS-DiD on hardship failed:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(cs_hard)) {
    cs_hard_simple <- aggte(cs_hard, type = "simple", na.rm = TRUE)
    cat("Hardship CS-DiD simple ATT:\n")
    summary(cs_hard_simple)
    saveRDS(cs_hard, "../data/cs_hardship.rds")
  }
}

# ------------------------------------------------------------------
# 6. DIAGNOSTICS
# ------------------------------------------------------------------
cat("\n=== 6. Writing diagnostics ===\n")

n_treated <- uniqueN(panel[group > 0]$country_code)
n_pre <- panel[group > 0, .(n_pre = sum(year < group[1])), by = country_code][, min(n_pre)]
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_countries = uniqueN(panel$country_code),
  n_years = uniqueN(panel$year),
  treatment_years = sort(unique(panel[group > 0]$group)),
  cs_att = cs_simple$overall.att,
  cs_se = cs_simple$overall.se
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics written.\n")
cat("  n_treated:", n_treated, "\n")
cat("  n_pre:", n_pre, "\n")
cat("  n_obs:", n_obs, "\n")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
