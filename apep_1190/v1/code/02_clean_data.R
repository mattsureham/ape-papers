## 02_clean_data.R — Construct analysis panel
## apep_1190: SNAP Retailer Exits and Birth Outcomes
##
## Merges: CBP grocery establishments × CHR birth outcomes × ACS demographics
## Constructs: treatment variables, chain bankruptcy IV

source("00_packages.R")
data_dir <- "../data"

# ============================================================================
# 1. PARSE COUNTY HEALTH RANKINGS DATA
# ============================================================================
cat("=== Parsing County Health Rankings ===\n")

chr_files <- list.files(data_dir, pattern = "^chr_\\d{4}\\.csv$", full.names = TRUE)
chr_list <- list()

for (f in chr_files) {
  yr <- as.integer(gsub(".*chr_(\\d{4})\\.csv$", "\\1", f))
  cat(sprintf("  CHR %d: ", yr))

  # CHR files have 2 header rows: human-readable names + variable codes
  # Read header from row 1, then skip both header rows for data
  df <- tryCatch({
    hdr <- fread(f, nrows = 0, header = TRUE)
    tmp <- fread(f, skip = 2, header = FALSE, fill = TRUE, showProgress = FALSE)
    names(tmp) <- names(hdr)
    tmp
  }, error = function(e) {
    cat(sprintf("parse error: %s\n", e$message))
    NULL
  })

  if (is.null(df)) next

  # Use exact column names (confirmed from data inspection)
  fips_col <- "5-digit FIPS Code"

  # Build output using exact column names
  out <- data.table(
    fips = as.character(df[[fips_col]]),
    chr_year = yr
  )

  # Safe column extraction
  safe_col <- function(df, pattern) {
    cols <- names(df)
    matched <- grep(pattern, cols, ignore.case = TRUE, value = TRUE)
    if (length(matched) > 0) as.numeric(df[[matched[1]]]) else rep(NA_real_, nrow(df))
  }

  out$lbw_rate <- safe_col(df, "^Low birthweight raw value$")
  out$lbw_numerator <- safe_col(df, "^Low birthweight numerator$")
  out$lbw_denominator <- safe_col(df, "^Low birthweight denominator$")
  out$infant_mort_rate <- safe_col(df, "^Infant mortality raw value$")
  out$im_numerator <- safe_col(df, "^Infant mortality numerator$")
  out$im_denominator <- safe_col(df, "^Infant mortality denominator$")
  out$teen_birth_rate <- safe_col(df, "^Teen births raw value$")
  out$premature_death_rate <- safe_col(df, "^Premature death raw value$")
  out$lbw_rate_black <- safe_col(df, "^Low birthweight \\(Black\\)$")
  out$lbw_rate_white <- safe_col(df, "^Low birthweight \\(White\\)$")
  out$lbw_rate_hispanic <- safe_col(df, "^Low birthweight \\(Hispanic\\)$")

  # Zero-pad FIPS (CHR stores as integer, e.g. 1001 instead of "01001")
  out[, fips := sprintf("%05d", as.integer(fips))]
  # Filter to valid county FIPS (not "00000" national or "XX000" state)
  out <- out[fips != "00000" & !grepl("000$", fips) & !is.na(lbw_rate)]

  chr_list[[as.character(yr)]] <- out
  cat(sprintf("%d counties with LBW data\n", nrow(out)))
}

chr <- rbindlist(chr_list, fill = TRUE)
cat(sprintf("CHR panel: %d county-years, %d unique counties\n",
            nrow(chr), uniqueN(chr$fips)))

# CHR release year corresponds to data 2 years earlier
# e.g., CHR 2020 release uses 2016-2018 birth data (centered on 2017)
# But for our purposes, we'll use release year as approximate data year
chr[, data_year := chr_year - 2]

# ============================================================================
# 2. LOAD CBP GROCERY DATA
# ============================================================================
cat("\n=== Loading CBP Grocery Data ===\n")

cbp <- fread(file.path(data_dir, "cbp_grocery_4451.csv"))
cat(sprintf("CBP: %d county-years, %d unique counties, years %d-%d\n",
            nrow(cbp), uniqueN(cbp$fips),
            min(cbp$year), max(cbp$year)))

# Ensure fips is 5-digit string
cbp[, fips := sprintf("%05s", fips)]

# ============================================================================
# 3. CONSTRUCT TREATMENT: GROCERY STORE EXITS
# ============================================================================
cat("\n=== Constructing Treatment Variables ===\n")

# For each county, compute year-over-year change in grocery establishments
cbp_wide <- cbp %>%
  arrange(fips, year) %>%
  group_by(fips) %>%
  mutate(
    estab_lag = lag(estab),
    estab_change = estab - estab_lag,
    estab_pct_change = ifelse(estab_lag > 0, estab_change / estab_lag, NA),
    # Significant exit: lost ≥20% of grocery stores OR lost ≥2 stores
    significant_exit = (estab_change <= -2) | (estab_pct_change <= -0.20 & !is.na(estab_pct_change)),
    # First year of significant exit
    cum_exit = cumsum(coalesce(significant_exit, FALSE))
  ) %>%
  ungroup()

