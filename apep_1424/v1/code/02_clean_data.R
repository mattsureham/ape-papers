## 02_clean_data.R — Construct judge leniency IV and analysis dataset
## apep_1416: The Legal Status Premium in Local Housing Markets

source("00_packages.R")

if (!requireNamespace("arrow", quietly = TRUE)) {
  install.packages("arrow", repos = "https://cran.r-project.org")
}
library(arrow)

data_dir <- "../data"

## ============================================================
## 1. Load EOIR case data
## ============================================================
cat("=== Loading EOIR case data ===\n")

parquet_file <- file.path(data_dir, "eoir_cases.parquet")
stopifnot("EOIR parquet not found" = file.exists(parquet_file))

eoir <- as.data.table(arrow::read_parquet(parquet_file))
cat(sprintf("  Loaded %s cases\n", format(nrow(eoir), big.mark = ",")))

## ============================================================
## 2. Parse dates
## ============================================================
cat("\n=== Parsing dates ===\n")

eoir[, comp_year := as.integer(format(as.Date(final_completion_date), "%Y"))]
eoir[is.na(comp_year), comp_year := as.integer(format(as.Date(ij_final_date), "%Y"))]

cat(sprintf("  Cases with valid year: %s (%.1f%%)\n",
            format(sum(!is.na(eoir$comp_year)), big.mark = ","),
            100 * mean(!is.na(eoir$comp_year))))

## ============================================================
## 3. Construct county FIPS from the data
## ============================================================
cat("\n=== Constructing county FIPS ===\n")

## county_fips_code is already a 5-digit FIPS (e.g., "17031" = Cook County, IL)
eoir[, county_fips := county_fips_code]
eoir[county_fips_code == "" | is.na(county_fips_code), county_fips := NA_character_]
## Convert to integer to match ACS format
eoir[, county_fips_int := as.integer(county_fips)]

cat(sprintf("  Cases with county FIPS: %s (%.1f%%)\n",
            format(sum(!is.na(eoir$county_fips)), big.mark = ","),
            100 * mean(!is.na(eoir$county_fips))))

## ============================================================
## 4. Filter and classify outcomes
## ============================================================
cat("\n=== Filtering cases ===\n")

eoir_clean <- eoir[
  !is.na(judge_name) & judge_name != "" &
  !is.na(final_court) & final_court != "" &
  !is.na(comp_year) & comp_year >= 2001 & comp_year <= 2023 &
  !is.na(case_outcome) & case_outcome != "" &
  !grepl("Visiting|IAD Judge|Clerical", judge_name, ignore.case = TRUE)
]
cat(sprintf("  After basic filters: %s cases\n", format(nrow(eoir_clean), big.mark = ",")))

## Classify outcomes
eoir_clean[, granted := as.integer(case_outcome %in% c(
  "Relief Granted",
  "Remove-INA Withholding Granted",
  "Remove-CAT Withholding Granted"
))]
eoir_clean[, removed := as.integer(case_outcome %in% c(
  "Remove",
  "Voluntary Departure"
))]

## Keep only clear outcomes
eoir_final <- eoir_clean[granted == 1 | removed == 1]
cat(sprintf("  Cases with clear outcome: %s\n", format(nrow(eoir_final), big.mark = ",")))
cat(sprintf("    Grant rate: %.1f%%\n", 100 * mean(eoir_final$granted)))
cat(sprintf("    Unique judges: %d\n", uniqueN(eoir_final$judge_name)))
cat(sprintf("    Unique courts: %d\n", uniqueN(eoir_final$final_court)))

stopifnot("Grant rate implausibly low" = mean(eoir_final$granted) > 0.05)
stopifnot("Grant rate implausibly high" = mean(eoir_final$granted) < 0.80)

## ============================================================
## 5. Leave-one-out judge leniency
## ============================================================
cat("\n=== Computing judge leniency IV ===\n")

## Judge × court × year
jcy <- eoir_final[, .(
  n_cases = .N,
  n_grants = sum(granted)
), by = .(judge_name, final_court, comp_year)]

## Judge career totals
j_totals <- eoir_final[, .(career_cases = .N, career_grants = sum(granted)), by = judge_name]

jcy <- merge(jcy, j_totals, by = "judge_name")
jcy[, leniency_loo := fifelse(
  career_cases - n_cases >= 50,
  (career_grants - n_grants) / (career_cases - n_cases),
  NA_real_
)]

cat(sprintf("  Judge-court-year cells: %d\n", nrow(jcy)))
cat(sprintf("  With valid LOO: %d (%.1f%%)\n",
            sum(!is.na(jcy$leniency_loo)), 100 * mean(!is.na(jcy$leniency_loo))))
cat(sprintf("  Leniency: mean=%.3f, SD=%.3f, range=[%.3f, %.3f]\n",
            mean(jcy$leniency_loo, na.rm = TRUE), sd(jcy$leniency_loo, na.rm = TRUE),
            min(jcy$leniency_loo, na.rm = TRUE), max(jcy$leniency_loo, na.rm = TRUE)))

## ============================================================
## 6. Aggregate to court × year
## ============================================================
cat("\n=== Aggregating to court × year ===\n")

court_year <- eoir_final[, .(
  n_cases = .N,
  n_grants = sum(granted),
  grant_rate = mean(granted),
  n_judges = uniqueN(judge_name)
), by = .(final_court, comp_year)]

