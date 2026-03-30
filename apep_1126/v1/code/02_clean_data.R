## ============================================================================
## 02_clean_data.R — Panel construction for apep_1126
## Memory-efficient: processes one year at a time (8GB RAM constraint)
## ============================================================================

source("00_packages.R")

DATA <- "../data"

## ---- 1. Load border county mapping ----
border_dt <- fread(file.path(DATA, "border_counties.csv"))
border_states <- c("WA", "ID", "MT", "ND", "MN", "MI", "OH", "PA", "NY", "VT", "NH", "ME")
border_state_fips <- c("53","16","30","38","27","26","39","42","36","50","33","23")

cat(sprintf("Border counties: %d, Interior: %d\n",
            sum(border_dt$is_border), sum(!border_dt$is_border)))

## ---- 2. Process UCR drug arrests one year at a time ----
cat("=== Processing UCR Drug Arrest Data (year by year) ===\n")
drug_dir <- file.path(DATA, "ucr_drug")
drug_files <- list.files(drug_dir, pattern = "\\.rds$", full.names = TRUE)

county_quarter_list <- list()

for (f in drug_files) {
  yr <- as.integer(gsub(".*_(\\d{4})\\.rds$", "\\1", basename(f)))
  cat(sprintf("  Processing %d...\n", yr))

  dt <- as.data.table(readRDS(f))
  cat(sprintf("    Loaded: %s rows, %d cols\n", format(nrow(dt), big.mark=","), ncol(dt)))

  ## Identify FIPS and state columns
  if (!"fips_state_county_code" %in% names(dt)) {
    ## Try alternative column names
    fips_candidates <- grep("fips|county_code", names(dt), value = TRUE, ignore.case = TRUE)
    cat(sprintf("    FIPS candidates: %s\n", paste(fips_candidates, collapse = ", ")))
    if (length(fips_candidates) > 0) {
      setnames(dt, fips_candidates[1], "fips_state_county_code")
    } else {
      cat("    WARNING: No FIPS column found. Skipping year.\n")
      next
    }
  }

  ## Filter to border states early to save memory
  if ("state_abb" %in% names(dt)) {
    dt <- dt[state_abb %in% border_states]
  } else if ("fips_state_code" %in% names(dt)) {
    dt <- dt[fips_state_code %in% as.integer(border_state_fips)]
  }
  cat(sprintf("    After state filter: %s rows\n", format(nrow(dt), big.mark=",")))

  ## Filter to valid FIPS
  dt <- dt[!is.na(fips_state_county_code) &
           nchar(as.character(fips_state_county_code)) >= 4]

  ## Drug arrest total = possession total + sale total (across all drug types, both sexes)
  ## Column pattern: drug_{possess|sale}_drug_total_total_{male|female}
  poss_male_col <- "drug_possess_drug_total_total_male"
  poss_female_col <- "drug_possess_drug_total_total_female"
  sale_male_col <- "drug_sale_drug_total_total_male"
  sale_female_col <- "drug_sale_drug_total_total_female"

  ## Check which columns exist
  has_poss <- poss_male_col %in% names(dt) && poss_female_col %in% names(dt)
  has_sale <- sale_male_col %in% names(dt) && sale_female_col %in% names(dt)

  if (has_poss || has_sale) {
    dt[, drug_arrests := 0]
    if (has_poss) {
      dt[, drug_arrests := drug_arrests +
           as.numeric(get(poss_male_col)) + as.numeric(get(poss_female_col))]
    }
    if (has_sale) {
      dt[, drug_arrests := drug_arrests +
           as.numeric(get(sale_male_col)) + as.numeric(get(sale_female_col))]
    }
    cat(sprintf("    Total drug arrests computed (possess=%s, sale=%s)\n",
                ifelse(has_poss, "yes", "no"), ifelse(has_sale, "yes", "no")))
    cat(sprintf("    Mean arrests per agency-month: %.1f\n",
                mean(dt$drug_arrests, na.rm = TRUE)))
  } else {
    cat("    WARNING: Cannot find drug arrest columns. Saving sample.\n")
    saveRDS(head(dt, 50), file.path(DATA, sprintf("drug_sample_%d.rds", yr)))
    next
  }

  ## Get month and population
  if (!"month" %in% names(dt)) {
    month_cols <- grep("month", names(dt), value = TRUE, ignore.case = TRUE)
    if (length(month_cols) > 0) setnames(dt, month_cols[1], "month")
  }

  pop_col <- "population"
  if (!pop_col %in% names(dt)) {
    pop_cols <- grep("population|pop", names(dt), value = TRUE, ignore.case = TRUE)
    if (length(pop_cols) > 0) pop_col <- pop_cols[1]
  }

  ## Pad FIPS to 5 digits
  dt[, fips := sprintf("%05d", as.integer(fips_state_county_code))]

  ## Convert month text to number
  month_map <- c("january"=1, "february"=2, "march"=3, "april"=4,
                 "may"=5, "june"=6, "july"=7, "august"=8,
                 "september"=9, "october"=10, "november"=11, "december"=12)
  dt[, month_num := month_map[tolower(month)]]
  dt[, quarter := ceiling(month_num / 3)]
  dt[, reporting_pop := as.numeric(get(pop_col))]

  ## Get state_abb if not present
  if (!"state_abb" %in% names(dt)) {
    dt[, state_abb := NA_character_]
  }

  ## Aggregate to county-quarter
  cq <- dt[,
    .(drug_arrests = sum(drug_arrests, na.rm = TRUE),
      reporting_pop = sum(reporting_pop, na.rm = TRUE),
      n_agencies = .N),
    by = .(fips, state_abb, quarter)
  ]
  cq[, file_year := yr]
  cq[, year_quarter := sprintf("%dQ%d", yr, quarter)]

  county_quarter_list[[as.character(yr)]] <- cq

  ## Free memory
  rm(dt, cq)
  gc(verbose = FALSE)
}

