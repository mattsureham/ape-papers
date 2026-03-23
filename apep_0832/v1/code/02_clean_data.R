## 02_clean_data.R — Construct analysis panel
## apep_0832: The Access Cost of Fraud Prevention

source("00_packages.R")
setwd(gsub("/code$", "", getwd()))

## ============================================================
## Load raw data
## ============================================================
wic_ebt <- fread("data/wic_ebt_dates.csv")
chr_panel <- fread("data/chr_state_panel.csv")
state_fips <- fread("data/state_fips.csv")

cat("Raw CHR panel:", nrow(chr_panel), "obs\n")
cat("CHR years:", paste(sort(unique(chr_panel$chr_year)), collapse = ", "), "\n")

## ============================================================
## Clean CHR panel
## ============================================================
## CHR data: each release year uses data from approximately 5 years prior
## to 2 years prior (e.g., CHR 2020 uses 2014-2018 data).
## The data_year approximation: center of the window ~ chr_year - 3.
##
## For our DiD, we use chr_year as the "effective year" since:
## 1. It's the consistent temporal dimension across the panel
## 2. The underlying data windows overlap, but the CHR release captures
##    the most recent information available at that time
## 3. Treatment timing in ebt_year represents when EBT was actually adopted,
##    which affects the underlying data flowing into future CHR releases

chr_panel[, lbw_rate := as.numeric(v037_rawvalue)]
chr_panel[, infant_mort_rate := as.numeric(v129_rawvalue)]
chr_panel[, state_abbr := toupper(trimws(state))]

## Drop US-level row and non-state entries
chr_panel <- chr_panel[!state_abbr %in% c("US", "")]

## Check coverage
cat("\nCHR states:", length(unique(chr_panel$state_abbr)), "\n")
cat("LBW non-missing:", sum(!is.na(chr_panel$lbw_rate)), "/", nrow(chr_panel), "\n")
cat("Infant mort non-missing:", sum(!is.na(chr_panel$infant_mort_rate)), "/", nrow(chr_panel), "\n")

## ============================================================
## Map CHR state names to state abbreviations
## ============================================================
## CHR uses full state names in the "state" column
## We need to merge with WIC EBT dates which use abbreviations

state_names <- data.table(
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
                 "Connecticut","Delaware","District of Columbia","Florida","Georgia",
                 "Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky",
                 "Louisiana","Maine","Maryland","Massachusetts","Michigan","Minnesota",
                 "Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire",
                 "New Jersey","New Mexico","New York","North Carolina","North Dakota",
                 "Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island","South Carolina",
                 "South Dakota","Tennessee","Texas","Utah","Vermont","Virginia",
                 "Washington","West Virginia","Wisconsin","Wyoming"),
  state_code = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID",
                 "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO",
                 "MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA",
                 "RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

## CHR state column contains full names or abbreviations depending on year
## Check what format we have
cat("\nSample CHR state values:", paste(head(unique(chr_panel$state_abbr), 10), collapse = ", "), "\n")

## If they look like abbreviations (2 chars), use directly
chr_panel[, state_code := fifelse(nchar(state_abbr) <= 2, state_abbr,
  state_names$state_code[match(state_abbr, toupper(state_names$state_name))])]

## Drop rows where state mapping failed
chr_panel <- chr_panel[!is.na(state_code)]
cat("After state mapping:", nrow(chr_panel), "obs\n")

## ============================================================
## Merge with WIC EBT dates
## ============================================================
panel <- merge(chr_panel, wic_ebt[, .(state, ebt_year)],
               by.x = "state_code", by.y = "state",
               all.x = TRUE)

cat("After merging EBT dates:", nrow(panel), "obs\n")
cat("Missing EBT year:", sum(is.na(panel$ebt_year)), "\n")

## Drop if no EBT date (shouldn't happen for valid states)
panel <- panel[!is.na(ebt_year)]

## ============================================================
## Create treatment variables
## ============================================================
## The CHR release year is our panel year
## Treatment = 1 if state adopted WIC EBT before or during the CHR data window
## CHR year Y uses data centered around Y-3
## So treatment is on if ebt_year <= chr_year - 2 (conservative: EBT adopted
## at least 2 years before CHR release to allow data to reflect the change)

panel[, year := chr_year]
panel[, post_ebt := as.integer(ebt_year <= (year - 2))]
panel[, years_since_ebt := year - 2 - ebt_year]  # Relative time (adjusted for data lag)

## Cohort variable for Callaway-Sant'Anna
## G = first year the state is "treated" in our panel (ebt_year + 2)
panel[, cohort_year := ebt_year + 2L]

cat("\nTreatment summary:\n")
cat("  Treated (post_ebt=1):", sum(panel$post_ebt == 1), "\n")
cat("  Untreated (post_ebt=0):", sum(panel$post_ebt == 0), "\n")
cat("  Treatment groups:", paste(sort(unique(panel$cohort_year)), collapse = ", "), "\n")

## ============================================================
## Categorize states by adoption timing
## ============================================================
panel[, adoption_group := fcase(
  ebt_year <= 2006, "Early (2004-2006)",
  ebt_year <= 2013, "Middle (2011-2013)",
  ebt_year <= 2016, "Late (2014-2016)",
  ebt_year >= 2017, "Very Late (2017-2019)"
)]

cat("\nAdoption groups:\n")
print(panel[, .(n_states = uniqueN(state_code)), by = adoption_group])

## ============================================================
## Create standardized outcomes
## ============================================================
## Standardize LBW rate (for SDE calculations later)
panel[, lbw_rate_pct := lbw_rate * 100]  # Convert to percentage
panel[, sd_lbw := sd(lbw_rate_pct[post_ebt == 0], na.rm = TRUE)]  # Pre-treatment SD

cat("\nOutcome summary:\n")
cat("  LBW rate: mean =", round(mean(panel$lbw_rate_pct, na.rm=TRUE), 2),
    "%, SD =", round(sd(panel$lbw_rate_pct, na.rm=TRUE), 2), "%\n")
cat("  Pre-treatment SD(LBW):", round(panel$sd_lbw[1], 3), "%\n")
if ("infant_mort_rate" %in% names(panel)) {
  panel[, im_rate := as.numeric(infant_mort_rate)]
  cat("  Infant mortality: mean =", round(mean(panel$im_rate, na.rm=TRUE), 2),
      ", SD =", round(sd(panel$im_rate, na.rm=TRUE), 2), "\n")
}

## ============================================================
## Panel diagnostics
## ============================================================
cat("\n=== Panel Diagnostics ===\n")
cat("States:", uniqueN(panel$state_code), "\n")
cat("Years:", length(unique(panel$year)), "(", min(panel$year), "-", max(panel$year), ")\n")
cat("Total obs:", nrow(panel), "\n")
cat("Balanced:", nrow(panel) == uniqueN(panel$state_code) * length(unique(panel$year)), "\n")

## Check pre-treatment periods per cohort
for (g in sort(unique(panel$cohort_year))) {
  pre <- panel[cohort_year == g & post_ebt == 0, .N]
  post <- panel[cohort_year == g & post_ebt == 1, .N]
  n_states <- panel[cohort_year == g, uniqueN(state_code)]
  cat("  Cohort", g, ": pre=", pre, "post=", post, "states=", n_states, "\n")
}

## ============================================================
## Save analysis panel
## ============================================================
fwrite(panel, "data/analysis_panel.csv")
cat("\nSaved analysis panel:", nrow(panel), "obs to data/analysis_panel.csv\n")
