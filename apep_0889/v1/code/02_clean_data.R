# 02_clean_data.R — Construct treatment and election panel
# APEP-0889: Slower Mail, Fewer Voters

source("00_packages.R")
data_dir <- "../data"

# ============================================================================
# 1. QCEW: Construct treatment from USPS establishment changes (2014-2023)
# ============================================================================
cat("=== Processing QCEW USPS establishments ===\n")

qcew <- fread(file.path(data_dir, "qcew_usps_county.csv"))
qcew[, fips := as.character(fips)]

# Baseline: 2014 (first available year)
baseline <- qcew[year == 2014, .(fips, estabs_2014 = usps_estabs, emp_2014 = usps_emp)]
cat(sprintf("Baseline 2014: %d counties\n", nrow(baseline)))

# Track year-over-year changes
qcew_wide <- dcast(qcew, fips ~ year, value.var = "usps_estabs")
setnames(qcew_wide, as.character(2014:2023), paste0("e_", 2014:2023))

qcew_wide <- merge(qcew_wide, baseline, by = "fips")

# Treatment: first year establishments declined from 2014 baseline
# Map to nearest SUBSEQUENT presidential election year
qcew_wide[, first_decline_year := NA_integer_]
for (yr in 2015:2018) {
  col <- paste0("e_", yr)
  qcew_wide[is.na(first_decline_year) & !is.na(get(col)) & get(col) < estabs_2014,
             first_decline_year := yr]
}

# Map QCEW treatment year to election treatment year
# Lost by 2015-2016 → treated by 2016 election
# Lost by 2017-2018 → treated by 2020 election
qcew_wide[, first_treat := fcase(
  first_decline_year %in% c(2015L, 2016L), 2016L,
  first_decline_year %in% c(2017L, 2018L), 2020L,
  default = 0L   # never-treated
)]

# Treatment intensity: total establishment loss by 2018 (or latest)
qcew_wide[, loss_by_2018 := fifelse(!is.na(e_2018),
                                     pmax(estabs_2014 - e_2018, 0L), 0L)]
qcew_wide[, pct_loss := fifelse(estabs_2014 > 0, loss_by_2018 / estabs_2014, 0)]

treatment <- qcew_wide[, .(fips, estabs_2014, emp_2014, first_treat,
                            loss_by_2018, pct_loss)]

cat(sprintf("Treatment cohorts:\n"))
print(treatment[, .(.N, mean_estabs_2014 = round(mean(estabs_2014), 1)),
                by = .(cohort = fifelse(first_treat == 0, "Never-treated",
                                         paste0("Treated by ", first_treat)))])

# ============================================================================
# 2. MIT Election Lab: County presidential returns + voting mode
# ============================================================================
cat("\n=== Processing MIT Election Lab returns ===\n")

mit <- fread(file.path(data_dir, "countypres_2000_2024.csv"))
mit[, fips := sprintf("%05d", as.integer(county_fips))]
mit <- mit[!is.na(county_fips) & county_fips != ""]

# Classify voting modes
mail_modes <- c("ABSENTEE", "ABSENTEE BY MAIL", "MAIL", "MAIL-IN",
                "2ND ABSENTEE")
inperson_modes <- c("ELECTION DAY", "EARLY", "EARLY VOTE", "EARLY VOTING",
                     "ADVANCED VOTING", "ONE STOP", "VOTE CENTER",
                     "IN-PERSON ABSENTEE", "LATE EARLY VOTING")

# Aggregate to county-year: total votes, mail votes, in-person votes
# Use TOTAL mode rows for total; sum mail modes for mail votes
county_totals <- mit[mode == "TOTAL",
                      .(total_votes = sum(candidatevotes, na.rm = TRUE)),
                      by = .(fips, year)]

county_mail <- mit[mode %in% mail_modes,
                    .(mail_votes = sum(candidatevotes, na.rm = TRUE)),
                    by = .(fips, year)]

county_inperson <- mit[mode %in% inperson_modes,
                        .(inperson_votes = sum(candidatevotes, na.rm = TRUE)),
                        by = .(fips, year)]

election <- merge(county_totals, county_mail, by = c("fips", "year"), all.x = TRUE)
election <- merge(election, county_inperson, by = c("fips", "year"), all.x = TRUE)

# Fill NA mail/inperson with 0 (states that only report TOTAL)
election[is.na(mail_votes), mail_votes := 0L]
election[is.na(inperson_votes), inperson_votes := 0L]

# Mail ballot share (only meaningful where mode data exists)
election[, has_mode_data := (mail_votes + inperson_votes) > 0]
election[has_mode_data == TRUE, mail_share := mail_votes / total_votes]

