## ============================================================
## 02_clean_data.R — Clean SNAP retailers + merge with natality
## State-level analysis panel
## APEP Paper apep_1301: SNAP Retailer Exits and Birth Outcomes
## ============================================================

source("code/00_packages.R")

data_dir <- "data"

## ---- 1. Load SNAP Retailer Data ----
cat("=== Loading SNAP Retailer Data ===\n")

snap <- fread(file.path(data_dir, "snap_retailers.csv"), showProgress = FALSE)
cat("SNAP raw rows:", format(nrow(snap), big.mark = ","), "\n")

# Standardize column names
old_names <- names(snap)
new_names <- gsub("\\s+", "_", tolower(old_names))
setnames(snap, old_names, new_names)
cat("Columns:", paste(names(snap), collapse = ", "), "\n")

# Parse dates
snap[, authorization_date := as.Date(authorization_date, format = "%m/%d/%Y")]
snap[, end_date := as.Date(end_date, format = "%m/%d/%Y")]
snap[, auth_year := year(authorization_date)]
snap[, end_year := year(end_date)]

# State abbreviation
snap[, state_abbr := toupper(trimws(state))]

# State FIPS mapping
state_fips_map <- c(
  "AL"="01","AK"="02","AZ"="04","AR"="05","CA"="06","CO"="08","CT"="09",
  "DE"="10","DC"="11","FL"="12","GA"="13","HI"="15","ID"="16","IL"="17",
  "IN"="18","IA"="19","KS"="20","KY"="21","LA"="22","ME"="23","MD"="24",
  "MA"="25","MI"="26","MN"="27","MS"="28","MO"="29","MT"="30","NE"="31",
  "NV"="32","NH"="33","NJ"="34","NM"="35","NY"="36","NC"="37","ND"="38",
  "OH"="39","OK"="40","OR"="41","PA"="42","RI"="44","SC"="45","SD"="46",
  "TN"="47","TX"="48","UT"="49","VT"="50","VA"="51","WA"="53","WV"="54",
  "WI"="55","WY"="56"
)

snap[, state_fips := state_fips_map[state_abbr]]
snap <- snap[!is.na(state_fips)]

# Classify store types
cat("\nStore type distribution:\n")
print(snap[, .N, by = store_type][order(-N)])

snap[, supermarket := as.integer(grepl("Super Store|Supermarket|Large Grocery|Warehouse|Combination",
                                        store_type, ignore.case = TRUE))]

cat(sprintf("\nSupermarket-class stores: %s / %s total\n",
            format(sum(snap$supermarket == 1), big.mark = ","),
            format(nrow(snap), big.mark = ",")))


## ---- 2. Identify Chain Bankruptcies ----
cat("\n=== Identifying Chain Bankruptcy Events ===\n")

chain_patterns <- list(
  ap_pathmark = list(
    pattern = "A&P|A ?& ?P|Pathmark|Waldbaum|Food Emporium|Super Fresh",
    bankruptcy_year = 2015,
    description = "A&P/Pathmark Ch.11 (2015)"
  ),
  tops = list(
    pattern = "^Tops\\b|Tops Markets|Tops Friendly",
    bankruptcy_year = 2018,
    description = "Tops Markets Ch.11 (2018)"
  ),
  southeastern = list(
    pattern = "Winn.Dixie|Winn Dixie|BI.LO|Bi-Lo|Harveys",
    bankruptcy_year = 2018,
    description = "Southeastern Grocers Ch.11 (2018)"
  ),
  luckys = list(
    pattern = "Lucky.s Market|Luckys Market",
    bankruptcy_year = 2020,
    description = "Lucky's Market closure (2020)"
  ),
  earth_fare = list(
    pattern = "Earth Fare",
    bankruptcy_year = 2020,
    description = "Earth Fare closure (2020)"
  )
)

snap[, chain_bankruptcy := ""]
snap[, bankruptcy_year_chain := NA_integer_]