## Combine all years
county_quarter <- rbindlist(county_quarter_list, fill = TRUE)
rm(county_quarter_list)
gc(verbose = FALSE)

cat(sprintf("\n=== County-quarter panel: %s rows, %d counties ===\n",
            format(nrow(county_quarter), big.mark = ","),
            uniqueN(county_quarter$fips)))

## ---- 3. Compute drug arrest rate ----
county_quarter[, drug_rate := (drug_arrests / reporting_pop) * 100000]
county_quarter[reporting_pop == 0 | is.na(reporting_pop), drug_rate := NA_real_]

## ---- 4. Merge border status ----
border_dt[, fips := as.character(fips)]
county_quarter[, fips := as.character(fips)]
county_quarter <- merge(county_quarter, border_dt[, .(fips, is_border)],
                        by = "fips", all.x = TRUE)
county_quarter[is.na(is_border), is_border := FALSE]

## Get state_abb from FIPS if missing
county_quarter[is.na(state_abb) | state_abb == "",
               state_abb := border_dt$state[match(fips, border_dt$fips)]]

cat(sprintf("Border counties in panel: %d\n",
            uniqueN(county_quarter[is_border == TRUE, fips])))
cat(sprintf("Interior counties in panel: %d\n",
            uniqueN(county_quarter[is_border == FALSE, fips])))

## ---- 5. Merge BTS crossing exposure ----
cat("\n=== Constructing crossing exposure ===\n")
bts <- fread(file.path(DATA, "bts_border_crossings.csv"))

## Parse date and filter pre-2018
bts[, date := as.Date(date)]
bts[, year := year(date)]
bts_pre <- bts[year >= 2014 & year <= 2017]

## Get total crossings by port with coordinates
port_volume <- bts_pre[,
  .(total_crossings = sum(as.numeric(value), na.rm = TRUE),
    port_lat = as.numeric(latitude[1]),
    port_lon = as.numeric(longitude[1])),
  by = .(port_name, state)
]
port_volume <- port_volume[!is.na(port_lat) & total_crossings > 0]
cat(sprintf("Ports with pre-2018 data: %d\n", nrow(port_volume)))

## Map port state names to abbreviations
state_map <- c(
  "Washington" = "WA", "Idaho" = "ID", "Montana" = "MT",
  "North Dakota" = "ND", "Minnesota" = "MN", "Michigan" = "MI",
  "Ohio" = "OH", "Pennsylvania" = "PA", "New York" = "NY",
  "Vermont" = "VT", "New Hampshire" = "NH", "Maine" = "ME"
)
port_volume[, state_abb := state_map[state]]

