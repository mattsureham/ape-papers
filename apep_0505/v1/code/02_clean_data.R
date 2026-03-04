## ============================================================
## 02_clean_data.R — Build analysis panel
## apep_0505: Council Tax Support Localization
## ============================================================

source("00_packages.R")

## ============================================================
## 1. Parse Revenue Outturn — Extract Treatment Variable
## ============================================================
cat("=== Parsing Revenue Outturn ===\n")

ro <- fread(file.path(DATA_DIR, "revenue_outturn", "revenue_outturn_timeseries.csv"))

## Key columns for treatment construction:
## RS_lctswa_net_exp = Local CTS working-age net expenditure (£000s)
## RS_lctspen_net_exp = Local CTS pensioner net expenditure (£000s)
## RS_lctstot_net_exp = Local CTS total net expenditure
## RS_grantrsg_net_exp = Revenue Support Grant
## RS_retainnndr_net_exp = Retained NNDR (business rates)
## RS_totsx_net_exp = Total service expenditure

## Extract fiscal year
ro[, fiscal_year := as.integer(substr(as.character(year_ending), 1, 4))]
## year_ending 201803 means year ending March 2018, i.e., fiscal year 2017/18
## So fiscal_year 2018 = FY 2017/18

## Filter to individual LAs (exclude totals/aggregates)
## Individual LAs have ONS codes starting with E06, E07, E08, E09, E10
ro_la <- ro[grepl("^E0[6-9]|^E10", ONS_code)]
cat("Individual LAs:", n_distinct(ro_la$ONS_code), "\n")
cat("Years:", paste(sort(unique(ro_la$fiscal_year)), collapse = ", "), "\n")

## Extract key variables
treatment_vars <- c("ONS_code", "LA_name", "fiscal_year",
                    "RS_lctswa_net_exp", "RS_lctspen_net_exp",
                    "RS_lctstot_net_exp", "RS_grantrsg_net_exp",
                    "RS_retainnndr_net_exp", "RS_totsx_net_exp",
                    "RS_colfunct_net_exp", "RS_ctrtot_net_exp",
                    "RS_netrevexp_net_exp")

## Check which columns exist
available <- treatment_vars[treatment_vars %in% names(ro_la)]
cat("Available treatment vars:", paste(available, collapse = ", "), "\n")

ro_panel <- ro_la[, ..available]

## Convert to numeric
num_cols <- setdiff(available, c("ONS_code", "LA_name", "fiscal_year"))
for (col in num_cols) {
  ro_panel[, (col) := as.numeric(get(col))]
}

cat("RO panel:", nrow(ro_panel), "LA-year obs\n")

## ============================================================
## 2. Construct Cross-Sectional Treatment Intensity
## ============================================================
cat("\n=== Constructing Treatment Variable ===\n")

## Use FY 2017/18 (first available year) as the treatment measure
## RS_lctswa_net_exp = CTS working-age net expenditure (£000s)
## Higher value = more generous scheme = less austerity

## Get population for normalization
## NOTE: The NOMIS NM_31_1 age=12 query returns 12-year-olds, NOT working-age (16-64).
## Use total population (age=0) instead, which gives correct LA-level counts.
pop_file <- file.path(DATA_DIR, "nomis", "population_by_la.csv")
if (file.exists(pop_file)) {
  total_pop <- fread(pop_file)
  wa_pop_clean <- total_pop[grepl("^E0", GEOGRAPHY_CODE), .(
    la_code = GEOGRAPHY_CODE,
    year = as.integer(gsub(".*?(\\d{4}).*", "\\1", DATE_NAME)),
    wa_pop = as.numeric(OBS_VALUE)
  )]
  cat("Total population (used as denominator):", nrow(wa_pop_clean), "LA-year obs\n")
  cat("  Sample: Hartlepool 2012 =", wa_pop_clean[la_code == "E06000001" & year == 2012, wa_pop], "\n")
}

## Get CTS expenditure from 2017/18
cts_2018 <- ro_panel[fiscal_year == 2018, .(
  la_code = ONS_code,
  la_name = LA_name,
  cts_wa_exp = RS_lctswa_net_exp,      # Working-age CTS (£000s)
  cts_pen_exp = RS_lctspen_net_exp,     # Pensioner CTS (£000s)
  cts_tot_exp = RS_lctstot_net_exp,     # Total CTS
  rsg = RS_grantrsg_net_exp,            # Revenue Support Grant
  total_exp = RS_totsx_net_exp          # Total service expenditure
)]

