## 01b_process_natality.R — Process natality microdata to county-year panel
## apep_1190: SNAP Retailer Exits and Birth Outcomes

source("00_packages.R")
data_dir <- "../data"

# Process any raw natality files that exist
cat("=== Processing CDC Natality Microdata ===\n")

raw_files <- list.files(data_dir, pattern = "^natl\\d{4}\\.csv$", full.names = TRUE)
cat(sprintf("Found %d raw natality files\n", length(raw_files)))

nat_county_list <- list()

for (f in raw_files) {
  yr <- as.integer(gsub(".*natl(\\d{4})\\.csv$", "\\1", f))
  agg_file <- file.path(data_dir, sprintf("natl%d_county.csv", yr))

  if (file.exists(agg_file)) {
    cat(sprintf("  %d: already aggregated, loading...\n", yr))
    nat_county_list[[as.character(yr)]] <- fread(agg_file)
    next
  }

  cat(sprintf("  %d: reading & aggregating... ", yr))

  dt <- fread(f, select = c("dob_yy", "mrcnty", "mrstfip",
                              "dbwt", "gestrec3", "gestrec10",
                              "pay_rec", "dmeth_rec"),
              showProgress = FALSE)

  setnames(dt, tolower(names(dt)))
  dt[, fips := sprintf("%02d%03d", as.integer(mrstfip), as.integer(mrcnty))]
  dt <- dt[as.integer(mrcnty) > 0 & !is.na(dbwt) & dbwt < 9999]

  county_yr <- dt[, .(
    births = .N,
    mean_bwt = mean(dbwt, na.rm = TRUE),
    sd_bwt = sd(dbwt, na.rm = TRUE),
    lbw_count = sum(dbwt < 2500, na.rm = TRUE),
    preterm_count = sum(gestrec3 == 2, na.rm = TRUE),
    csection_count = sum(dmeth_rec == 2, na.rm = TRUE),
    medicaid_births = sum(pay_rec == 1, na.rm = TRUE),
    private_births = sum(pay_rec == 2, na.rm = TRUE)
  ), by = .(fips, year = dob_yy)]

  county_yr[, `:=`(
    lbw_rate = lbw_count / births,
    preterm_rate = preterm_count / births,
    csection_rate = csection_count / births,
    medicaid_share = medicaid_births / births
  )]

  fwrite(county_yr, agg_file)
  nat_county_list[[as.character(yr)]] <- county_yr
  cat(sprintf("%d counties, %s births\n",
              uniqueN(county_yr$fips),
              format(sum(county_yr$births), big.mark = ",")))

  rm(dt); gc()
}

# Also load any pre-aggregated files
agg_files <- list.files(data_dir, pattern = "^natl\\d{4}_county\\.csv$", full.names = TRUE)
for (af in agg_files) {
  yr_str <- gsub(".*natl(\\d{4})_county\\.csv$", "\\1", af)
  if (!(yr_str %in% names(nat_county_list))) {
    nat_county_list[[yr_str]] <- fread(af)
  }
}

stopifnot("No natality data" = length(nat_county_list) > 0)

natality <- rbindlist(nat_county_list)
fwrite(natality, file.path(data_dir, "natality_county_panel.csv"))
cat(sprintf("\nFinal natality panel: %d county-years, %d counties, %s births\n",
            nrow(natality), uniqueN(natality$fips),
            format(sum(natality$births), big.mark = ",")))
cat(sprintf("Years covered: %s\n", paste(sort(unique(natality$year)), collapse = ", ")))
