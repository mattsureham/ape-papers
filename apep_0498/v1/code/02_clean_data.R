## =============================================================================
## 02_clean_data.R — Construct analysis panel
## APEP-0498: The Austerity Mortality Gradient
## =============================================================================

source("00_packages.R")

## ---------------------------------------------------------------------------
## 1. Load and clean mortality data
## ---------------------------------------------------------------------------
cat("Loading Fingertips data...\n")
mort <- fread(file.path(DATA_DIR, "fingertips_mortality_raw.csv"))
deflator <- fread(file.path(DATA_DIR, "gdp_deflator.csv"))
grants <- fread(file.path(DATA_DIR, "grant_panel.csv"))

## Parse time period to numeric year
mort[, year := as.integer(sub("^(\\d{4}).*", "\\1", `Time period`))]

## For 3-year rolling indicators (drug deaths): use the START year
mort[`Time period range` == "3y" & grepl(" - ", `Time period`), year := {
  start_yr <- as.integer(sub("^(\\d{4}) .*", "\\1", `Time period`))
  end_suffix <- as.integer(sub(".*- (\\d+)$", "\\1", `Time period`))
  end_yr <- ifelse(end_suffix < 100,
                   as.integer(paste0(substr(as.character(start_yr), 1, 2),
                                     sprintf("%02d", end_suffix))),
                   end_suffix)
  as.integer(round((start_yr + end_yr) / 2))
}]

## Keep relevant columns
mort_clean <- mort[!is.na(year) & !is.na(Value), .(
  la_code = `Area Code`,
  la_name = `Area Name`,
  indicator_id = `Indicator ID`,
  year,
  value = as.numeric(Value),
  count = as.numeric(Count),
  denominator = as.numeric(Denominator)
)]

## Deduplicate
mort_clean <- unique(mort_clean, by = c("la_code", "indicator_id", "year"))

cat(sprintf("Mortality data: %d obs, %d LAs, years %d-%d\n",
            nrow(mort_clean), uniqueN(mort_clean$la_code),
            min(mort_clean$year), max(mort_clean$year)))

## ---------------------------------------------------------------------------
## 2. Reshape to wide (one row per LA-year)
## ---------------------------------------------------------------------------
mort_wide <- dcast(mort_clean, la_code + la_name + year ~ indicator_id,
                   value.var = "value", fun.aggregate = function(x) mean(x, na.rm = TRUE))

id_map <- c(
  "92432" = "drug_death_rate",
  "91380" = "alcohol_mortality",
  "108"   = "under75_mortality",
  "90244" = "drug_treatment_opiate",
  "90245" = "drug_treatment_nonopiate",
  "40601" = "liver_disease_mortality",
  "92488" = "cancer_mortality"
)

for (old in names(id_map)) {
  if (old %in% names(mort_wide)) {
    setnames(mort_wide, old, id_map[[old]])
  }
}

## Clean NaN
for (col in names(mort_wide)) {
  if (is.numeric(mort_wide[[col]])) {
    mort_wide[is.nan(get(col)), (col) := NA_real_]
  }
}

## ---------------------------------------------------------------------------
## 3. Process grant data
## ---------------------------------------------------------------------------
cat("Processing grant data...\n")

## The grant panel has per-head nominal allocations
## We need to deflate to real terms
grants <- merge(grants, deflator, by = "year", all.x = TRUE)
grants[, grant_per_head_real := ph_grant_per_head * (100 / deflator)]

## Get baseline: use earliest available year per LA (typically 2016)
baseline_grants <- grants[, .(
  baseline_grant = grant_per_head_real[which.min(year)],
  baseline_year = min(year)
), by = la_code]

cat(sprintf("Grant panel: %d obs, %d LAs\n", nrow(grants), uniqueN(grants$la_code)))
cat(sprintf("Baseline grant: mean=%.0f, sd=%.0f (year=%d for most)\n",
            mean(baseline_grants$baseline_grant),
            sd(baseline_grants$baseline_grant),
            median(baseline_grants$baseline_year)))

## Calculate grant change from baseline for each year
grants <- merge(grants, baseline_grants, by = "la_code", all.x = TRUE)
grants[, grant_change := grant_per_head_real - baseline_grant]
grants[, grant_change_pct := 100 * (grant_per_head_real - baseline_grant) / baseline_grant]