## Merge with working-age population (use 2017 as closest year)
if (exists("wa_pop_clean")) {
  wa_2017 <- wa_pop_clean[year == 2017, .(la_code, wa_pop_2017 = wa_pop)]
  cts_2018 <- merge(cts_2018, wa_2017, by = "la_code", all.x = TRUE)
}

## Compute per-capita CTS measures
if ("wa_pop_2017" %in% names(cts_2018)) {
  cts_2018[, cts_wa_per_cap := cts_wa_exp * 1000 / wa_pop_2017]  # £ per working-age person
  cts_2018[, cts_pen_per_cap := cts_pen_exp * 1000 / wa_pop_2017]
}

## Summary stats for treatment variable
cat("\nTreatment variable (CTS WA expenditure per capita, 2017/18):\n")
if ("cts_wa_per_cap" %in% names(cts_2018)) {
  cat("  N:", sum(!is.na(cts_2018$cts_wa_per_cap)), "\n")
  cat("  Mean:", round(mean(cts_2018$cts_wa_per_cap, na.rm = TRUE), 2), "\n")
  cat("  SD:", round(sd(cts_2018$cts_wa_per_cap, na.rm = TRUE), 2), "\n")
  cat("  Min:", round(min(cts_2018$cts_wa_per_cap, na.rm = TRUE), 2), "\n")
  cat("  Max:", round(max(cts_2018$cts_wa_per_cap, na.rm = TRUE), 2), "\n")
  cat("  Median:", round(median(cts_2018$cts_wa_per_cap, na.rm = TRUE), 2), "\n")

  ## Standardize treatment variable (z-score)
  cts_2018[, cts_wa_z := scale(cts_wa_per_cap)[, 1]]
  ## Also create a "cut intensity" measure (inverse of generosity)
  cts_2018[, cut_intensity := -cts_wa_z]
}

cat("\nTreatment assigned to", sum(!is.na(cts_2018$cts_wa_per_cap)), "LAs\n")

## ============================================================
## 3. Clean NOMIS JSA Data — Build Long Panel
## ============================================================
cat("\n=== Building NOMIS Panel ===\n")

jsa_file <- file.path(DATA_DIR, "nomis", "jsa_claimants_by_la.csv")
jsa <- fread(jsa_file)

jsa_clean <- jsa[grepl("^E0", GEOGRAPHY_CODE), .(
  la_code = GEOGRAPHY_CODE,
  la_name = GEOGRAPHY_NAME,
  date_name = DATE_NAME,
  jsa_count = as.numeric(OBS_VALUE)
)]

## Extract year from date
jsa_clean[, year := as.integer(gsub(".*?(\\d{4}).*", "\\1", date_name))]

## Collapse to annual (average Jan and Jul)
jsa_annual <- jsa_clean[, .(
  jsa_count = mean(jsa_count, na.rm = TRUE)
), by = .(la_code, la_name, year)]

## Merge with population for rates
if (exists("wa_pop_clean")) {
  jsa_annual <- merge(jsa_annual, wa_pop_clean[, .(la_code, year, wa_pop)],
                      by = c("la_code", "year"), all.x = TRUE)
  jsa_annual[, jsa_rate := jsa_count / wa_pop * 100]
  cat("JSA rate stats: mean =", round(mean(jsa_annual$jsa_rate, na.rm=TRUE), 2),
      ", max =", round(max(jsa_annual$jsa_rate, na.rm=TRUE), 2), "\n")
  ## Sanity check: JSA rate should be 0-15% for UK LAs
  stopifnot("JSA rate implausibly high" = max(jsa_annual$jsa_rate, na.rm=TRUE) < 20)
}

cat("JSA annual panel:", nrow(jsa_annual), "obs,",
    n_distinct(jsa_annual$la_code), "LAs,",
    paste(range(jsa_annual$year, na.rm = TRUE), collapse = "-"), "\n")

## ============================================================
## 4. Process Land Registry — Aggregate to LA Level
## ============================================================
cat("\n=== Processing Land Registry ===\n")

lr_dir <- file.path(DATA_DIR, "land_registry")
lr_files <- list.files(lr_dir, pattern = "^pp-\\d{4}\\.csv$", full.names = TRUE)

lr_col_names <- c("guid", "price", "date", "postcode", "prop_type",
                   "old_new", "duration", "paon", "saon", "street",
                   "locality", "town", "district", "county",
                   "ppd_category", "record_status")