for (chain_name in names(chain_patterns)) {
  chain <- chain_patterns[[chain_name]]
  matches <- grepl(chain$pattern, snap$store_name, ignore.case = TRUE)
  snap[matches, chain_bankruptcy := chain_name]
  snap[matches, bankruptcy_year_chain := chain$bankruptcy_year]
  n_match <- sum(matches)
  n_super <- sum(matches & snap$supermarket == 1)
  n_closed <- sum(matches & !is.na(snap$end_year))
  cat(sprintf("  %s: %d stores (%d supermarket-class), %d closed\n",
              chain$description, n_match, n_super, n_closed))
}

cat(sprintf("\nTotal chain bankruptcy stores: %d\n",
            sum(snap$chain_bankruptcy != "")))


## ---- 3. Construct State-Year Supermarket Panel ----
cat("\n=== Constructing State-Year Supermarket Panel ===\n")

supers <- snap[supermarket == 1]
states <- unique(supers$state_fips)
years <- 2014:2023

panel <- CJ(state_fips = states, year = years)

# For each state-year: count active supermarkets, exits, chain closures
for (yr in years) {
  # Active supermarkets
  active <- supers[auth_year <= yr & (is.na(end_year) | end_year >= yr)]
  active_ct <- active[, .(n_supermarkets = .N), by = state_fips]

  # Supermarket exits this year
  exits <- supers[end_year == yr]
  exit_ct <- exits[, .(super_exits = .N), by = state_fips]

  # Chain bankruptcy closures this year
  chain_exits <- supers[chain_bankruptcy != "" & end_year == yr]
  chain_ct <- chain_exits[, .(chain_closures = .N), by = state_fips]

  panel[year == yr, n_supermarkets := active_ct[match(
    panel[year == yr, state_fips], active_ct$state_fips), n_supermarkets]]
  panel[year == yr, super_exits := exit_ct[match(
    panel[year == yr, state_fips], exit_ct$state_fips), super_exits]]
  panel[year == yr, chain_closures := chain_ct[match(
    panel[year == yr, state_fips], chain_ct$state_fips), chain_closures]]
}

panel[is.na(n_supermarkets), n_supermarkets := 0]
panel[is.na(super_exits), super_exits := 0]
panel[is.na(chain_closures), chain_closures := 0]

# Cumulative exits and treatment variables
panel[order(state_fips, year), cum_exits := cumsum(super_exits), by = state_fips]
panel[, post_exit := as.integer(cum_exits > 0)]

# Exit rate per 1000 supermarkets (intensive margin)
panel[, exit_rate := fifelse(n_supermarkets > 0,
                              super_exits / n_supermarkets * 1000, 0)]

# IV: pre-existing chain presence × post-bankruptcy
for (chain_name in names(chain_patterns)) {
  chain <- chain_patterns[[chain_name]]
  bk_yr <- chain$bankruptcy_year

  # States with this chain before bankruptcy
  pre_stores <- supers[chain_bankruptcy == chain_name & auth_year < bk_yr]
  pre_count <- pre_stores[, .(pre_chain_count = .N), by = state_fips]

  iv_name <- paste0("iv_", chain_name)
  iv_intensity <- paste0("iv_intensity_", chain_name)

  panel[, (iv_name) := as.integer(
    state_fips %in% pre_count$state_fips & year >= bk_yr)]

  # Intensity: pre-existing store count × post
  panel <- merge(panel, pre_count, by = "state_fips", all.x = TRUE)
  panel[is.na(pre_chain_count), pre_chain_count := 0]
  panel[, (iv_intensity) := fifelse(year >= bk_yr, pre_chain_count, 0L)]
  panel[, pre_chain_count := NULL]
}

# Combined IV: total pre-existing chain exposure × post-bankruptcy
iv_int_cols <- names(panel)[grepl("^iv_intensity_", names(panel))]
panel[, iv_chain_intensity := rowSums(.SD), .SDcols = iv_int_cols]

# Binary: any chain exposure
iv_bin_cols <- names(panel)[grepl("^iv_", names(panel)) &
                             !grepl("intensity", names(panel))]
panel[, iv_any_chain := as.integer(rowSums(.SD) > 0), .SDcols = iv_bin_cols]