cat(sprintf("Election data: %d county-years across %s\n",
            nrow(election), paste(sort(unique(election$year)), collapse=", ")))
cat(sprintf("Counties with mode data by year:\n"))
print(election[has_mode_data == TRUE, .N, by = year][order(year)])

# ============================================================================
# 3. Census ACS: County demographics
# ============================================================================
cat("\n=== Loading Census ACS data ===\n")

acs_file <- file.path(data_dir, "census_acs_county.csv")
if (file.exists(acs_file)) {
  acs <- fread(acs_file)
  acs[, fips := as.character(fips)]

  # Use 2015 ACS for pre-treatment controls, 2019 for post-treatment
  acs_baseline <- acs[acs_year == 2015, .(fips, pop_2015 = total_pop,
                                           income_2015 = median_income,
                                           pct_white_2015 = pct_white)]
  acs_post <- acs[acs_year == 2019, .(fips, pop_2019 = total_pop)]

  cat(sprintf("ACS baseline: %d counties\n", nrow(acs_baseline)))
} else {
  cat("ACS data not found — proceeding without demographic controls.\n")
  acs_baseline <- NULL
}

# ============================================================================
# 4. Construct analysis panel: county × election year
# ============================================================================
cat("\n=== Constructing analysis panel ===\n")

# Panel: counties × presidential election years (2000-2024)
panel <- merge(election, treatment, by = "fips", all.x = TRUE)

# Drop counties without QCEW data (can't determine treatment)
panel <- panel[!is.na(first_treat)]

# Treatment indicators
panel[, treated := first_treat > 0]
panel[, post := year >= first_treat & first_treat > 0]

# Merge ACS controls
if (!is.null(acs_baseline)) {
  panel <- merge(panel, acs_baseline, by = "fips", all.x = TRUE)
  panel <- merge(panel, acs_post, by = "fips", all.x = TRUE)

  # Turnout rate (votes / voting-age proxy: pop * 0.76)
  panel[, turnout_pop := fifelse(year <= 2016, pop_2015, pop_2019)]
  panel[turnout_pop > 0, turnout_rate := total_votes / (turnout_pop * 0.76)]
  panel[turnout_rate > 1 | turnout_rate < 0, turnout_rate := NA]
}

# Log votes
panel[total_votes > 0, log_votes := log(total_votes)]
panel[mail_votes > 0, log_mail := log(mail_votes)]

# State FIPS for clustering
panel[, state_fips := substr(fips, 1, 2)]

# Per-capita USPS establishments (baseline measure)
if (!is.null(acs_baseline)) {
  panel[pop_2015 > 0, estabs_per_10k := estabs_2014 / (pop_2015 / 10000)]
}

# ============================================================================
# 5. Summary statistics
# ============================================================================
cat("\n=== Analysis Panel Summary ===\n")
cat(sprintf("Panel: %d county-elections, %d counties, %d years\n",
            nrow(panel), uniqueN(panel$fips), uniqueN(panel$year)))

cat("\nCounties by treatment cohort:\n")
print(panel[year == 2016, .N, by = .(first_treat)])

cat("\nMean total votes by year and treatment:\n")
print(panel[, .(mean_votes = round(mean(total_votes, na.rm = TRUE)),
                n = .N),
            by = .(year, treated)][order(year, treated)])

cat("\nMail ballot share (where available) by year and treatment:\n")
print(panel[has_mode_data == TRUE,
            .(mean_mail_share = round(mean(mail_share, na.rm = TRUE), 4),
              n = .N),
            by = .(year, treated)][order(year, treated)])

cat("\nUSPS establishments by treatment status (2014 baseline):\n")
print(panel[year == 2016, .(mean_estabs = round(mean(estabs_2014, na.rm = TRUE), 1),
                             mean_loss = round(mean(loss_by_2018, na.rm = TRUE), 2)),
            by = treated])

if (!is.null(acs_baseline)) {
  cat("\nDemographic balance (2015 ACS):\n")
  print(panel[year == 2016,
              .(mean_pop = round(mean(pop_2015, na.rm = TRUE)),
                mean_income = round(mean(income_2015, na.rm = TRUE)),
                mean_pct_white = round(mean(pct_white_2015, na.rm = TRUE), 3)),
              by = treated])
}

# Save
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("\nPanel saved: %d observations\n", nrow(panel)))

# ============================================================================
# 6. Diagnostics JSON (for validate_v1.py)
# ============================================================================
diag <- list(
  n_treated = panel[year == 2016 & treated == TRUE, uniqueN(fips)],
  n_pre = length(unique(panel$year[panel$year < 2016])),
  n_obs = nrow(panel)
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("Diagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))