lr_annual <- rbindlist(lapply(lr_files, function(f) {
  yr <- as.integer(str_extract(basename(f), "\\d{4}"))
  cat("LR", yr, "... ")
  tryCatch({
    dt <- fread(f, header = FALSE, select = c(2, 3, 5, 7, 13),
                showProgress = FALSE)
    setnames(dt, c("price", "date", "prop_type", "duration", "district"))
    dt[, price := as.numeric(price)]
    dt[, year := year(as.Date(date))]
    dt <- dt[price >= 10000 & price <= 10000000]
    agg <- dt[, .(
      median_price = median(price, na.rm = TRUE),
      mean_log_price = mean(log(price), na.rm = TRUE),
      n_transactions = .N,
      pct_detached = mean(prop_type == "D", na.rm = TRUE),
      pct_flat = mean(prop_type == "F", na.rm = TRUE),
      p25_price = quantile(price, 0.25),
      p75_price = quantile(price, 0.75)
    ), by = .(district, year)]
    cat(nrow(agg), "districts\n")
    agg
  }, error = function(e) { cat("ERROR:", e$message, "\n"); NULL })
}), fill = TRUE)

cat("LR panel:", nrow(lr_annual), "district-year obs,",
    n_distinct(lr_annual$district), "districts\n")

## ============================================================
## 5. Match Land Registry Districts to LA Codes
## ============================================================
cat("\n=== Matching LR Districts to LA Codes ===\n")

## Build crosswalk from name matching
## JSA/NOMIS uses LA names; LR uses "district" which is typically the LA name
stopifnot("LR panel not empty" = nrow(lr_annual) > 0)
lr_districts <- unique(lr_annual$district)
nomis_las <- unique(jsa_annual[, .(la_code, la_name)])

## Clean names for matching
lr_lookup <- data.table(
  district = lr_districts,
  dist_clean = toupper(trimws(lr_districts))
)
la_names <- nomis_las[, .(
  la_code, la_name,
  name_clean = toupper(trimws(la_name))
)]

## Exact match first
matched <- merge(lr_lookup, la_names, by.x = "dist_clean", by.y = "name_clean",
                 all.x = TRUE)

## For unmatched, try partial matching
unmatched <- matched[is.na(la_code)]
if (nrow(unmatched) > 0) {
  cat("Unmatched districts:", nrow(unmatched), "\n")
  ## Try removing common suffixes/prefixes
  for (i in seq_len(nrow(unmatched))) {
    d <- unmatched$dist_clean[i]
    ## Try fuzzy matching with agrep
    m <- agrep(d, la_names$name_clean, max.distance = 0.15, value = FALSE)
    if (length(m) == 1) {
      matched[dist_clean == d, `:=`(
        la_code = la_names$la_code[m],
        la_name = la_names$la_name[m]
      )]
    }
  }
}

match_rate <- mean(!is.na(matched$la_code))
cat("Final match rate:", round(match_rate * 100, 1), "%\n")
cat("Matched:", sum(!is.na(matched$la_code)), "of", nrow(matched), "districts\n")

## Add LA codes to LR panel
lr_annual <- merge(lr_annual, matched[, .(district, la_code)],
                   by = "district", all.x = TRUE)

## Aggregate to LA level (some LAs have multiple districts)
lr_by_la <- lr_annual[!is.na(la_code), .(
  median_price = median(median_price, na.rm = TRUE),
  mean_log_price = mean(mean_log_price, na.rm = TRUE),
  n_transactions = sum(n_transactions, na.rm = TRUE),
  p25_price = median(p25_price, na.rm = TRUE)
), by = .(la_code, year)]

cat("LR by LA:", nrow(lr_by_la), "obs,",
    n_distinct(lr_by_la$la_code), "LAs\n")

## ============================================================
## 6. Merge All Panels
## ============================================================
cat("\n=== Merging Panels ===\n")

## Start with JSA as backbone
panel <- copy(jsa_annual)

## Add property prices
panel <- merge(panel, lr_by_la, by = c("la_code", "year"), all.x = TRUE)

## Add treatment variable (cross-sectional, from 2017/18 RO)
treatment_cols <- c("la_code", "cts_wa_per_cap", "cts_pen_per_cap",
                    "cts_wa_z", "cut_intensity", "cts_wa_exp", "cts_pen_exp",
                    "rsg", "total_exp")
available_treat <- treatment_cols[treatment_cols %in% names(cts_2018)]
panel <- merge(panel, cts_2018[, ..available_treat],
               by = "la_code", all.x = TRUE)

