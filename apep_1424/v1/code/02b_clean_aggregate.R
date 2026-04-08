## 02b_clean_aggregate.R — Build analysis panel from OpenImmigration aggregates
## Fallback when full EOIR proceedings are not available
## apep_1416: The Legal Status Premium in Local Housing Markets

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## 1. Build court-level judge leniency instrument
## ============================================================
cat("=== Building judge leniency from aggregates ===\n")

judge_courts <- fread(file.path(data_dir, "eoir_judge_courts.csv"))
courts <- fread(file.path(data_dir, "eoir_courts.csv"))

## Filter to judges with >=100 decisions
jc <- judge_courts[judge_total >= 100]
cat(sprintf("  Active judge-court links: %d\n", nrow(jc)))

## Court-level average judge leniency (unweighted mean of judge grant rates)
court_leniency <- jc[, .(
  leniency_iv = mean(judge_grant_rate, na.rm = TRUE),
  leniency_sd = sd(judge_grant_rate, na.rm = TRUE),
  n_judges = .N,
  total_hearings = sum(hearings, na.rm = TRUE),
  leniency_p25 = quantile(judge_grant_rate, 0.25, na.rm = TRUE),
  leniency_p75 = quantile(judge_grant_rate, 0.75, na.rm = TRUE)
), by = code]

## Merge court metadata
court_leniency <- merge(court_leniency,
  courts[, .(code, state, city, grantRate, cases)],
  by = "code", all.x = TRUE
)

cat(sprintf("  Courts with leniency: %d\n", nrow(court_leniency)))
cat(sprintf("  Leniency: mean=%.1f, SD=%.1f, [%.1f, %.1f]\n",
  mean(court_leniency$leniency_iv), sd(court_leniency$leniency_iv),
  min(court_leniency$leniency_iv), max(court_leniency$leniency_iv)))
cat(sprintf("  Court grant rate: mean=%.1f, SD=%.1f\n",
  mean(court_leniency$grantRate, na.rm=TRUE), sd(court_leniency$grantRate, na.rm=TRUE)))
cat(sprintf("  First-stage corr(leniency, grantRate): %.3f\n",
  cor(court_leniency$leniency_iv, court_leniency$grantRate, use = "complete.obs")))

## ============================================================
## 2. Court-to-county crosswalk
## ============================================================
cat("\n=== Court-county crosswalk ===\n")

crosswalk <- data.table(
  code = c(
    "NYC", "LOS", "SFR", "MIA", "CHI", "HOU", "ARL", "SAN", "BOS",
    "ATL", "NEW", "BAL", "PHI", "DEN", "SEA", "CLE", "DET", "DAL",
    "ORL", "HAR", "PHO", "LAS", "MEM", "SNA", "BUF", "POR",
    "TAC", "HLG", "ELP", "OMA", "KCA", "STL", "SLC",
    "HON", "MIN", "PIB", "BLM",
    ## Additional courts
    "PSD", "WLA", "CIC", "SND", "ELO", "JNA", "PIS", "WAS",
    "NYV", "IMP", "ELZ", "OAK", "LRO", "NLA", "ADL", "NYB",
    "SNC", "NOL", "HGP", "CHL", "FLO", "KRO", "HSG", "OTM",
    "SMO", "HYA", "AUR", "VNS", "LVG", "ATD"
  ),
  county_fips = c(
    "36061", "06037", "06075", "12086", "17031", "48201", "51013", "06073", "25025",
    "13121", "36047", "24510", "42101", "08031", "53033", "39035", "26163", "48113",
    "12095", "09003", "04013", "32003", "47157", "06059", "36029", "41051",
    "53053", "48215", "48141", "31055", "29095", "29510", "49035",
    "15003", "27053", "42003", "55025",
    ## Additional courts → counties
    "48163", "06037", "48339", "06073", "04021", "22069", "48061", "51059",
    "36061", "06025", "34039", "22005", "48479", "06037", "36071", "36061",
    "06059", "22071", "48201", "37119", "04021", "12086", "48201", "06073",
    "06067", "24033", "08005", "06037", "32003", "13121"
  )
)

court_county <- merge(court_leniency, crosswalk, by = "code")
cat(sprintf("  Courts matched: %d of %d\n", nrow(court_county), nrow(court_leniency)))

## ============================================================
## 3. Merge with ACS housing panel
## ============================================================
cat("\n=== Building panel ===\n")

acs <- fread(file.path(data_dir, "acs_housing.csv"))
acs[, fips := as.character(fips)]

## Rename ACS variables
setnames(acs,
  c("B25064_001E", "B25077_001E", "B25003_001E", "B25003_002E",
    "B05001_001E", "B05001_006E", "B01003_001E", "B19013_001E"),
  c("median_rent", "median_home_value", "tenure_total", "owner_occupied",
    "citizen_total", "noncitizen", "total_pop", "median_hh_income"))
acs[, homeownership_rate := owner_occupied / tenure_total]
acs[, noncitizen_share := noncitizen / citizen_total]
acs[, log_rent := log(median_rent)]
acs[, log_home_value := log(median_home_value)]

## Panel: court × year
## Leniency is time-invariant; ACS outcomes vary by year
panel <- merge(
  court_county[, .(code, county_fips, leniency_iv, leniency_sd,
                   n_judges, grantRate, city, state, total_hearings)],
  acs,
  by.x = "county_fips", by.y = "fips",
  allow.cartesian = TRUE
)

## Drop missing
panel <- panel[!is.na(median_rent) & !is.na(leniency_iv) & !is.na(grantRate)]

## Additional variables
panel[, log_pop := log(total_pop)]
panel[, rent_to_income := median_rent / (median_hh_income / 12)]
panel[, grant_rate := grantRate / 100]  # Convert from percentage to proportion

cat(sprintf("  Panel: %d obs, %d courts, %d years\n",
  nrow(panel), uniqueN(panel$code), uniqueN(panel$year)))

## ============================================================
## 4. Summary statistics
## ============================================================
cat("\n=== Summary Statistics ===\n")

cat(sprintf("  %-25s %10s %10s %10s %10s\n", "Variable", "Mean", "SD", "Min", "Max"))
cat(sprintf("  %s\n", paste(rep("-", 65), collapse = "")))
for (v in c("grant_rate", "leniency_iv", "median_rent", "median_home_value",
            "homeownership_rate", "noncitizen_share", "total_pop", "n_judges")) {
  x <- panel[[v]]
  cat(sprintf("  %-25s %10.3f %10.3f %10.3f %10.3f\n",
    v, mean(x, na.rm=TRUE), sd(x, na.rm=TRUE), min(x, na.rm=TRUE), max(x, na.rm=TRUE)))
}

## ============================================================
## 5. Save
## ============================================================
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))

## Diagnostics for validate_v1.py
diag <- list(
  n_treated = uniqueN(panel$code),
  n_pre = uniqueN(panel$year[panel$year <= 2015]),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat(sprintf("\n  Panel saved: %d obs\n", nrow(panel)))
cat("  diagnostics.json saved\n")
cat("\n=== Aggregate clean complete ===\n")
