# ==============================================================================
# 03_main_analysis.R — Primary DiD Estimation
# APEP-0546: Do Red Flag Laws Save Lives or Shift Deaths?
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

# ─── Load panels ────────────────────────────────────────────────────────────

panel <- fread(file.path(data_dir, "panel_combined.csv"))
short <- fread(file.path(data_dir, "panel_short_2019_2024.csv"))

# ─── A. CALLAWAY-SANT'ANNA: Total Suicide Rate (Combined Panel) ─────────────

cat("=== A. CS-DiD: Total Suicide Rate (1999-2024) ===\n")

# Prepare data for did::att_gt()
# Remove 2018 (gap year) — CS-DiD handles unbalanced panels
cs_data <- panel[year != 2018]

# Exclude CT (erpo_year = 1999 = panel start, no pre-periods)
cs_data_main <- cs_data[!(state == "Connecticut")]

# Verify panel structure
cat("  Panel: ", uniqueN(cs_data_main$state), " states, ",
    uniqueN(cs_data_main$year), " years\n")
cat("  Treated cohorts:\n")
print(cs_data_main[G > 0, .(states = uniqueN(state)), by = G][order(G)])

# CS-DiD with never-treated as comparison group
cs_total <- att_gt(
  yname = "rate_All_Suicide",
  tname = "year",
  idname = "state_id",
  gname = "G",
  data = as.data.frame(cs_data_main),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

cat("\nGroup-time ATTs:\n")
print(summary(cs_total))

# Aggregate: overall ATT
agg_total <- aggte(cs_total, type = "simple")
cat("\nOverall ATT (Total Suicide Rate):\n")
print(summary(agg_total))

# Aggregate: event study
es_total <- aggte(cs_total, type = "dynamic", min_e = -8, max_e = 6)
cat("\nEvent Study (Total Suicide Rate):\n")
print(summary(es_total))

# Save results
saveRDS(cs_total, file.path(data_dir, "cs_total_suicide.rds"))
saveRDS(agg_total, file.path(data_dir, "agg_total_suicide.rds"))
saveRDS(es_total, file.path(data_dir, "es_total_suicide.rds"))

# ─── B. CS-DiD: Firearm Suicide Rate (Short Panel 2019-2024) ────────────────

cat("\n=== B. CS-DiD: Firearm Suicide Rate (2019-2024) ===\n")

# Only states newly treated in 2019-2024 panel
# Exclude states already treated before 2019 (always-treated in this panel)
short_clean <- copy(short)
short_clean[erpo_year < 2019, G := 0L]  # Treat pre-2019 adopters as always-treated → exclude
short_clean[erpo_year < 2019, treated := 0L]

# Remove always-treated states entirely (they muddy CS-DiD)
short_cs <- short_clean[!(erpo_year < 2019 & !is.na(erpo_year))]

cat("  Short panel: ", uniqueN(short_cs$state), " states, ",
    uniqueN(short_cs$year), " years\n")
cat("  Newly treated in short panel:\n")
print(short_cs[G > 0, .(states = uniqueN(state)), by = G][order(G)])

cs_fa <- att_gt(
  yname = "rate_FA_Suicide",
  tname = "year",
  idname = "state_id",
  gname = "G",
  data = as.data.frame(short_cs),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_fa <- aggte(cs_fa, type = "simple")
cat("\nOverall ATT (Firearm Suicide Rate):\n")
print(summary(agg_fa))

es_fa <- aggte(cs_fa, type = "dynamic", min_e = -4, max_e = 4)

saveRDS(cs_fa, file.path(data_dir, "cs_fa_suicide.rds"))
saveRDS(agg_fa, file.path(data_dir, "agg_fa_suicide.rds"))
saveRDS(es_fa, file.path(data_dir, "es_fa_suicide.rds"))

# ─── C. CS-DiD: Non-Firearm Suicide Rate (Substitution Test) ────────────────

cat("\n=== C. CS-DiD: Non-Firearm Suicide Rate (2019-2024) ===\n")

cs_nf <- att_gt(
  yname = "rate_NF_Suicide",
  tname = "year",
  idname = "state_id",
  gname = "G",
  data = as.data.frame(short_cs),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_nf <- aggte(cs_nf, type = "simple")
cat("\nOverall ATT (Non-Firearm Suicide Rate — Substitution Test):\n")
print(summary(agg_nf))

es_nf <- aggte(cs_nf, type = "dynamic", min_e = -4, max_e = 4)

saveRDS(cs_nf, file.path(data_dir, "cs_nf_suicide.rds"))
saveRDS(agg_nf, file.path(data_dir, "agg_nf_suicide.rds"))
saveRDS(es_nf, file.path(data_dir, "es_nf_suicide.rds"))

# ─── D. Placebo: Drug Overdose Deaths ───────────────────────────────────────

cat("\n=== D. Placebo: Drug Overdose Rate (2019-2024) ===\n")

cs_drug <- att_gt(
  yname = "rate_Drug_OD",
  tname = "year",
  idname = "state_id",
  gname = "G",
  data = as.data.frame(short_cs),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_drug <- aggte(cs_drug, type = "simple")
cat("\nOverall ATT (Drug OD Rate — Placebo):\n")
print(summary(agg_drug))

es_drug <- aggte(cs_drug, type = "dynamic", min_e = -4, max_e = 4)

saveRDS(cs_drug, file.path(data_dir, "cs_drug_od.rds"))
saveRDS(agg_drug, file.path(data_dir, "agg_drug_od.rds"))
saveRDS(es_drug, file.path(data_dir, "es_drug_od.rds"))

# ─── E. All Suicide (Short Panel) for direct comparison ─────────────────────

cat("\n=== E. CS-DiD: All Suicide Rate (2019-2024) ===\n")

cs_all_short <- att_gt(
  yname = "rate_All_Suicide",
  tname = "year",
  idname = "state_id",
  gname = "G",
  data = as.data.frame(short_cs),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_all_short <- aggte(cs_all_short, type = "simple")
cat("\nOverall ATT (All Suicide Rate, Short Panel):\n")
print(summary(agg_all_short))

es_all_short <- aggte(cs_all_short, type = "dynamic", min_e = -4, max_e = 4)

saveRDS(cs_all_short, file.path(data_dir, "cs_all_suicide_short.rds"))
saveRDS(agg_all_short, file.path(data_dir, "agg_all_suicide_short.rds"))
saveRDS(es_all_short, file.path(data_dir, "es_all_suicide_short.rds"))

# ─── F. TWFE for comparison (diagnostic, not primary) ───────────────────────

cat("\n=== F. TWFE (diagnostic comparison) ===\n")

# Standard TWFE on combined panel for comparison
twfe_total <- feols(
  rate_All_Suicide ~ treated | state_id + year,
  data = cs_data_main,
  cluster = ~state_id
)

cat("\nTWFE (Total Suicide Rate):\n")
print(summary(twfe_total))

# TWFE on short panel (firearm suicide)
twfe_fa <- feols(
  rate_FA_Suicide ~ treated | state_id + year,
  data = short_cs,
  cluster = ~state_id
)

cat("\nTWFE (Firearm Suicide Rate, 2019-2024):\n")
print(summary(twfe_fa))

saveRDS(twfe_total, file.path(data_dir, "twfe_total.rds"))
saveRDS(twfe_fa, file.path(data_dir, "twfe_fa.rds"))

# ─── G. Export main results for tables ───────────────────────────────────────

main_results <- data.table(
  Outcome = c("Total Suicide Rate (Combined)",
              "Firearm Suicide Rate",
              "Non-Firearm Suicide Rate",
              "All Suicide Rate (Short)",
              "Drug OD Rate (Placebo)"),
  ATT = c(agg_total$overall.att, agg_fa$overall.att,
          agg_nf$overall.att, agg_all_short$overall.att,
          agg_drug$overall.att),
  SE = c(agg_total$overall.se, agg_fa$overall.se,
         agg_nf$overall.se, agg_all_short$overall.se,
         agg_drug$overall.se),
  Panel = c("1999-2024", "2019-2024", "2019-2024",
            "2019-2024", "2019-2024"),
  N_treated = c(
    uniqueN(cs_data_main[G > 0]$state),
    uniqueN(short_cs[G > 0]$state),
    uniqueN(short_cs[G > 0]$state),
    uniqueN(short_cs[G > 0]$state),
    uniqueN(short_cs[G > 0]$state)
  )
)
main_results[, p_value := 2 * pnorm(-abs(ATT / SE))]
main_results[, CI_lower := ATT - 1.96 * SE]
main_results[, CI_upper := ATT + 1.96 * SE]

fwrite(main_results, file.path(data_dir, "main_results.csv"))

cat("\n=== Main Results Summary ===\n")
print(main_results[, .(Outcome, ATT = round(ATT, 3), SE = round(SE, 3),
                        p = round(p_value, 3), Panel)])

cat("\nDONE.\n")