## For border counties: compute state-level total crossing volume
## (simpler and more robust than port-to-county distance mapping for V1)
state_exposure <- port_volume[!is.na(state_abb),
  .(state_crossings = sum(total_crossings)),
  by = state_abb
]

## Merge state-level exposure
county_quarter <- merge(county_quarter, state_exposure,
                        by = "state_abb", all.x = TRUE)
county_quarter[is.na(state_crossings), state_crossings := 0]

## Crossing exposure: only for border counties
county_quarter[, crossing_exposure := ifelse(is_border, log1p(state_crossings), 0)]
county_quarter[, exposure_std := (crossing_exposure - mean(crossing_exposure, na.rm=TRUE)) /
                 sd(crossing_exposure, na.rm=TRUE)]

## ---- 6. Create regime indicators ----
cat("\n=== Creating regime indicators ===\n")

county_quarter[, year_q := file_year + (quarter - 1) / 4]

## Regime coding
county_quarter[, regime := "pre"]
county_quarter[file_year > 2018 | (file_year == 2018 & quarter == 4), regime := "post_legal"]
county_quarter[file_year >= 2020 & file_year < 2022, regime := "covid_closed"]
county_quarter[file_year >= 2022, regime := "post_reopen"]

county_quarter[, post_legal := as.integer(regime != "pre")]
county_quarter[, covid_closed := as.integer(regime == "covid_closed")]
county_quarter[, post_reopen := as.integer(regime == "post_reopen")]

## Event time (quarters relative to 2018Q4)
county_quarter[, event_time := (file_year - 2018) * 4 + (quarter - 4)]

cat("Regime distribution:\n")
print(county_quarter[, .N, by = regime])

## ---- 7. Coverage quality check ----
cat("\n=== Coverage quality check ===\n")
n_total_quarters <- uniqueN(county_quarter$year_quarter)
coverage <- county_quarter[,
  .(n_quarters = .N,
    n_reporting = sum(reporting_pop > 0, na.rm = TRUE)),
  by = .(fips, is_border)
]
coverage[, pct_reporting := n_reporting / n_total_quarters]

high_coverage <- coverage[pct_reporting >= 0.9, fips]
county_quarter[, high_coverage := fips %in% high_coverage]

cat(sprintf("Total quarters: %d\n", n_total_quarters))
cat(sprintf("Median reporting coverage: %.1f%%\n",
            median(coverage$pct_reporting, na.rm = TRUE) * 100))
cat(sprintf("High-coverage counties: %d / %d\n",
            length(high_coverage), nrow(coverage)))
cat(sprintf("High-coverage border: %d\n",
            uniqueN(county_quarter[is_border == TRUE & high_coverage == TRUE, fips])))

## ---- 8. Write diagnostics ----
n_border_hc <- uniqueN(county_quarter[is_border == TRUE & high_coverage == TRUE, fips])
n_pre <- uniqueN(county_quarter[regime == "pre", year_quarter])
n_obs_hc <- nrow(county_quarter[high_coverage == TRUE & !is.na(drug_rate)])

diagnostics <- list(
  n_treated = n_border_hc,
  n_pre = n_pre,
  n_obs = n_obs_hc,
  n_total_counties = uniqueN(county_quarter$fips),
  n_border_counties = uniqueN(county_quarter[is_border == TRUE, fips]),
  n_high_coverage = length(high_coverage),
  sd_drug_rate = sd(county_quarter[high_coverage == TRUE]$drug_rate, na.rm = TRUE)
)
jsonlite::write_json(diagnostics, file.path(DATA, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("\nDiagnostics:\n"))
cat(sprintf("  Treated (border, high-coverage): %d\n", diagnostics$n_treated))
cat(sprintf("  Pre-periods: %d\n", diagnostics$n_pre))
cat(sprintf("  Total obs (high-coverage): %s\n",
            format(diagnostics$n_obs, big.mark = ",")))
cat(sprintf("  SD(drug_rate): %.2f\n", diagnostics$sd_drug_rate))

## ---- 9. Save panel ----
panel_path <- file.path(DATA, "county_quarter_panel.parquet")
write_parquet(county_quarter, panel_path)
cat(sprintf("\nPanel saved: %s (%s rows)\n", panel_path,
            format(nrow(county_quarter), big.mark = ",")))

cat("\n=== Panel construction complete ===\n")
