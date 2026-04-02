# 02_clean_data.R — Data cleaning and panel construction for apep_1319
# Merges ASB incident data with ASBO treatment intensity and population

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# Load raw data
# ============================================================================

asb_raw <- fread(file.path(data_dir, "asb_monthly_raw.csv"))
asbo_data <- fread(file.path(data_dir, "asbo_issuance_by_cjs_area.csv"))
pop_data <- fread(file.path(data_dir, "population_by_force.csv"))

cat("Raw panel data:", nrow(asb_raw), "rows\n")

# The panel already has cjs_area from the fetch script
asb_panel <- copy(asb_raw)

# Parse date
asb_panel[, year_month := as.Date(paste0(date, "-01"))]
asb_panel[, year := year(year_month)]
asb_panel[, month := month(year_month)]

# Rename force_slug to force_id for consistency
setnames(asb_panel, "force_slug", "force_id", skip_absent = TRUE)

# ============================================================================
# Merge treatment intensity (ASBO rates)
# ============================================================================

asb_panel <- merge(asb_panel, asbo_data, by = "cjs_area", all.x = TRUE)
stopifnot(sum(is.na(asb_panel$asbo_total)) == 0)

# ============================================================================
# Merge population and construct rates
# ============================================================================

asb_panel <- merge(asb_panel, pop_data, by = "cjs_area", all.x = TRUE)
stopifnot(sum(is.na(asb_panel$population_2014)) == 0)

# Construct rates per 100,000
asb_panel[, asb_rate := asb_count / population_2014 * 100000]
asb_panel[, burglary_rate := burglary_count / population_2014 * 100000]

# Treatment intensity: ASBOs per 100,000 population
asb_panel[, asbo_rate_pc := asbo_total / population_2014 * 100000]

# Standardize treatment for easier interpretation
asb_panel[, asbo_rate_std := (asbo_rate_pc - mean(asbo_rate_pc)) / sd(asbo_rate_pc)]

# ============================================================================
# Create treatment variables
# ============================================================================

# Reform date: 20 October 2014 — first full post-reform month is November 2014
asb_panel[, post := as.integer(year_month >= as.Date("2014-11-01"))]

# October 2014 is partial — exclude for clean identification
asb_panel <- asb_panel[year_month != as.Date("2014-10-01")]

# Interaction (continuous treatment DiD)
asb_panel[, post_asbo := post * asbo_rate_pc]
asb_panel[, post_asbo_std := post * asbo_rate_std]

# Event time (months relative to reform)
asb_panel[, event_time := as.integer(difftime(year_month, as.Date("2014-10-01"), units = "days")) / 30.44]
asb_panel[, event_time := round(event_time)]

# ============================================================================
# Panel diagnostics
# ============================================================================

cat("\n=== Panel Summary ===\n")
cat("Forces:", uniqueN(asb_panel$cjs_area), "\n")
cat("Date range:", as.character(min(asb_panel$year_month)), "to", as.character(max(asb_panel$year_month)), "\n")
cat("Total obs:", nrow(asb_panel), "\n")
cat("Pre-reform obs:", sum(asb_panel$post == 0), "\n")
cat("Post-reform obs:", sum(asb_panel$post == 1), "\n")
cat("Missing ASB counts:", sum(is.na(asb_panel$asb_count)), "\n")
cat("Missing burglary counts:", sum(is.na(asb_panel$burglary_count)), "\n")

# Treatment intensity summary
cat("\n=== Treatment Intensity (ASBOs per 100k) ===\n")
intensity <- asb_panel[, .(asbo_rate_pc = first(asbo_rate_pc)), by = cjs_area]
cat("Min:", round(min(intensity$asbo_rate_pc), 1), "\n")
cat("P25:", round(quantile(intensity$asbo_rate_pc, 0.25), 1), "\n")
cat("Median:", round(median(intensity$asbo_rate_pc), 1), "\n")
cat("P75:", round(quantile(intensity$asbo_rate_pc, 0.75), 1), "\n")
cat("Max:", round(max(intensity$asbo_rate_pc), 1), "\n")
cat("SD:", round(sd(intensity$asbo_rate_pc), 1), "\n")

# Drop observations with missing outcome
asb_panel <- asb_panel[!is.na(asb_count)]
cat("\nFinal panel after dropping missing:", nrow(asb_panel), "obs\n")

# ============================================================================
# Save cleaned panel
# ============================================================================

fwrite(asb_panel, file.path(data_dir, "asb_panel_clean.csv"))
cat("Saved cleaned panel to", file.path(data_dir, "asb_panel_clean.csv"), "\n")