# Identify treatment timing: first significant exit year
first_exit <- cbp_wide %>%
  filter(significant_exit == TRUE) %>%
  group_by(fips) %>%
  summarize(first_exit_year = min(year), .groups = "drop")

cat(sprintf("Counties with significant grocery exits: %d\n", nrow(first_exit)))
cat("Exit year distribution:\n")
print(table(first_exit$first_exit_year))

# ============================================================================
# 4. CONSTRUCT IV: CHAIN BANKRUPTCY EXPOSURE
# ============================================================================
cat("\n=== Constructing Chain Bankruptcy IV ===\n")

# Major grocery chain bankruptcies/closures:
# - A&P / Pathmark: Filed Nov 2015, closed 2015-2016. ~300 stores (NE, Mid-Atlantic)
# - Tops Friendly Markets: Filed Feb 2018. ~170 stores (NY, PA, VT)
# - Southeastern Grocers (Winn-Dixie/Bi-Lo): Filed Mar 2018. ~100 closures (SE US)
# - Lucky's Market (Kroger sold): Jan 2020. ~30 stores closed
# - Earth Fare: Feb 2020. ~50 stores closed

# State-level exposure based on chain geographic footprint (pre-period presence)
# A&P operated in: CT, NJ, NY, PA, DE, MD
# Tops operated in: NY, PA, VT
# Winn-Dixie/Bi-Lo: FL, GA, SC, NC, AL, MS, LA
# Lucky's: FL, CO, MI, MT, OH, WY, MO
# Earth Fare: FL, GA, IN, KY, NC, OH, SC, TN, VA

# Construct state-level chain exposure indicator
chain_exposure <- data.table(
  state_fips = c(
    # A&P states (heavy presence, bankruptcy 2015)
    "09", "34", "36", "42", "10", "24",
    # Tops states (bankruptcy 2018)
    "36", "42", "50",
    # Winn-Dixie/Bi-Lo states (bankruptcy 2018)
    "12", "13", "45", "37", "01", "28", "22",
    # Lucky's/Earth Fare states (closures 2020)
    "12", "08", "26", "30", "39", "56", "29",
    "13", "18", "21", "37", "39", "45", "47", "51"
  ),
  chain = c(
    rep("ap", 6),
    rep("tops", 3),
    rep("winn_dixie", 7),
    rep("luckys", 7),
    rep("earth_fare", 8)
  ),
  shock_year = c(
    rep(2015, 6),
    rep(2018, 3),
    rep(2018, 7),
    rep(2020, 7),
    rep(2020, 8)
  )
)

# Count number of chain shocks per state
chain_by_state <- chain_exposure %>%
  group_by(state_fips) %>%
  summarize(
    n_chains_exposed = n_distinct(chain),
    earliest_shock = min(shock_year),
    ap_exposed = any(chain == "ap"),
    tops_exposed = any(chain == "tops"),
    winn_dixie_exposed = any(chain == "winn_dixie"),
    .groups = "drop"
  )

cat(sprintf("States with chain exposure: %d\n", nrow(chain_by_state)))

# Merge chain exposure to counties (via state FIPS prefix)
cbp_wide$state_fips <- substr(cbp_wide$fips, 1, 2)

cbp_panel <- cbp_wide %>%
  left_join(chain_by_state, by = "state_fips") %>%
  mutate(
    n_chains_exposed = coalesce(n_chains_exposed, 0L),
    ap_exposed = coalesce(ap_exposed, FALSE),
    tops_exposed = coalesce(tops_exposed, FALSE),
    winn_dixie_exposed = coalesce(winn_dixie_exposed, FALSE),
    # IV: Post-bankruptcy × chain exposure
    # For each chain, create post × exposed interaction
    ap_post = as.integer(ap_exposed & year >= 2016),
    tops_post = as.integer(tops_exposed & year >= 2019),
    wd_post = as.integer(winn_dixie_exposed & year >= 2019),
    # Combined IV: any chain bankruptcy shock
    any_chain_post = as.integer(ap_post | tops_post | wd_post),
    # Continuous IV: number of chains that have gone bankrupt in this state by year t
    chain_shocks_cumulative = ap_post + tops_post + wd_post
  )

# ============================================================================
# 5. LOAD ACS DEMOGRAPHICS
# ============================================================================
cat("\n=== Loading ACS Demographics ===\n")

acs <- fread(file.path(data_dir, "acs_county_demographics.csv"))
acs[, fips := sprintf("%05s", fips)]

# For each year in our panel, match to nearest ACS year
acs[, year := acs_year]
cat(sprintf("ACS: %d county-years\n", nrow(acs)))

# ============================================================================
# 6. MERGE ALL SOURCES
# ============================================================================
cat("\n=== Merging panel ===\n")