## Create time variables
panel[, post := as.integer(year >= 2013)]
panel[, event_time := year - 2013]

## Filter to 2008-2019 (avoid COVID)
panel <- panel[year >= 2008 & year <= 2019]

## Drop LAs with missing treatment
panel <- panel[!is.na(cts_wa_per_cap)]

## Create treatment intensity bins (quartiles)
panel[, treat_quartile := cut(cts_wa_per_cap,
                               breaks = quantile(cts_wa_per_cap, c(0, 0.25, 0.5, 0.75, 1),
                                                 na.rm = TRUE),
                               labels = c("Q1_least_generous", "Q2", "Q3", "Q4_most_generous"),
                               include.lowest = TRUE)]

## ============================================================
## 7. Summary Statistics
## ============================================================
cat("\n=== Panel Summary ===\n")
cat("Final panel:", nrow(panel), "obs\n")
cat("LAs:", n_distinct(panel$la_code), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Years per LA:", round(nrow(panel) / n_distinct(panel$la_code), 1), "\n")

## Summary stats by pre/post
cat("\nPre-reform (2008-2012):\n")
pre <- panel[post == 0]
cat("  JSA rate: mean =", round(mean(pre$jsa_rate, na.rm = TRUE), 2),
    ", sd =", round(sd(pre$jsa_rate, na.rm = TRUE), 2), "\n")
cat("  Median price: mean =", round(mean(pre$median_price, na.rm = TRUE), 0), "\n")

cat("\nPost-reform (2013-2019):\n")
post_data <- panel[post == 1]
cat("  JSA rate: mean =", round(mean(post_data$jsa_rate, na.rm = TRUE), 2),
    ", sd =", round(sd(post_data$jsa_rate, na.rm = TRUE), 2), "\n")
cat("  Median price: mean =", round(mean(post_data$median_price, na.rm = TRUE), 0), "\n")

## Treatment stats by quartile
cat("\nTreatment quartiles (CTS per cap, 2017/18):\n")
panel[year == 2017, .(
  n_las = .N,
  mean_cts = round(mean(cts_wa_per_cap, na.rm = TRUE), 2),
  mean_jsa = round(mean(jsa_rate, na.rm = TRUE), 2),
  mean_price = round(mean(median_price, na.rm = TRUE), 0)
), by = treat_quartile][order(treat_quartile)] %>% print()

## ============================================================
## 8. Build Revenue Outturn Panel (Short Panel 2017-2024)
## ============================================================
cat("\n=== Building RO Short Panel ===\n")

## For the RO-based analysis (cross-sectional + short panel)
ro_short <- ro_panel[!is.na(RS_lctswa_net_exp)]

## Merge with population for per-capita measures
if (exists("wa_pop_clean")) {
  ro_short <- merge(ro_short,
                    wa_pop_clean[, .(la_code, year = year, wa_pop)],
                    by.x = c("ONS_code", "fiscal_year"),
                    by.y = c("la_code", "year"),
                    all.x = TRUE)
  ## Try with year-1 for fiscal year alignment
  ro_short2 <- merge(ro_short[is.na(wa_pop)],
                     wa_pop_clean[, .(la_code, year = year + 1, wa_pop)],
                     by.x = c("ONS_code", "fiscal_year"),
                     by.y = c("la_code", "year"),
                     all.x = TRUE, suffixes = c("", ".2"))
  if ("wa_pop.2" %in% names(ro_short2)) {
    ro_short[is.na(wa_pop), wa_pop := ro_short2$wa_pop.2]
  }

  ro_short[, cts_wa_per_cap := RS_lctswa_net_exp * 1000 / wa_pop]
  ro_short[, cts_pen_per_cap := RS_lctspen_net_exp * 1000 / wa_pop]
}

cat("RO short panel:", nrow(ro_short), "obs,",
    n_distinct(ro_short$ONS_code), "LAs\n")

## ============================================================
## 9. Save Everything
## ============================================================
cat("\n=== Saving ===\n")

saveRDS(panel, file.path(DATA_DIR, "analysis_panel.rds"))
saveRDS(cts_2018, file.path(DATA_DIR, "treatment_2018.rds"))
saveRDS(ro_short, file.path(DATA_DIR, "ro_short_panel.rds"))
if (exists("lr_annual")) saveRDS(lr_annual, file.path(DATA_DIR, "lr_panel.rds"))
if (exists("jsa_annual")) saveRDS(jsa_annual, file.path(DATA_DIR, "jsa_panel.rds"))

cat("All data saved.\n")
