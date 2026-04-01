# ==============================================================================
# 02_clean_data.R — Construct analysis panel for apep_1253
# ==============================================================================

source("00_packages.R")

cat("=== Loading raw data ===\n")

qwi   <- fread("../data/qwi_raw.csv", colClasses = list(character = c("fips", "industry", "agegrp")))
saipe <- fread("../data/saipe_2019.csv", colClasses = list(character = "fips"))
pop   <- fread("../data/population_2019.csv", colClasses = list(character = "fips"))

cat(sprintf("QWI: %s rows\n", format(nrow(qwi), big.mark = ",")))

# ==============================================================================
# Construct time variables
# ==============================================================================

qwi[, `:=`(
  yearqtr = year + (quarter - 1) / 4,
  time_id = (year - 2018) * 4 + quarter,  # 1 = 2018Q1
  post = as.integer(year > 2021 | (year == 2021 & quarter >= 4))
)]

# Treatment date: 2021Q4 (October 2021 TFP revision)
# time_id for 2021Q4 = (2021-2018)*4 + 4 = 16
qwi[, event_time := time_id - 16L]

cat(sprintf("Pre-treatment quarters: %d\n", length(unique(qwi[post == 0, time_id]))))
cat(sprintf("Post-treatment quarters: %d\n", length(unique(qwi[post == 1, time_id]))))

# ==============================================================================
# Clean QWI: handle suppressed cells
# ==============================================================================

# QWI uses status flags: 1 = publishable, 5 = suppressed, 9 = unavailable
# Keep only publishable employment data
qwi <- qwi[emp_status %in% c("1", "3") | is.na(emp_status)]

# Drop rows with missing employment
qwi <- qwi[!is.na(emp) & emp > 0]

cat(sprintf("QWI after cleaning suppressed cells: %s rows\n",
            format(nrow(qwi), big.mark = ",")))

# ==============================================================================
# Aggregate across age groups within county-quarter-industry
# ==============================================================================

panel <- qwi[, .(
  emp          = sum(emp, na.rm = TRUE),
  hires_all    = sum(hires_all, na.rm = TRUE),
  separations  = sum(separations, na.rm = TRUE),
  avg_earnings = weighted.mean(avg_earnings, emp, na.rm = TRUE),
  firm_job_gains = sum(firm_job_gains, na.rm = TRUE),
  firm_job_losses = sum(firm_job_losses, na.rm = TRUE)
), by = .(fips, year, quarter, yearqtr, time_id, post, event_time, industry)]

cat(sprintf("Panel (county-quarter-industry): %s rows\n",
            format(nrow(panel), big.mark = ",")))

# ==============================================================================
# Merge treatment intensity (SAIPE poverty rate as SNAP proxy)
# ==============================================================================

# SNAP participation is highly correlated with poverty rate (r > 0.85)
# Using 2019 poverty rate as predetermined treatment intensity
panel <- merge(panel, saipe[, .(fips, poverty_rate, child_poverty_rate, median_hh_income)],
               by = "fips", all.x = TRUE)

# Merge population for weighting
panel <- merge(panel, pop[, .(fips, population)],
               by = "fips", all.x = TRUE)

# Drop counties without poverty/population data
n_before <- nrow(panel)
panel <- panel[!is.na(poverty_rate) & !is.na(population)]
cat(sprintf("Dropped %d rows without SAIPE/population data\n", n_before - nrow(panel)))

# ==============================================================================
# Construct key variables
# ==============================================================================

# Log employment (main outcome)
panel[, log_emp := log(emp)]

# Treatment intensity × post interaction
panel[, treat_post := poverty_rate * post]

# Standardize poverty rate (for interpretation)
panel[, poverty_rate_std := (poverty_rate - mean(poverty_rate)) / sd(poverty_rate)]
panel[, treat_post_std := poverty_rate_std * post]

# State FIPS for clustering
panel[, state_fips := substr(fips, 1, 2)]

# Create county-industry FE identifier
panel[, county_industry := paste0(fips, "_", industry)]

# Industry-quarter FE identifier
panel[, industry_quarter := paste0(industry, "_", time_id)]

# ==============================================================================
# Industry labels
# ==============================================================================

ind_labels <- data.table(
  industry = c("72", "44-45", "62", "56", "31-33", "54", "52"),
  ind_label = c("Food Services", "Retail Trade", "Healthcare",
                "Admin/Waste", "Manufacturing", "Professional Svcs", "Finance")
)
panel <- merge(panel, ind_labels, by = "industry", all.x = TRUE)

# ==============================================================================
# Create balanced panel flag
# ==============================================================================

# Count time periods per county-industry
n_periods <- panel[, .N, by = .(fips, industry)]
max_t <- max(n_periods$N)
panel[, balanced := fips %in% n_periods[N == max_t, fips]]

cat(sprintf("Balanced panel counties: %d / %d\n",
            length(unique(panel[balanced == TRUE, fips])),
            length(unique(panel$fips))))

# ==============================================================================
# Summary
# ==============================================================================

cat("\n=== Panel Summary ===\n")
cat(sprintf("Counties: %d\n", length(unique(panel$fips))))
cat(sprintf("States: %d\n", length(unique(panel$state_fips))))
cat(sprintf("Industries: %d\n", length(unique(panel$industry))))
cat(sprintf("Quarters: %d (%d pre, %d post)\n",
            length(unique(panel$time_id)),
            length(unique(panel[post == 0, time_id])),
            length(unique(panel[post == 1, time_id]))))
cat(sprintf("Total obs: %s\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("Poverty rate: mean=%.1f%%, sd=%.1f%%, range=[%.1f%%, %.1f%%]\n",
            mean(panel$poverty_rate), sd(panel$poverty_rate),
            min(panel$poverty_rate), max(panel$poverty_rate)))

# Save
fwrite(panel, "../data/analysis_panel.csv")
cat("\nSaved analysis panel to data/analysis_panel.csv\n")
