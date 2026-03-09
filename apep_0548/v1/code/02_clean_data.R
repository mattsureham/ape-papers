## 02_clean_data.R — Construct analysis panel
## APEP-0548: Selective Licensing and Housing Markets in England

source("00_packages.R")

data_dir <- "../data"

## ===================================================================
## 1. LOAD DATA
## ===================================================================
cat("Loading Land Registry data...\n")
lr <- arrow::read_parquet(file.path(data_dir, "land_registry_england.parquet"))
setDT(lr)
cat("  ", nrow(lr), " transactions loaded\n")
cat("  Unique districts: ", n_distinct(lr$district), "\n")

## Licensing adoption dates
licensing <- fread(file.path(data_dir, "licensing_adoption_dates.csv"))

## Census 2021 PRS share at LA level
prs_file <- file.path(data_dir, "census_2021_prs_share_la.csv")
prs_la <- if (file.exists(prs_file)) fread(prs_file) else NULL

## ===================================================================
## 2. MATCH LICENSING DATES TO LAND REGISTRY DISTRICTS
## ===================================================================
cat("Matching licensing dates to Land Registry districts...\n")

## Standardize names
lr[, la_name := trimws(district)]
licensing[, la_name_lic := trimws(la_name)]

## Exact match first
lr[, la_name_lower := tolower(la_name)]
licensing[, la_name_lower := tolower(la_name_lic)]

## Check exact matches
matched <- intersect(licensing$la_name_lower, unique(lr$la_name_lower))
cat("  Exact name matches: ", length(matched), " / ", nrow(licensing), "\n")

## Merge treatment dates into transactions
lr_treat <- merge(lr,
                  licensing[, .(la_name_lower, licensing_start, licensing_year, licensing_qtr)],
                  by = "la_name_lower", all.x = TRUE)

## Show unmatched licensing LAs
unmatched_lic <- licensing[!la_name_lower %in% unique(lr$la_name_lower)]
if (nrow(unmatched_lic) > 0) {
  cat("  Unmatched licensing LAs:\n")
  for (i in seq_len(nrow(unmatched_lic))) {
    ## Try fuzzy match
    dists <- adist(unmatched_lic$la_name_lower[i], unique(lr$la_name_lower))
    best_idx <- which.min(dists)
    best_name <- unique(lr$la_name_lower)[best_idx]
    best_dist <- dists[best_idx]
    cat("    '", unmatched_lic$la_name[i], "' -> closest: '", best_name,
        "' (edit dist: ", best_dist, ")\n")

    if (best_dist <= 5) {
      lr_treat[la_name_lower == best_name,
               `:=`(licensing_start = unmatched_lic$licensing_start[i],
                    licensing_year = unmatched_lic$licensing_year[i],
                    licensing_qtr = unmatched_lic$licensing_qtr[i])]
      cat("      -> MATCHED\n")
    }
  }
}

## Create treatment variables
lr_treat[, treated_ever := !is.na(licensing_start)]
lr_treat[, treated := as.integer(treated_ever & date >= as.Date(licensing_start))]
lr_treat[is.na(treated), treated := 0L]
lr_treat[, cohort := fifelse(treated_ever, as.integer(licensing_year), 0L)]
lr_treat[is.na(cohort), cohort := 0L]

n_treated_la <- n_distinct(lr_treat[treated_ever == TRUE]$la_name)
n_control_la <- n_distinct(lr_treat[treated_ever == FALSE]$la_name)
cat("\nTreatment assignment:\n")
cat("  Ever-treated LAs: ", n_treated_la, "\n")
cat("  Never-treated LAs: ", n_control_la, "\n")
cat("  Treated transactions: ", sum(lr_treat$treated), "\n")
cat("  Control transactions: ", sum(lr_treat$treated == 0), "\n")

## ===================================================================
## 3. BUILD LA-QUARTER PANEL
## ===================================================================
cat("\nBuilding LA-quarter panel...\n")

lr_treat[, qtr_date := floor_date(date, "quarter")]
lr_treat[, log_price := log(price)]

## Property type labels
lr_treat[, ptype_label := fcase(
  ptype == "D", "Detached",
  ptype == "S", "Semi-detached",
  ptype == "T", "Terraced",
  ptype == "F", "Flat",
  default = "Other"
)]

## Aggregate to LA-quarter
la_qtr <- lr_treat[, .(
  mean_price = mean(price, na.rm = TRUE),
  median_price = median(price, na.rm = TRUE),
  mean_log_price = mean(log_price, na.rm = TRUE),
  sd_log_price = sd(log_price, na.rm = TRUE),
  n_transactions = .N,
  pct_detached = mean(ptype == "D", na.rm = TRUE),
  pct_flat = mean(ptype == "F", na.rm = TRUE),
  pct_terraced = mean(ptype == "T", na.rm = TRUE),
  pct_new = mean(oldnew == "Y", na.rm = TRUE)
), by = .(la_name, year, qtr_date, licensing_start, licensing_year,
          treated_ever, cohort)]

