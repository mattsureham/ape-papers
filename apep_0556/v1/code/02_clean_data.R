## ============================================================
## 02_clean_data.R — Clean and construct analysis panel
## APEP Paper: India's NRHM and Neonatal Mortality Transition
## ============================================================

source("00_packages.R")
data_dir <- "../data"

## ── 1. Load raw data ───────────────────────────────────────────

dhs_sub <- fread(file.path(data_dir, "dhs_subnational_raw.csv"))
dhs_nat <- fread(file.path(data_dir, "dhs_national_raw.csv"))
wb_data <- fread(file.path(data_dir, "wb_national_indicators.csv"))
srs_imr <- fread(file.path(data_dir, "srs_state_imr.csv"))
nrhm    <- fread(file.path(data_dir, "nrhm_implementation_full.csv"))

cat("Raw data loaded.\n")

## ── 2. Clean DHS subnational data ──────────────────────────────

# Keep only preferred estimates
dhs_clean <- dhs_sub[IsPreferred == 1 | is.na(IsPreferred)]

# Standardize state names
# Remove ".." prefix for sub-states and clean names
dhs_clean[, state := gsub("^\\.\\.", "", CharacteristicLabel)]
dhs_clean[, state := trimws(state)]

# Remove composite entries (keep individual states)
composites <- c("Madhya Pradesh, inc Chhattisgarh",
                "Uttar Pradesh, inc Uttarakhand",
                "Bihar, inc Jharkhand",
                "Andhra Pradesh including Telangana")
dhs_clean <- dhs_clean[!CharacteristicLabel %in% composites]

# Harmonize state names across survey rounds
name_map <- c(
  "Jammu, Kashmir & Ladakh" = "Jammu and Kashmir",
  "New Delhi" = "Delhi",
  "Andaman and Nicobar Islands" = "Andaman and Nicobar",
  "Dadra and Nagar Haveli" = "Dadra and Nagar Haveli"
)
for (old_name in names(name_map)) {
  dhs_clean[state == old_name, state := name_map[old_name]]
}

# Convert value to numeric
dhs_clean[, value := as.numeric(Value)]

# Reshape to wide by indicator
dhs_wide <- dcast(dhs_clean,
                   state + SurveyYear ~ IndicatorId,
                   value.var = "value",
                   fun.aggregate = function(x) mean(x, na.rm = TRUE))

setnames(dhs_wide, c("RH_DELP_C_DHF", "RH_ANCN_W_N4P", "AN_ANEM_W_ANY"),
         c("inst_delivery", "anc_4plus", "anemia_women"),
         skip_absent = TRUE)

cat(sprintf("DHS wide panel: %d state-survey obs, %d unique states\n",
            nrow(dhs_wide), uniqueN(dhs_wide$state)))

## ── 3. Merge NRHM treatment assignment ─────────────────────────

# Standardize NRHM state names
nrhm[state == "Andhra Pradesh", state := "Andhra Pradesh"]

# Create lookup
treat_lookup <- nrhm[, .(state, high_focus, eag_state, ne_state,
                          jsy_incentive_inr, jsy_universal, nrhm_phase,
                          asha_start_year, baseline_inst_delivery_2006)]

# Merge
panel <- merge(dhs_wide, treat_lookup, by = "state", all.x = TRUE)

# States without NRHM classification: assign non-high-focus
# (UTs and small states not in our treatment list)
panel[is.na(high_focus), `:=`(
  high_focus = 0, eag_state = 0, ne_state = 0,
  jsy_incentive_inr = 800, jsy_universal = 0, nrhm_phase = 2,
  asha_start_year = 2009
)]

# Create time variables
panel[, `:=`(
  # Post-NRHM indicator (2006 is first year with NRHM in progress)
  post_nrhm = as.integer(SurveyYear >= 2006),
  # Survey period (ordered)
  period = factor(SurveyYear, levels = c(1993, 1999, 2006, 2015, 2020),
                  labels = c("NFHS-1 (1993)", "NFHS-2 (1999)", "NFHS-3 (2006)",
                             "NFHS-4 (2015)", "NFHS-5 (2020)")),
  # Treatment × Post
  treat_post = high_focus * as.integer(SurveyYear >= 2015),
  # For CS-DiD: first treatment year
  first_treat = fifelse(high_focus == 1, 2006, 2009)
)]

