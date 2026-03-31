# 02_clean_data.R — Merge and construct analysis variables
# apep_1202: Broadband preemption and telehealth adoption

source("00_packages.R")

cat("=== Loading raw data ===\n")
telehealth <- fread("../data/cms_telehealth_raw.csv")
states <- fread("../data/state_preemption.csv")
acs_internet <- fread("../data/acs_internet.csv")
acs_demo <- fread("../data/acs_demographics.csv")

cat(sprintf("  Telehealth: %d rows\n", nrow(telehealth)))
cat(sprintf("  States: %d rows\n", nrow(states)))

# --- CMS Telehealth Panel ---
cat("\n=== Cleaning CMS telehealth data ===\n")

# Filter to state-level, "All" demographic categories, quarterly (not "Overall")
# Keep rural/urban breakdown for triple-diff
th <- telehealth[
  Bene_Mdcd_Mdcr_Enrl_Stus == "All" &
  Bene_Race_Desc == "All" &
  Bene_Sex_Desc == "All" &
  Bene_Mdcr_Entlmt_Stus == "All" &
  Bene_Age_Desc == "All" &
  Quarter != "Overall" &
  !(Bene_Geo_Desc %in% c("National", "Puerto Rico", "Virgin Islands",
                          "Other Areas", "Missing Data"))
]

# Convert types
th[, Year := as.integer(Year)]
th[, Quarter := as.integer(Quarter)]
th[, Pct_Telehealth := as.numeric(Pct_Telehealth)]
th[, Total_Bene_Telehealth := as.numeric(Total_Bene_Telehealth)]
th[, Total_Bene_TH_Elig := as.numeric(Total_Bene_TH_Elig)]

# Create time variable (year-quarter numeric for panel)
th[, yq := Year + (Quarter - 1) / 4]
th[, time_id := (Year - 2020) * 4 + Quarter]  # 1 = 2020Q1, 2 = 2020Q2, etc.

# Identify rural/urban
th[, rural := fifelse(Bene_RUCA_Desc == "Rural", 1L, 0L)]
th[, urban := fifelse(Bene_RUCA_Desc == "Urban", 1L, 0L)]
th[, ruca_all := fifelse(Bene_RUCA_Desc == "All", 1L, 0L)]

cat(sprintf("  Filtered telehealth: %d rows\n", nrow(th)))
cat(sprintf("  Years: %s\n", paste(sort(unique(th$Year)), collapse = ", ")))
cat(sprintf("  Quarters: %s\n", paste(sort(unique(th$Quarter)), collapse = ", ")))
cat(sprintf("  States: %d\n", uniqueN(th$Bene_Geo_Desc)))
cat(sprintf("  RUCA categories: %s\n", paste(unique(th$Bene_RUCA_Desc), collapse = ", ")))

# Merge with state preemption
th <- merge(th, states, by.x = "Bene_Geo_Desc", by.y = "state_name", all.x = TRUE)

# Check merge
n_matched <- sum(!is.na(th$state_abbr))
cat(sprintf("  Merged with preemption: %d/%d matched\n", n_matched, nrow(th)))

# Drop unmatched (territories, etc.)
th <- th[!is.na(state_abbr)]

# Post-COVID indicator: COVID telehealth expansion started 2020Q2 (March 2020)
th[, post_covid := fifelse(time_id >= 2, 1L, 0L)]  # 2020Q2 = time_id 2

# Interaction: preemption × post-COVID
th[, preempt_post := preemption * post_covid]

cat(sprintf("\n  Final telehealth panel: %d obs\n", nrow(th)))
cat(sprintf("  State-quarters (All RUCA): %d\n", nrow(th[ruca_all == 1])))
cat(sprintf("  Preempted states: %d\n", uniqueN(th[preemption == 1]$state_abbr)))
cat(sprintf("  Control states: %d\n", uniqueN(th[preemption == 0]$state_abbr)))

# --- ACS Internet Panel ---
cat("\n=== Cleaning ACS internet data ===\n")

# Extract state FIPS from GEOID
acs_internet[, state_fips := substr(GEOID, 1, 2)]
states[, state_fips := as.character(state_fips)]
acs_internet <- merge(acs_internet, states[, .(state_fips, state_abbr, preemption)],
                      by = "state_fips", all.x = TRUE)
acs_internet <- acs_internet[!is.na(state_abbr)]

# Compute broadband rate
acs_internet[, broadband_rate := broadbandE / total_hhE]
acs_internet[, no_internet_rate := no_internetE / total_hhE]

cat(sprintf("  ACS internet: %d state-years\n", nrow(acs_internet)))

# Pre-COVID broadband (2019) — for mechanism evidence
broadband_2019 <- acs_internet[year == 2019, .(state_abbr, broadband_rate_2019 = broadband_rate,
                                                 no_internet_rate_2019 = no_internet_rate)]

# --- ACS Demographics ---
cat("\n=== Cleaning ACS demographic controls ===\n")

acs_demo[, state_fips := substr(GEOID, 1, 2)]
acs_demo <- merge(acs_demo, states[, .(state_fips, state_abbr)],
                  by = "state_fips", all.x = TRUE)
acs_demo <- acs_demo[!is.na(state_abbr)]

# Use 2019 demographics as pre-treatment controls
demo_2019 <- acs_demo[year == 2019, .(state_abbr,
                                       med_income = med_incomeE,
                                       pct_college = college_baE / college_totalE)]

# --- Final merge ---
cat("\n=== Final merge ===\n")

# Merge broadband and demographics into telehealth panel
th <- merge(th, broadband_2019, by = "state_abbr", all.x = TRUE)
th <- merge(th, demo_2019, by = "state_abbr", all.x = TRUE)

# Numeric state ID for fixest
th[, state_id := as.integer(factor(state_abbr))]

# Save
fwrite(th, "../data/analysis_panel.csv")
cat(sprintf("  Saved analysis_panel.csv: %d rows\n", nrow(th)))

# --- Summary statistics by preemption status ---
cat("\n=== Summary: Telehealth by preemption (All RUCA, post-COVID) ===\n")
summ <- th[ruca_all == 1 & post_covid == 1,
           .(mean_th = mean(Pct_Telehealth, na.rm = TRUE),
             sd_th = sd(Pct_Telehealth, na.rm = TRUE),
             n_states = uniqueN(state_abbr),
             n_obs = .N),
           by = preemption]
print(summ)

cat("\n=== Summary: Telehealth by preemption × rural (post-COVID) ===\n")
summ2 <- th[ruca_all == 0 & post_covid == 1 & Bene_RUCA_Desc %in% c("Rural", "Urban"),
            .(mean_th = mean(Pct_Telehealth, na.rm = TRUE),
              n_obs = .N),
            by = .(preemption, Bene_RUCA_Desc)]
print(summ2)

cat("\n=== Summary: Pre-COVID broadband by preemption ===\n")
bb_summ <- broadband_2019[, .(state_abbr, broadband_rate_2019)]
bb_summ <- merge(bb_summ, states[, .(state_abbr, preemption)], by = "state_abbr")
print(bb_summ[, .(mean_bb = mean(broadband_rate_2019, na.rm = TRUE),
                   sd_bb = sd(broadband_rate_2019, na.rm = TRUE)),
              by = preemption])