# CBP panel is the backbone (2012-2022)
# CHR data_year maps to approximate natality data year
# ACS merges on closest year

# First merge CBP with CHR
# CHR data_year is chr_year - 2 (e.g., CHR 2020 ≈ data from 2017)
chr_merge <- chr[, .(fips, data_year, lbw_rate, lbw_numerator, lbw_denominator,
                      infant_mort_rate, im_numerator, im_denominator,
                      teen_birth_rate, premature_death_rate,
                      lbw_rate_black, lbw_rate_white, lbw_rate_hispanic)]

panel <- cbp_panel %>%
  as.data.table() %>%
  merge(chr_merge, by.x = c("fips", "year"), by.y = c("fips", "data_year"),
        all.x = TRUE)

# Merge ACS (use same year; ACS 5-year is centered on that year)
panel <- merge(panel, acs[, .(fips, year, med_income, poverty_rate, total_pop)],
               by = c("fips", "year"), all.x = TRUE)

# Forward-fill ACS for years without data
panel <- panel[order(fips, year)]
panel[, `:=`(
  med_income = nafill(med_income, type = "locf"),
  poverty_rate = nafill(poverty_rate, type = "locf"),
  total_pop = nafill(total_pop, type = "locf")
), by = fips]

# ============================================================================
# 7. FINAL SAMPLE RESTRICTIONS
# ============================================================================
cat("\n=== Applying sample restrictions ===\n")

# Restrict to counties with:
# - At least 5 years of CBP data
# - At least some LBW data
# - Population > 10K (meaningful grocery store market)
county_coverage <- panel[, .(
  n_years = .N,
  n_lbw = sum(!is.na(lbw_rate)),
  mean_pop = mean(total_pop, na.rm = TRUE),
  mean_estab = mean(estab, na.rm = TRUE)
), by = fips]

valid_counties <- county_coverage[n_years >= 5 & n_lbw >= 1 &
                                    mean_pop > 10000 & mean_estab > 0]$fips

panel_final <- panel[fips %in% valid_counties]

cat(sprintf("Final panel: %d county-years, %d unique counties\n",
            nrow(panel_final), uniqueN(panel_final$fips)))
if (nrow(panel_final) > 0) {
  cat(sprintf("Years: %d-%d\n", min(panel_final$year), max(panel_final$year)))
} else {
  cat("WARNING: Panel is empty!\n")
  # Debug: show what went wrong
  cat(sprintf("Counties with >=5 years CBP: %d\n", sum(county_coverage$n_years >= 5)))
  cat(sprintf("Counties with any LBW: %d\n", sum(county_coverage$n_lbw >= 1)))
  cat(sprintf("Counties with pop>10K: %d\n", sum(county_coverage$mean_pop > 10000, na.rm = TRUE)))
  cat(sprintf("Counties with estab>0: %d\n", sum(county_coverage$mean_estab > 0, na.rm = TRUE)))
  cat(sprintf("Counties meeting all: %d\n", length(valid_counties)))
}
cat(sprintf("Counties with exit events: %d\n",
            sum(panel_final$fips %in% first_exit$fips)))
cat(sprintf("Counties in chain-exposed states: %d\n",
            sum(panel_final[, any(n_chains_exposed > 0), by = fips]$V1)))
cat(sprintf("Mean grocery establishments: %.1f\n",
            mean(panel_final$estab, na.rm = TRUE)))
cat(sprintf("Mean LBW rate: %.4f\n",
            mean(panel_final$lbw_rate, na.rm = TRUE)))

# Add event time for event study
panel_final <- merge(panel_final, first_exit, by = "fips", all.x = TRUE)
panel_final[, event_time := year - first_exit_year]
panel_final[, treated := !is.na(first_exit_year)]
panel_final[, post := as.integer(!is.na(event_time) & event_time >= 0)]

# ============================================================================
# 8. SAVE
# ============================================================================
fwrite(panel_final, file.path(data_dir, "analysis_panel.csv"))

cat(sprintf("\n=== Panel saved: %d obs, %d counties, %d treated ===\n",
            nrow(panel_final), uniqueN(panel_final$fips),
            sum(panel_final$treated[!duplicated(panel_final$fips)])))

# Summary stats
cat("\n=== Summary Statistics ===\n")
cat(sprintf("LBW rate (non-missing): mean=%.4f, sd=%.4f, n=%d\n",
            mean(panel_final$lbw_rate, na.rm = TRUE),
            sd(panel_final$lbw_rate, na.rm = TRUE),
            sum(!is.na(panel_final$lbw_rate))))
cat(sprintf("Grocery establishments: mean=%.1f, sd=%.1f\n",
            mean(panel_final$estab, na.rm = TRUE),
            sd(panel_final$estab, na.rm = TRUE)))
cat(sprintf("Infant mortality (non-missing): mean=%.2f, n=%d\n",
            mean(panel_final$infant_mort_rate, na.rm = TRUE),
            sum(!is.na(panel_final$infant_mort_rate))))