court_leniency <- jcy[!is.na(leniency_loo), .(
  leniency_iv = weighted.mean(leniency_loo, n_cases),
  n_judges_iv = .N
), by = .(final_court, comp_year)]

court_year <- merge(court_year, court_leniency, by = c("final_court", "comp_year"), all.x = TRUE)

cat(sprintf("  Court-year obs: %d\n", nrow(court_year)))
cat(sprintf("  With leniency IV: %d\n", sum(!is.na(court_year$leniency_iv))))
cat(sprintf("  Corr(grant_rate, leniency_iv): %.3f\n",
            cor(court_year$grant_rate, court_year$leniency_iv, use = "complete.obs")))

## ============================================================
## 7. Map courts to counties using respondent addresses
## ============================================================
cat("\n=== Mapping courts to counties ===\n")

## Use modal county FIPS of cases at each court-year as the court's county
## This is more accurate than city-based crosswalk: uses actual respondent locations
court_county <- eoir_final[!is.na(county_fips) & county_fips != "NANA", .(
  modal_county = names(sort(table(county_fips), decreasing = TRUE))[1],
  n_with_fips = .N
), by = .(final_court, comp_year)]

court_year <- merge(court_year, court_county, by = c("final_court", "comp_year"), all.x = TRUE)

## For court-years without respondent FIPS, use a manual crosswalk
crosswalk <- fread(file.path(data_dir, "court_county_crosswalk.csv"))
## Try matching unmatched courts
court_year[is.na(modal_county), court_lower := tolower(final_court)]
crosswalk[, name_lower := tolower(court_name)]

for (i in seq_len(nrow(crosswalk))) {
  court_year[is.na(modal_county) &
             grepl(crosswalk$name_lower[i], court_lower, fixed = TRUE),
             modal_county := crosswalk$county_fips[i]]
}

cat(sprintf("  Court-years with county: %d of %d (%.1f%%)\n",
            sum(!is.na(court_year$modal_county)), nrow(court_year),
            100 * mean(!is.na(court_year$modal_county))))

## ============================================================
## 8. Merge with ACS
## ============================================================
cat("\n=== Merging with ACS ===\n")

acs <- fread(file.path(data_dir, "acs_housing.csv"))
acs[, fips := sprintf("%05d", as.integer(fips))]

## Debug merge
cat(sprintf("  court_year with modal_county: %d\n", sum(!is.na(court_year$modal_county))))
cat(sprintf("  modal_county examples: %s\n", paste(head(court_year$modal_county[!is.na(court_year$modal_county)], 5), collapse=", ")))
cat(sprintf("  comp_year range: %d - %d\n", min(court_year$comp_year), max(court_year$comp_year)))
cat(sprintf("  ACS fips examples: %s\n", paste(head(acs$fips, 5), collapse=", ")))
cat(sprintf("  ACS year range: %d - %d\n", min(acs$year), max(acs$year)))
cat(sprintf("  modal_county class: %s, fips class: %s\n", class(court_year$modal_county[1]), class(acs$fips[1])))
cat(sprintf("  comp_year class: %s, year class: %s\n", class(court_year$comp_year[1]), class(acs$year[1])))
cat(sprintf("  Any overlap fips? %d\n", sum(court_year$modal_county %in% acs$fips, na.rm=TRUE)))
cat(sprintf("  Any overlap year? %d\n", sum(court_year$comp_year %in% acs$year, na.rm=TRUE)))

analysis <- merge(court_year[!is.na(modal_county)], acs,
                  by.x = c("modal_county", "comp_year"),
                  by.y = c("fips", "year"),
                  all.x = TRUE)
cat(sprintf("  After merge: %d rows, log_rent NAs: %d\n", nrow(analysis), sum(is.na(analysis$log_rent))))

## Rename for consistency with downstream scripts
setnames(analysis, "modal_county", "county_fips")
analysis[, base_city_code := final_court]
analysis[, code := final_court]  # 03_main_analysis.R uses 'code'
analysis[, year := comp_year]    # standardize

## Filter to complete obs
analysis <- analysis[
  !is.na(leniency_iv) & !is.na(log_rent) & !is.na(grant_rate) &
  n_cases >= 50
]

cat(sprintf("\n  Final analysis dataset: %d obs\n", nrow(analysis)))
cat(sprintf("  Courts: %d\n", uniqueN(analysis$final_court)))
cat(sprintf("  Counties: %d\n", uniqueN(analysis$county_fips)))
cat(sprintf("  Years: %d - %d\n", min(analysis$comp_year), max(analysis$comp_year)))

cat("\n  Variable means (SD):\n")
for (v in c("grant_rate", "leniency_iv", "median_rent", "median_home_value",
            "homeownership_rate", "noncitizen_share", "n_cases")) {
  if (v %in% names(analysis)) {
    cat(sprintf("    %s: %.3f (%.3f)\n", v,
                mean(analysis[[v]], na.rm = TRUE),
                sd(analysis[[v]], na.rm = TRUE)))
  }
}

## ============================================================
## 9. Save
## ============================================================
fwrite(analysis, file.path(data_dir, "analysis.csv"))
saveRDS(analysis, file.path(data_dir, "analysis.rds"))

cat("\n=== Clean data complete ===\n")
