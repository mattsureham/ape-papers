## 02_clean_data.R — Clean and construct analysis dataset
## apep_0845: EU Professional Qualifications Directive

source("code/00_packages.R")

cat("\n=== CLEANING DATA ===\n")

## ─── Load raw data ────────────────────────────────────────────────────────
oq_raw <- readRDS("data/oq_raw.rds")
regulated_profs <- readRDS("data/regulated_profs.rds")
transposition <- readRDS("data/transposition.rds")

## ─── EU27 member states ──────────────────────────────────────────────────
eu27 <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
          "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
          "PL", "PT", "RO", "SK", "SI", "ES", "SE")

## ─── 1. Overqualification panel ──────────────────────────────────────────
oq <- as.data.table(oq_raw)

cat("Raw overqualification columns:", names(oq), "\n")
cat("Citizen values:", unique(oq$citizen), "\n")

# Keep: age 20-64, both sexes, relevant citizenship groups
# Include FOR (all foreign) for broader coverage (24 countries vs 18 for EU-only)
oq <- oq[age == "Y20-64" & sex == "T" &
          citizen %in% c("NAT", "EU27_2020_FOR", "NEU27_2020_FOR", "FOR")]

# Keep only EU27 countries (2-letter geo codes)
oq <- oq[nchar(geo) == 2 & geo %in% eu27]

# Rename time column
setnames(oq, "TIME_PERIOD", "year", skip_absent = TRUE)
if (!"year" %in% names(oq) && "time" %in% names(oq)) setnames(oq, "time", "year")
oq[, year := as.integer(year)]

# Create citizenship group labels
oq[, cit_group := fcase(
  citizen == "NAT", "nat",
  citizen == "EU27_2020_FOR", "eu_for",
  citizen == "NEU27_2020_FOR", "non_eu_for",
  citizen == "FOR", "all_for"
)]

# Pivot to wide: one row per country-year
oq_wide <- dcast(oq, geo + year ~ cit_group, value.var = "values",
                 fun.aggregate = mean, na.rm = TRUE)

# Construct overqualification gaps
# Primary: all-foreign vs national (24 countries coverage)
oq_wide[, oq_gap_all := all_for - nat]
# Secondary: EU-foreign vs national (18 countries)
oq_wide[, oq_gap := eu_for - nat]
# Placebo: non-EU-foreign vs national (23 countries)
oq_wide[, oq_gap_noneu := non_eu_for - nat]

# Drop rows where primary outcome is missing
oq_wide <- oq_wide[!is.na(oq_gap_all)]

# Rename geo to country for clarity
setnames(oq_wide, "geo", "country")

cat(sprintf("Overqualification panel: %d country-years, %d countries, years %d-%d\n",
            nrow(oq_wide), uniqueN(oq_wide$country),
            min(oq_wide$year, na.rm = TRUE), max(oq_wide$year, na.rm = TRUE)))

## ─── 2. Merge treatment variables ────────────────────────────────────────

# Merge regulated professions count
panel <- merge(oq_wide, regulated_profs, by.x = "country", by.y = "geo", all.x = TRUE)

# Merge transposition dates
if ("trans_year" %in% names(transposition)) {
  panel <- merge(panel, transposition, by.x = "country", by.y = "geo", all.x = TRUE)
}

# Drop observations with missing treatment
panel <- panel[!is.na(n_regulated)]

# Construct treatment variables
# Post = after transposition deadline (Jan 2016)
panel[, post := as.integer(year >= 2016)]

# Continuous treatment intensity (standardized)
panel[, rp_std := (n_regulated - mean(n_regulated, na.rm = TRUE)) /
        sd(n_regulated, na.rm = TRUE)]

# High vs low regulation (above/below median)
panel[, high_reg := as.integer(n_regulated >= median(n_regulated, na.rm = TRUE))]

# Interaction terms
panel[, treat_post := rp_std * post]
panel[, high_reg_post := high_reg * post]

# Event time for event study
panel[, event_time := year - 2016]

## ─── 3. Summary statistics ───────────────────────────────────────────────
cat("\n=== PANEL SUMMARY ===\n")
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("Countries: %d\n", uniqueN(panel$country)))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("Regulated professions: %d-%d (mean=%.0f, sd=%.0f)\n",
            min(panel$n_regulated), max(panel$n_regulated),
            mean(panel$n_regulated), sd(panel$n_regulated)))
cat(sprintf("Overqualification gap (EU-foreign minus national):\n"))
cat(sprintf("  Pre-2016 mean: %.1f pp (n=%d)\n",
            mean(panel[year < 2016]$oq_gap, na.rm = TRUE),
            sum(!is.na(panel[year < 2016]$oq_gap))))
cat(sprintf("  Post-2016 mean: %.1f pp (n=%d)\n",
            mean(panel[year >= 2016]$oq_gap, na.rm = TRUE),
            sum(!is.na(panel[year >= 2016]$oq_gap))))
cat(sprintf("  EU-foreign OQ rate: pre=%.1f%%, post=%.1f%%\n",
            mean(panel[year < 2016]$eu_for, na.rm = TRUE),
            mean(panel[year >= 2016]$eu_for, na.rm = TRUE)))
cat(sprintf("  National OQ rate: pre=%.1f%%, post=%.1f%%\n",
            mean(panel[year < 2016]$nat, na.rm = TRUE),
            mean(panel[year >= 2016]$nat, na.rm = TRUE)))

## ─── Save analysis dataset ───────────────────────────────────────────────
saveRDS(panel, "data/analysis_panel.rds")
fwrite(panel, "data/analysis_panel.csv")

cat("\n=== CLEANING COMPLETE ===\n")
