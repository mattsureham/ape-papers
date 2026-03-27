## 02_clean_data.R — Construct analysis panel
## apep_1046: Cross-hazard injury substitution from OSHA silica standard

source("00_packages.R")

dt <- fread("../data/ita_raw_combined.csv", showProgress = FALSE)
cat("Raw rows:", nrow(dt), "\n")

## ── Standardize key columns ──────────────────────────────────────────
setnames(dt, tolower(names(dt)))

## Use year_filing_for as the analysis year
dt[, year := as.integer(year_filing_for)]
dt <- dt[year >= 2016 & year <= 2024]

## NAICS: extract 2-digit sector and 3-digit subsector
dt[, naics6 := as.character(naics_code)]
dt[, naics2 := as.integer(substr(naics6, 1, 2))]
dt[, naics3 := as.integer(substr(naics6, 1, 3))]
dt[, naics4 := as.integer(substr(naics6, 1, 4))]

## ── Define treatment groups ──────────────────────────────────────────
## Manufacturing = NAICS 31-33 (affected by 2018 silica standard for general industry)
## Services control = NAICS 54, 56, 62, 72 (minimal silica exposure)
## Construction = NAICS 23 (affected by 2016 silica standard — used as placebo/early-treatment)

dt[, sector_group := fcase(
  naics2 %in% 31:33, "manufacturing",
  naics2 == 23,       "construction",
  naics2 %in% c(54, 56, 62, 72), "services",
  default = "other"
)]

## High-silica manufacturing subsectors
## NAICS 327 (stone/glass/cement), 331 (primary metals), 332 (fabricated metals),
## 324 (petroleum/coal), 321 (wood)
dt[, high_silica := as.integer(naics3 %in% c(327, 331, 332, 324, 321))]

## Treatment indicator: manufacturing
dt[, mfg := as.integer(sector_group == "manufacturing")]

## Post-silica standard (general industry effective June 2018, full year = 2019)
dt[, post := as.integer(year >= 2019)]

## ── Clean outcome variables ──────────────────────────────────────────
injury_cols <- c("total_injuries", "total_skin_disorders",
                 "total_respiratory_conditions", "total_poisonings",
                 "total_hearing_loss", "total_other_illnesses")

## Replace NA with 0 for injury counts
for (col in injury_cols) {
  dt[is.na(get(col)), (col) := 0L]
}

## Clean employee count and hours
dt[, emp := as.numeric(annual_average_employees)]
dt[, hours := as.numeric(total_hours_worked)]

## Drop establishments with missing/zero employees or hours
dt <- dt[!is.na(emp) & emp > 0 & !is.na(hours) & hours > 0]
cat("After dropping missing emp/hours:", nrow(dt), "\n")

## Compute rates per 100 FTE (200,000 hours = 100 FTE-years)
for (col in injury_cols) {
  rate_col <- paste0(col, "_rate")
  dt[, (rate_col) := get(col) / hours * 200000]
}

## Total illness rate (sum of 5 illness categories)
dt[, total_illness := total_skin_disorders + total_respiratory_conditions +
     total_poisonings + total_hearing_loss + total_other_illnesses]
dt[, total_illness_rate := total_illness / hours * 200000]

## ── Filter to analysis sample ────────────────────────────────────────
## Keep manufacturing and services for main analysis
panel <- dt[sector_group %in% c("manufacturing", "services", "construction")]
cat("Analysis sample (mfg + services + construction):", nrow(panel), "\n")

## ── Create balanced panel of establishments present ≥4 years ────────
estab_years <- panel[, .(n_years = uniqueN(year)), by = establishment_id]
balanced_ids <- estab_years[n_years >= 4, establishment_id]
cat("Establishments with ≥4 years:", length(balanced_ids), "\n")

panel_bal <- panel[establishment_id %in% balanced_ids]
cat("Balanced panel rows:", nrow(panel_bal), "\n")

## ── Reshape to long format (establishment × hazard category × year) ─
## For triple-diff, stack injury categories
hazard_long <- melt(
  panel_bal,
  id.vars = c("establishment_id", "year", "naics2", "naics3", "naics4",
              "sector_group", "mfg", "high_silica", "post", "emp", "hours",
              "state", "company_name"),
  measure.vars = c("total_injuries_rate", "total_respiratory_conditions_rate",
                    "total_hearing_loss_rate", "total_skin_disorders_rate",
                    "total_other_illnesses_rate", "total_poisonings_rate"),
  variable.name = "hazard_type",
  value.name = "rate"
)

## Clean hazard type labels
hazard_long[, hazard := gsub("total_|_rate", "", hazard_type)]

## Targeted by silica standard = respiratory conditions
## Non-targeted = all other categories
hazard_long[, targeted := as.integer(hazard == "respiratory_conditions")]
hazard_long[, non_targeted := 1L - targeted]

cat("\nHazard-long panel rows:", nrow(hazard_long), "\n")
cat("Unique establishments:", uniqueN(hazard_long$establishment_id), "\n")

## ── Summary statistics ───────────────────────────────────────────────
cat("\n=== Sample by sector group ===\n")
print(panel_bal[, .(
  n_estab = uniqueN(establishment_id),
  n_obs = .N,
  mean_emp = round(mean(emp, na.rm = TRUE), 0),
  mean_injury_rate = round(mean(total_injuries_rate, na.rm = TRUE), 2),
  mean_resp_rate = round(mean(total_respiratory_conditions_rate, na.rm = TRUE), 3),
  mean_hearing_rate = round(mean(total_hearing_loss_rate, na.rm = TRUE), 3)
), by = sector_group])

cat("\n=== Injury rates by sector × period ===\n")
print(panel_bal[, .(
  injury_rate = round(mean(total_injuries_rate, na.rm = TRUE), 2),
  resp_rate = round(mean(total_respiratory_conditions_rate, na.rm = TRUE), 3),
  hearing_rate = round(mean(total_hearing_loss_rate, na.rm = TRUE), 3),
  skin_rate = round(mean(total_skin_disorders_rate, na.rm = TRUE), 3),
  other_illness_rate = round(mean(total_other_illnesses_rate, na.rm = TRUE), 3),
  n = .N
), by = .(sector_group, post)])

## ── Save ─────────────────────────────────────────────────────────────
fwrite(panel_bal, "../data/panel_establishment.csv")
fwrite(hazard_long, "../data/panel_hazard_long.csv")

cat("\nSaved panel_establishment.csv and panel_hazard_long.csv\n")
cat("Ready for analysis.\n")