cat(sprintf("Panel: %d state-year obs\n", nrow(panel)))
cat(sprintf("States: %d\n", length(unique(panel$state_fips))))
cat(sprintf("States with any chain exposure: %d\n",
            length(unique(panel[iv_any_chain == 1, state_fips]))))
cat(sprintf("States with any super exit: %d\n",
            length(unique(panel[cum_exits > 0, state_fips]))))


## ---- 4. Merge with Natality ----
cat("\n=== Merging with Natality ===\n")

natality <- fread(file.path(data_dir, "natality_state_year.csv"))
cat(sprintf("Natality: %d state-year obs\n", nrow(natality)))

# Ensure consistent types for merge keys (fread may read numeric-looking strings as integer)
panel[, state_fips := sprintf("%02s", as.character(state_fips))]
natality[, state_fips := sprintf("%02s", as.character(state_fips))]
cat(sprintf("Panel state_fips class: %s, Natality state_fips class: %s\n",
            class(panel$state_fips), class(natality$state_fips)))

# Compute rates as percentages
natality[, `:=`(
  lbw_rate_100 = lbw_rate * 100,
  preterm_rate_100 = preterm_rate * 100,
  csection_rate_100 = csection_rate * 100,
  medicaid_share_100 = medicaid_share * 100
)]

analysis <- merge(panel, natality, by = c("state_fips", "year"), all = FALSE)


## ---- 5. Merge Unemployment ----
unemp_file <- file.path(data_dir, "state_unemployment.csv")
if (file.exists(unemp_file)) {
  unemp <- fread(unemp_file)
  unemp[, state_fips := sprintf("%02s", as.character(state_fips))]
  analysis <- merge(analysis, unemp, by = c("state_fips", "year"), all.x = TRUE)
  cat(sprintf("Unemployment merged: %d obs with unemp data\n",
              sum(!is.na(analysis$unemp_rate))))
} else {
  analysis[, unemp_rate := NA_real_]
  cat("WARNING: No unemployment data available.\n")
}

## ---- 6. Merge State Population ----
pop_file <- file.path(data_dir, "state_population.csv")
if (file.exists(pop_file)) {
  pop <- fread(pop_file)
  pop[, state_fips := sprintf("%02s", as.character(state_fips))]
  analysis <- merge(analysis, pop[, .(state_fips, population)],
                    by = "state_fips", all.x = TRUE)
}

## ---- 7. Create Additional Variables ----
# First exit year per state
analysis[, first_exit_year := fifelse(
  any(super_exits > 0), min(year[super_exits > 0]), NA_integer_),
  by = state_fips]
analysis[, ever_treated := as.integer(!is.na(first_exit_year))]
analysis[, rel_time := year - first_exit_year]

# Supermarket exits per 100K population
analysis[, exits_per_100k := fifelse(
  !is.na(population) & population > 0,
  super_exits / population * 100000, 0)]

# High vs low Medicaid share (for heterogeneity)
median_medicaid <- median(analysis$medicaid_share, na.rm = TRUE)
analysis[, high_medicaid := as.integer(medicaid_share >= median_medicaid)]

## ---- Summary ----
cat(sprintf("\n=== Final Analysis Dataset ===\n"))
cat(sprintf("Observations: %d\n", nrow(analysis)))
cat(sprintf("States: %d\n", length(unique(analysis$state_fips))))
cat(sprintf("Years: %s\n", paste(sort(unique(analysis$year)), collapse = ", ")))
cat(sprintf("Mean LBW rate: %.2f%%\n", mean(analysis$lbw_rate_100, na.rm = TRUE)))
cat(sprintf("Mean preterm rate: %.2f%%\n", mean(analysis$preterm_rate_100, na.rm = TRUE)))
cat(sprintf("Mean supermarkets per state: %.0f\n", mean(analysis$n_supermarkets)))
cat(sprintf("Mean exits per state-year: %.1f\n", mean(analysis$super_exits)))
cat(sprintf("States with chain exposure: %d\n",
            length(unique(analysis[iv_any_chain == 1, state_fips]))))

fwrite(analysis, file.path(data_dir, "analysis_panel.csv"))
cat("\nAnalysis panel saved to data/analysis_panel.csv\n")
