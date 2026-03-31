# 02_clean_data.R — Merge QWI + Asian population share, construct DDD variables

source("00_packages.R")

# ── Load data ──
qwi <- fread("../data/qwi_state_race_industry.csv")
asian_share <- fread("../data/state_asian_share.csv")

cat(sprintf("QWI: %d rows, %d states\n", nrow(qwi), uniqueN(qwi$state_fips)))
cat(sprintf("Asian share data: %d states\n", nrow(asian_share)))

# ── Construct time variable ──
qwi[, yrqtr := year + (quarter - 1) / 4]

# ── Classify sectors ──
qwi[, sector_type := fcase(
  industry %in% c("72", "44-45"), "customer_facing",
  industry %in% c("54", "51"),    "knowledge",
  industry == "00",               "all",
  default = NA_character_
)]
qwi <- qwi[!is.na(sector_type)]

# Aggregate customer-facing and knowledge sectors
# (combine NAICS 72 + 44-45 into one "customer_facing" group, 54 + 51 into "knowledge")
panel_sectors <- qwi[sector_type != "all",
  .(emp = sum(emp, na.rm = TRUE),
    hires = sum(hires, na.rm = TRUE),
    separations = sum(separations, na.rm = TRUE),
    total_earnings = sum(total_earnings, na.rm = TRUE),
    emp_with_earnings = sum(emp_with_earnings, na.rm = TRUE)),
  by = .(state_fips, year, quarter, yrqtr, race, sector_type)]

panel_sectors[, avg_earnings := fifelse(emp_with_earnings > 0,
                                         total_earnings / emp_with_earnings, NA_real_)]

# ── Merge Asian population share (cross-sectional, pre-determined) ──
panel <- merge(panel_sectors, asian_share[, .(state_fips, asian_share, asian_share_std, high_asian)],
               by = "state_fips", all.x = TRUE)

# Drop states without Census match (should be zero or very few)
n_before <- nrow(panel)
panel <- panel[!is.na(asian_share)]
cat(sprintf("Dropped %d rows without Asian share data\n", n_before - nrow(panel)))

# ── Construct DDD variables ──
panel[, asian := as.integer(race == "A4")]
panel[, customer_facing := as.integer(sector_type == "customer_facing")]

# Log employment (add 1 for zeros)
panel[, log_emp := log(emp + 1)]
panel[, log_hires := log(hires + 1)]
panel[, log_sep := log(separations + 1)]
panel[, log_earn := fifelse(avg_earnings > 0, log(avg_earnings), NA_real_)]

# Post-COVID indicator
panel[, post_covid := as.integer(yrqtr >= 2020.0)]

# ── Create event time variable (quarters relative to 2020Q1) ──
panel[, event_time := (year - 2020) * 4 + quarter - 1]

# ── Fixed effects identifiers (for fixest) ──
# fixest handles interactions natively, but we need state_fips as factor
panel[, state_fips := as.character(state_fips)]

# ── Normalize employment to Q4 2019 baseline ──
baseline <- panel[year == 2019 & quarter == 4,
                  .(base_emp = emp), by = .(state_fips, race, sector_type)]
panel <- merge(panel, baseline, by = c("state_fips", "race", "sector_type"), all.x = TRUE)
panel[, emp_index := fifelse(base_emp > 0, emp / base_emp * 100, NA_real_)]

# ── Summary statistics ──
cat("\n── Panel summary ──\n")
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("States: %d\n", uniqueN(panel$state_fips)))
cat(sprintf("Quarters: %d (%s to %s)\n",
            uniqueN(panel$yrqtr), min(panel$yrqtr), max(panel$yrqtr)))

cat("\n── Employment by race x sector (2019Q4) ──\n")
print(panel[year == 2019 & quarter == 4,
            .(total_emp = sum(emp, na.rm = TRUE), mean_emp = mean(emp, na.rm = TRUE)),
            by = .(race, sector_type)][order(race, sector_type)])

cat("\n── Asian share distribution across states ──\n")
print(summary(asian_share$asian_share))

# Validate
stopifnot("Panel has data" = nrow(panel) > 500)
stopifnot("Both race groups" = all(c("A1", "A4") %in% panel$race))
stopifnot("Both sectors" = all(c("customer_facing", "knowledge") %in% panel$sector_type))
stopifnot("Pre-COVID exists" = any(panel$yrqtr < 2020))
stopifnot("Post-COVID exists" = any(panel$yrqtr >= 2020))

# Save
fwrite(panel, "../data/analysis_panel.csv")
cat("\nAnalysis panel saved to data/analysis_panel.csv\n")
