## 03_main_analysis.R — Callaway-Sant'Anna DiD + Event Studies
## APEP-0636: Constitutional Carry and Firearm Violence

source("00_packages.R")

panel <- read_csv("data/analysis_panel_clean.csv", show_col_types = FALSE)
cat("Loaded:", nrow(panel), "rows,", n_distinct(panel$state_fips), "states\n")

# Only keep states in DiD sample (exclude pre-2019 adopters)
did_panel <- panel |> filter(cc_wave != "Pre-2019")

# ============================================================
# 1. CALLAWAY-SANT'ANNA: FIREARM HOMICIDE RATE
# ============================================================

cat("\n=== CS-DiD: Firearm Homicide Rate ===\n")

cs_hom <- att_gt(
  yname = "fa_homicide_rate",
  tname = "year",
  idname = "state_id",
  gname = "gname",
  data = did_panel,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

cat("ATT(g,t) estimates computed\n")

# Overall ATT
agg_hom_simple <- aggte(cs_hom, type = "simple")
cat("\nOverall ATT (Firearm Homicide Rate):\n")
summary(agg_hom_simple)

# Event study aggregation
es_hom <- aggte(cs_hom, type = "dynamic", min_e = -4, max_e = 3)
cat("\nEvent Study (Firearm Homicide Rate):\n")
summary(es_hom)

# Group-specific ATTs
agg_hom_group <- aggte(cs_hom, type = "group")
cat("\nGroup ATTs (Firearm Homicide Rate):\n")
summary(agg_hom_group)

# ============================================================
# 2. CALLAWAY-SANT'ANNA: FIREARM SUICIDE RATE
# ============================================================

cat("\n=== CS-DiD: Firearm Suicide Rate ===\n")

cs_sui <- att_gt(
  yname = "fa_suicide_rate",
  tname = "year",
  idname = "state_id",
  gname = "gname",
  data = did_panel,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_sui_simple <- aggte(cs_sui, type = "simple")
cat("\nOverall ATT (Firearm Suicide Rate):\n")
summary(agg_sui_simple)

es_sui <- aggte(cs_sui, type = "dynamic", min_e = -4, max_e = 3)
cat("\nEvent Study (Firearm Suicide Rate):\n")
summary(es_sui)

agg_sui_group <- aggte(cs_sui, type = "group")

# ============================================================
# 3. CALLAWAY-SANT'ANNA: TOTAL FIREARM DEATH RATE
# ============================================================

cat("\n=== CS-DiD: Total Firearm Death Rate ===\n")

cs_total <- att_gt(
  yname = "total_fa_rate",
  tname = "year",
  idname = "state_id",
  gname = "gname",
  data = did_panel,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_total_simple <- aggte(cs_total, type = "simple")
cat("\nOverall ATT (Total Firearm Death Rate):\n")
summary(agg_total_simple)

es_total <- aggte(cs_total, type = "dynamic", min_e = -4, max_e = 3)

# ============================================================
# 4. TWFE COMPARISON (for reference)
# ============================================================

cat("\n=== TWFE Comparison ===\n")

twfe_hom <- feols(fa_homicide_rate ~ treated | state_fips + year,
                  data = did_panel, cluster = ~state_fips)
cat("TWFE Firearm Homicide:\n")
print(summary(twfe_hom))

twfe_sui <- feols(fa_suicide_rate ~ treated | state_fips + year,
                  data = did_panel, cluster = ~state_fips)
cat("\nTWFE Firearm Suicide:\n")
print(summary(twfe_sui))

twfe_total <- feols(total_fa_rate ~ treated | state_fips + year,
                    data = did_panel, cluster = ~state_fips)

# Sun-Abraham event study
did_panel <- did_panel |>
  mutate(
    sunab_cohort = ifelse(gname == 0, 10000L, gname),
    rel_year = year - sunab_cohort
  )

sa_hom <- feols(fa_homicide_rate ~ sunab(sunab_cohort, year) | state_fips + year,
                data = did_panel, cluster = ~state_fips)

sa_sui <- feols(fa_suicide_rate ~ sunab(sunab_cohort, year) | state_fips + year,
                data = did_panel, cluster = ~state_fips)

# ============================================================
# 5. SAVE ALL RESULTS
# ============================================================

results <- list(
  # CS-DiD objects
  cs_hom = cs_hom,
  cs_sui = cs_sui,
  cs_total = cs_total,
  # Aggregated ATTs
  agg_hom_simple = agg_hom_simple,
  agg_sui_simple = agg_sui_simple,
  agg_total_simple = agg_total_simple,
  # Event studies
  es_hom = es_hom,
  es_sui = es_sui,
  es_total = es_total,
  # Group ATTs
  agg_hom_group = agg_hom_group,
  agg_sui_group = agg_sui_group,
  # TWFE
  twfe_hom = twfe_hom,
  twfe_sui = twfe_sui,
  twfe_total = twfe_total,
  # Sun-Abraham
  sa_hom = sa_hom,
  sa_sui = sa_sui
)

saveRDS(results, "data/main_results.rds")

# ============================================================
# 6. KEY RESULTS SUMMARY
# ============================================================

cat("\n")
cat("============================================\n")
cat("         KEY RESULTS SUMMARY\n")
cat("============================================\n\n")

cat("CS-DiD Overall ATTs:\n")
cat(sprintf("  Firearm Homicide: %.3f (SE=%.3f, p=%.3f)\n",
            agg_hom_simple$overall.att, agg_hom_simple$overall.se,
            2 * pnorm(-abs(agg_hom_simple$overall.att / agg_hom_simple$overall.se))))
cat(sprintf("  Firearm Suicide:  %.3f (SE=%.3f, p=%.3f)\n",
            agg_sui_simple$overall.att, agg_sui_simple$overall.se,
            2 * pnorm(-abs(agg_sui_simple$overall.att / agg_sui_simple$overall.se))))
cat(sprintf("  Total Firearm:    %.3f (SE=%.3f, p=%.3f)\n",
            agg_total_simple$overall.att, agg_total_simple$overall.se,
            2 * pnorm(-abs(agg_total_simple$overall.att / agg_total_simple$overall.se))))

cat("\nTWFE Estimates:\n")
cat(sprintf("  Firearm Homicide: %.3f (SE=%.3f)\n",
            coef(twfe_hom)["treated"], se(twfe_hom)["treated"]))
cat(sprintf("  Firearm Suicide:  %.3f (SE=%.3f)\n",
            coef(twfe_sui)["treated"], se(twfe_sui)["treated"]))

cat("\nN treated states:", n_distinct(did_panel$state_fips[did_panel$gname > 0]), "\n")
cat("N control states:", n_distinct(did_panel$state_fips[did_panel$gname == 0]), "\n")
cat("N state-year obs:", nrow(did_panel), "\n")

# Update diagnostics
diag <- jsonlite::read_json("data/diagnostics.json")
diag$n_treated <- n_distinct(did_panel$state_fips[did_panel$gname > 0])
diag$n_pre <- 5L
diag$n_obs <- nrow(did_panel)
diag$att_fa_homicide <- round(agg_hom_simple$overall.att, 4)
diag$att_fa_suicide <- round(agg_sui_simple$overall.att, 4)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\nMain analysis complete. Results saved to data/main_results.rds\n")
