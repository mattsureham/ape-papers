# 02_clean_data.R — Construct analysis panel using HUC-12 assignments
source("00_packages.R")

# --- Load raw data ---
facilities <- readRDS("../data/facilities_raw.rds")
huc12_map <- readRDS("../data/facility_huc12.rds")
attains <- readRDS("../data/attains_303d.rds")

cat("=== Merging facility data with HUC-12 assignments ===\n")

# Focus on major facilities (have HUC-12 from lookup)
setDT(facilities)
setDT(huc12_map)
fac <- merge(facilities, huc12_map, by = "NPDES_ID", all.x = FALSE)
cat("Facilities with HUC-12:", nrow(fac), "\n")

# Clean
fac[, `:=`(
  lat = as.numeric(FAC_LAT),
  lon = as.numeric(FAC_LONG),
  huc8 = as.character(FAC_DERIVED_HUC),
  is_major = (CWP_MAJOR_MINOR_TYPE_FLAG == "M")
)]
fac <- fac[!is.na(huc12) & nchar(huc12) == 12]
cat("With valid HUC-12:", nrow(fac), "\n")

# Parse compliance status
fac[, compl_str := as.character(CWP_13QTRS_COMPL_STATUS)]
fac[, n_violation_qtrs := nchar(gsub("[^VES]", "", compl_str))]
fac[, pct_violation := n_violation_qtrs / 13]
fac[, any_violation := (n_violation_qtrs > 0)]

# --- Match to 303(d) listing ---
cat("\n=== Matching to 303(d) listings ===\n")
attains[, huc12 := as.character(huc12)]
listed_huc12s <- unique(attains[on303dlist == "Y" & !is.na(huc12) & nchar(huc12) == 12, .(huc12)])
listed_huc12s[, listed_303d := TRUE]

fac <- merge(fac, listed_huc12s, by = "huc12", all.x = TRUE)
fac[is.na(listed_303d), listed_303d := FALSE]

cat("Facilities in 303(d)-listed HUC-12:", sum(fac$listed_303d), "\n")
cat("Facilities in non-listed HUC-12:", sum(!fac$listed_303d), "\n")

# --- Construct boundary sample ---
huc8_var <- fac[, .(
  n_fac = .N,
  n_listed = sum(listed_303d),
  n_unlisted = sum(!listed_303d)
), by = huc8]
huc8_var[, has_variation := (n_listed > 0 & n_unlisted > 0)]

cat("\n=== HUC-8 variation (key for identification) ===\n")
cat("Total HUC-8s:", nrow(huc8_var), "\n")
cat("With within-variation:", sum(huc8_var$has_variation), "\n")
cat("All listed:", sum(huc8_var$n_unlisted == 0 & huc8_var$n_listed > 0), "\n")
cat("All unlisted:", sum(huc8_var$n_listed == 0), "\n")

fac <- merge(fac, huc8_var[, .(huc8, has_variation, n_fac)], by = "huc8", all.x = TRUE)
boundary <- fac[has_variation == TRUE]

cat("\nBoundary sample:\n")
cat("  Facilities:", nrow(boundary), "\n")
cat("  Treated:", sum(boundary$listed_303d), "\n")
cat("  Control:", sum(!boundary$listed_303d), "\n")
cat("  HUC-8s:", uniqueN(boundary$huc8), "\n")
cat("  States:", uniqueN(boundary$CWP_STATE), "\n")

# Save
saveRDS(fac, "../data/analysis_full.rds")
saveRDS(boundary, "../data/boundary_sample.rds")
cat("\nSaved analysis_full.rds and boundary_sample.rds\n")