## Treatment indicator at LA-quarter level
la_qtr[, treated := as.integer(treated_ever & qtr_date >= as.Date(licensing_start))]
la_qtr[is.na(treated), treated := 0L]

cat("LA-quarter panel: ", nrow(la_qtr), " observations\n")
cat("  LAs: ", n_distinct(la_qtr$la_name), "\n")
cat("  Quarters: ", n_distinct(la_qtr$qtr_date), "\n")
cat("  Treated obs: ", sum(la_qtr$treated), "\n")

## ===================================================================
## 4. ADD PRS SHARE (DOSE VARIABLE)
## ===================================================================
if (!is.null(prs_la)) {
  cat("\nMerging Census 2021 PRS share...\n")
  ## Match by name (census la_name_census to lr la_name)
  prs_la[, la_name_lower := tolower(trimws(la_name_census))]

  la_qtr[, la_name_lower := tolower(trimws(la_name))]
  la_qtr <- merge(la_qtr, prs_la[, .(la_name_lower, prs_share)],
                  by = "la_name_lower", all.x = TRUE)

  ## For unmatched, try fuzzy
  unmatched_prs <- unique(la_qtr[is.na(prs_share)]$la_name_lower)
  available_prs <- prs_la$la_name_lower

  for (um in unmatched_prs) {
    dists <- adist(um, available_prs)
    best <- which.min(dists)
    if (dists[best] <= 3) {
      match_share <- prs_la$prs_share[best]
      la_qtr[la_name_lower == um, prs_share := match_share]
    }
  }

  prs_coverage <- mean(!is.na(la_qtr$prs_share))
  cat("  PRS share coverage: ", round(prs_coverage * 100, 1), "%\n")
  cat("  Mean PRS share: ", round(mean(la_qtr$prs_share, na.rm = TRUE), 3), "\n")

  la_qtr[, la_name_lower := NULL]
}

## ===================================================================
## 5. BUILD LA-YEAR PANEL (for CS-DiD)
## ===================================================================
cat("\nBuilding LA-year panel for CS-DiD...\n")

la_annual <- la_qtr[, .(
  mean_log_price = mean(mean_log_price, na.rm = TRUE),
  median_price = mean(median_price, na.rm = TRUE),
  sd_log_price = mean(sd_log_price, na.rm = TRUE),
  n_transactions = sum(n_transactions, na.rm = TRUE),
  pct_detached = mean(pct_detached, na.rm = TRUE),
  pct_flat = mean(pct_flat, na.rm = TRUE),
  pct_terraced = mean(pct_terraced, na.rm = TRUE),
  pct_new = mean(pct_new, na.rm = TRUE),
  prs_share = mean(prs_share, na.rm = TRUE)
), by = .(la_name, year, licensing_year, treated_ever, cohort)]

## Numeric ID
la_annual[, la_id := as.integer(as.factor(la_name))]

cat("LA-year panel: ", nrow(la_annual), " observations, ",
    n_distinct(la_annual$la_name), " LAs, ",
    n_distinct(la_annual$year), " years\n")

## ===================================================================
## 6. SAVE PANELS
## ===================================================================
fwrite(la_qtr, file.path(data_dir, "la_quarter_panel.csv"))
fwrite(la_annual, file.path(data_dir, "la_annual_panel.csv"))

## Save transaction-level for hedonic models (parquet for size)
arrow::write_parquet(lr_treat, file.path(data_dir, "lr_transactions_treated.parquet"))

## ===================================================================
## 7. BUILD ASB PANEL (if data available)
## ===================================================================
asb_file <- file.path(data_dir, "police_asb_lsoa_month.csv")
if (file.exists(asb_file)) {
  cat("\nBuilding ASB panel...\n")
  asb <- fread(asb_file)
  asb[, year := as.integer(substr(Month, 1, 4))]

  ## Aggregate to LA-year (LSOA codes map to LAs but we'd need lookup)
  ## For now, use the monthly data as-is and aggregate later
  cat("  ASB data: ", nrow(asb), " LSOA-month observations\n")
} else {
  cat("\nNo ASB data available. Will skip mechanism test.\n")
}

cat("\n=== PANEL CONSTRUCTION COMPLETE ===\n")
cat("LA-quarter panel: ", nrow(la_qtr), " obs\n")
cat("LA-annual panel: ", nrow(la_annual), " obs\n")
cat("Transaction-level: ", nrow(lr_treat), " obs\n")
cat("Ready for 03_main_analysis.R\n")
