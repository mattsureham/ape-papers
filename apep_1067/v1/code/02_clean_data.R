## 02_clean_data.R — Clean and prepare NBI panel for bunching analysis
## APEP Working Paper apep_1067

source("00_packages.R")

data_dir <- "../data"

# Load raw data
nbi <- fread(file.path(data_dir, "nbi_panel_2000_2018.csv"))
cat(sprintf("Raw records: %s\n", format(nrow(nbi), big.mark = ",")))

# --- Clean sufficiency rating ---
# SR is typically 0-100, stored as numeric
nbi[, sr := as.numeric(SUFFICIENCY_RATING)]

# Drop records with missing or invalid SR
nbi <- nbi[!is.na(sr) & sr >= 0 & sr <= 100]
cat(sprintf("After SR cleaning: %s records\n", format(nrow(nbi), big.mark = ",")))

# --- Clean owner code ---
# Owner codes: 01=State Highway Agency, 02=County Highway Agency,
# 03=Town/Township, 04=City/Municipal, 11=State Park/Forest,
# 12=Local Park/Forest, 21=Other State Agencies, 25=Other Local,
# 26=Private, 27=Railroad, 31=State Toll Authority, 32=Local Toll Authority,
# 60=Other Federal Agencies, 62=Bureau of Indian Affairs,
# 64=US Forest Service, 66=National Park Service, 68=Bureau of Land Management,
# 70=Bureau of Reclamation, 72=Corps of Engineers (Civil), 74=Corps of Engineers (Military),
# 80=Unknown
nbi[, owner := as.integer(OWNER_022)]
nbi[, owner_type := fcase(
  owner == 1, "State DOT",
  owner %in% c(2, 3, 4, 25), "Local Government",
  owner %in% c(21, 31), "Other State",
  owner %in% c(26, 27), "Private/Railroad",
  owner %in% c(60, 62, 64, 66, 68, 70, 72, 74), "Federal",
  default = "Other"
)]

# --- Clean state code ---
nbi[, state_code := sprintf("%02d", as.integer(STATE_CODE_001))]

# Exclude territories (PR = 72) — keep 50 states + DC
nbi <- nbi[as.integer(state_code) <= 56 & state_code != "72"]

# --- Create integer SR for binning ---
# NBI reports SR to one decimal place but we'll use integer bins
nbi[, sr_int := floor(sr)]

# --- MAP-21 period indicator ---
# MAP-21 signed July 6, 2012; effective October 1, 2012
# Pre-MAP-21: 2000-2012; Post-MAP-21: 2013-2018
nbi[, post_map21 := as.integer(year >= 2013)]
nbi[, period := ifelse(year >= 2013, "Post-MAP-21 (2013-2018)", "Pre-MAP-21 (2000-2012)")]

# --- Clean other variables ---
nbi[, adt := as.numeric(ADT_029)]
nbi[, year_built := as.integer(YEAR_BUILT_027)]
nbi[, bridge_age := year - year_built]

# Condition ratings (0-9 scale)
nbi[, deck_cond := as.integer(DECK_COND_058)]
nbi[, super_cond := as.integer(SUPERSTRUCTURE_COND_059)]
nbi[, sub_cond := as.integer(SUBSTRUCTURE_COND_060)]

# --- Summary statistics ---
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Total bridge-year observations: %s\n", format(nrow(nbi), big.mark = ",")))
cat(sprintf("Unique bridges: %s\n", format(nbi[, uniqueN(STRUCTURE_NUMBER_008)], big.mark = ",")))
cat(sprintf("States: %d\n", nbi[, uniqueN(state_code)]))
cat(sprintf("Years: %d-%d\n", min(nbi$year), max(nbi$year)))
cat(sprintf("\nSufficiency Rating distribution:\n"))
print(summary(nbi$sr))
cat(sprintf("\nOwner type distribution:\n"))
print(nbi[, .N, by = owner_type][order(-N)])
cat(sprintf("\nPeriod distribution:\n"))
print(nbi[, .N, by = period][order(period)])

# --- SR distribution around threshold (quick check) ---
cat("\n=== SR Distribution Around 50 Threshold ===\n")
threshold_dist <- nbi[sr_int >= 40 & sr_int <= 60, .N, by = sr_int][order(sr_int)]
print(threshold_dist)

# Check bunching at 49 vs 50
n_49 <- nbi[sr_int == 49, .N]
n_50 <- nbi[sr_int == 50, .N]
cat(sprintf("\nSR=49: %s | SR=50: %s | Ratio: %.2f | Drop: %.1f%%\n",
            format(n_49, big.mark = ","), format(n_50, big.mark = ","),
            n_49 / n_50, 100 * (1 - n_50 / n_49)))

# --- Save cleaned data ---
fwrite(nbi, file.path(data_dir, "nbi_clean.csv"))
cat(sprintf("\nSaved cleaned data: %s\n", file.path(data_dir, "nbi_clean.csv")))
