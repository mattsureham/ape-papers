# 02_clean_data.R — Clean and construct analysis variables
# apep_0999: IR35 bunching at small company threshold

source("00_packages.R")

DATA_DIR <- "../data"

# --- Load NOMIS aggregate data ---
cat("Loading NOMIS business counts...\n")
nomis <- fread(file.path(DATA_DIR, "nomis_clean.csv"))

cat(sprintf("NOMIS data: %d rows\n", nrow(nomis)))
cat(sprintf("Years: %d to %d\n", min(nomis$year), max(nomis$year)))
cat(sprintf("Sectors: %s\n", paste(unique(nomis$sector_type), collapse = ", ")))
cat(sprintf("Size bands: %s\n", paste(sort(unique(nomis$emp_lower)), collapse = ", ")))

# --- Key outcome: bunching ratio 20-49 / 50-99 ---
bunching <- fread(file.path(DATA_DIR, "bunching_ratio_panel.csv"))

cat("\nBunching ratio summary:\n")
cat("Contractor-intensive sectors:\n")
print(bunching[contractor == 1, .(year, sic_name, bunching_ratio, count_20_49, count_50_99)])
cat("\nControl sectors:\n")
print(bunching[contractor == 0, .(year, sic_name, bunching_ratio, count_20_49, count_50_99)])

# --- Create analysis variables ---
bunching[, year_f := factor(year)]

# Treatment period: 2021+ for IR35 private-sector extension
bunching[, post_2021 := as.integer(year >= 2021)]
bunching[, contractor := as.integer(sector_type == "contractor")]

# Full analysis panel with all sizebands
analysis <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
analysis[, year_f := factor(year)]

# Log counts for regression
analysis[, log_count := log(pmax(count, 1))]

# Save cleaned datasets
fwrite(bunching, file.path(DATA_DIR, "bunching_clean.csv"))
fwrite(analysis, file.path(DATA_DIR, "analysis_clean.csv"))

cat("\n=== Data cleaning complete ===\n")
cat(sprintf("Bunching panel: %d sector-year observations\n", nrow(bunching)))
cat(sprintf("Full panel: %d sector-band-year observations\n", nrow(analysis)))