cat(sprintf("\nAnalysis panel: %d obs, %d states, %d survey rounds\n",
            nrow(panel), uniqueN(panel$state), uniqueN(panel$SurveyYear)))

## ── 4. Summary statistics ──────────────────────────────────────

cat("\n=== Summary Statistics by Treatment Group ===\n")

# Baseline (NFHS-3, 2006) summary
baseline <- panel[SurveyYear == 2006]
cat("\nBaseline (NFHS-3, 2006):\n")
cat(sprintf("  High-focus states: %d, mean inst_delivery = %.1f%%\n",
            sum(baseline$high_focus == 1, na.rm = TRUE),
            mean(baseline$inst_delivery[baseline$high_focus == 1], na.rm = TRUE)))
cat(sprintf("  Non-high-focus: %d, mean inst_delivery = %.1f%%\n",
            sum(baseline$high_focus == 0, na.rm = TRUE),
            mean(baseline$inst_delivery[baseline$high_focus == 0], na.rm = TRUE)))

# Endline (NFHS-4, 2015) summary
endline <- panel[SurveyYear == 2015]
cat(sprintf("\nEndline (NFHS-4, 2015):\n"))
cat(sprintf("  High-focus states: mean inst_delivery = %.1f%%\n",
            mean(endline$inst_delivery[endline$high_focus == 1], na.rm = TRUE)))
cat(sprintf("  Non-high-focus: mean inst_delivery = %.1f%%\n",
            mean(endline$inst_delivery[endline$high_focus == 0], na.rm = TRUE)))

# Change
hf_change <- mean(endline$inst_delivery[endline$high_focus == 1], na.rm = TRUE) -
             mean(baseline$inst_delivery[baseline$high_focus == 1], na.rm = TRUE)
nhf_change <- mean(endline$inst_delivery[endline$high_focus == 0], na.rm = TRUE) -
              mean(baseline$inst_delivery[baseline$high_focus == 0], na.rm = TRUE)
cat(sprintf("\nDiD estimate (raw): %.1f pp (HF change: %.1f, NHF change: %.1f)\n",
            hf_change - nhf_change, hf_change, nhf_change))

## ── 5. Create SRS analysis panel ───────────────────────────────

srs_panel <- merge(srs_imr, treat_lookup[, .(state, high_focus, eag_state)],
                    by = "state", all.x = TRUE)

# Check for pre-NRHM parallel trends (2005-2007 pre-period, 2008+ post)
cat("\n=== SRS IMR Pre-Trend Check ===\n")
srs_pre <- srs_panel[year <= 2007]
cat(sprintf("Pre-NRHM (2005-2007):\n"))
cat(sprintf("  HF states avg IMR: %.1f (2005) → %.1f (2007)\n",
            mean(srs_pre$imr[srs_pre$high_focus == 1 & srs_pre$year == 2005]),
            mean(srs_pre$imr[srs_pre$high_focus == 1 & srs_pre$year == 2007])))
cat(sprintf("  NHF states avg IMR: %.1f (2005) → %.1f (2007)\n",
            mean(srs_pre$imr[srs_pre$high_focus == 0 & srs_pre$year == 2005]),
            mean(srs_pre$imr[srs_pre$high_focus == 0 & srs_pre$year == 2007])))

## ── 6. Save cleaned data ──────────────────────────────────────

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
fwrite(srs_panel, file.path(data_dir, "srs_analysis_panel.csv"))

# Summary statistics table for paper
sumstats <- panel[SurveyYear == 2006, .(
  N = .N,
  mean_inst_delivery = mean(inst_delivery, na.rm = TRUE),
  sd_inst_delivery = sd(inst_delivery, na.rm = TRUE),
  mean_anc = mean(anc_4plus, na.rm = TRUE),
  sd_anc = sd(anc_4plus, na.rm = TRUE),
  mean_anemia = mean(anemia_women, na.rm = TRUE),
  sd_anemia = sd(anemia_women, na.rm = TRUE)
), by = .(Group = fifelse(high_focus == 1, "High-Focus (Phase 1)", "Non-High-Focus (Phase 2)"))]

fwrite(sumstats, file.path(data_dir, "summary_stats_baseline.csv"))

cat("\n✓ All cleaned data saved.\n")
cat(sprintf("  analysis_panel.csv: %d rows\n", nrow(panel)))
cat(sprintf("  srs_analysis_panel.csv: %d rows\n", nrow(srs_panel)))