## ---------------------------------------------------------------------------
## 4. Merge all data
## ---------------------------------------------------------------------------
cat("Merging datasets...\n")

panel <- copy(mort_wide)

## Merge grant data (many mortality years won't have grant data — that's OK)
panel <- merge(panel, grants[, .(la_code, year, ph_grant_per_head = grant_per_head_real,
                                  grant_change, grant_change_pct)],
               by = c("la_code", "year"), all.x = TRUE)

## Merge baseline grant (time-invariant)
panel <- merge(panel, baseline_grants[, .(la_code, baseline_grant)],
               by = "la_code", all.x = TRUE)

## Merge deflator
panel <- merge(panel, deflator, by = "year", all.x = TRUE)

## Post-treatment indicator (grants started being cut from 2015/16)
panel[, post := as.integer(year >= 2016)]

## ---------------------------------------------------------------------------
## 5. Construct tercile treatment groups
## ---------------------------------------------------------------------------
## Use latest available grant data (2020 or 2021) vs baseline to classify LAs

latest_grants <- grants[year >= 2020, .(
  latest_grant = grant_per_head_real[which.max(year)],
  latest_year = max(year)
), by = la_code]

tercile_data <- merge(baseline_grants, latest_grants, by = "la_code")
tercile_data[, total_change_pct := 100 * (latest_grant - baseline_grant) / baseline_grant]

if (nrow(tercile_data) > 10) {
  breaks <- quantile(tercile_data$total_change_pct, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  if (length(unique(breaks)) < 4) {
    ## Ensure unique breaks
    breaks <- unique(breaks)
    while (length(breaks) < 4) breaks <- c(breaks, max(breaks) + 1)
  }

  tercile_data[, grant_tercile := cut(total_change_pct,
                                       breaks = quantile(total_change_pct, c(0, 1/3, 2/3, 1)),
                                       labels = c("Large cut", "Moderate change", "Protected"),
                                       include.lowest = TRUE)]

  panel <- merge(panel, tercile_data[, .(la_code, grant_tercile, total_change_pct)],
                 by = "la_code", all.x = TRUE)

  cat("\nGrant tercile distribution:\n")
  print(tercile_data[!is.na(grant_tercile), .N, by = grant_tercile])

  cat("\nBaseline characteristics by tercile:\n")
  print(tercile_data[!is.na(grant_tercile), .(
    n = .N,
    mean_baseline = round(mean(baseline_grant), 0),
    mean_change_pct = round(mean(total_change_pct), 1)
  ), by = grant_tercile][order(grant_tercile)])
}

## Standardized baseline grant for event study
panel[, baseline_grant_std := (baseline_grant - mean(baseline_grant, na.rm = TRUE)) /
        sd(baseline_grant, na.rm = TRUE)]

## ---------------------------------------------------------------------------
## 6. Restrict to LAs with both mortality and grant data
## ---------------------------------------------------------------------------
## Keep LAs that appear in the grant panel
las_with_grants <- unique(grants$la_code)
panel_full <- panel[la_code %in% las_with_grants]

cat(sprintf("\n=== Final Panel ===\n"))
cat(sprintf("Total obs: %d (full: %d)\n", nrow(panel_full), nrow(panel)))
cat(sprintf("LAs with grants: %d\n", uniqueN(panel_full$la_code)))
cat(sprintf("Year range: %d-%d\n", min(panel_full$year), max(panel_full$year)))

for (v in c("drug_death_rate", "alcohol_mortality", "under75_mortality",
            "drug_treatment_opiate", "ph_grant_per_head", "cancer_mortality")) {
  if (v %in% names(panel_full)) {
    x <- panel_full[!is.na(get(v))][[v]]
    if (length(x) > 0) {
      cat(sprintf("  %s: N=%d, mean=%.1f, sd=%.1f\n", v, length(x), mean(x), sd(x)))
    }
  }
}

## Save both versions
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
fwrite(panel_full, file.path(DATA_DIR, "analysis_panel_grants.csv"))
cat("\n✓ Panels saved\n")
