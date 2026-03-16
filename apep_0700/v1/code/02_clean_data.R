## 02_clean_data.R — Clean and merge data for apep_0700
## UK LHA Freeze and Homelessness

source("00_packages.R")
setwd("../data")

## -----------------------------------------------------------------------
## 1. LHA rates: Compute treatment intensity (LHA gap by BRMA)
## -----------------------------------------------------------------------
cat("=== Processing LHA rates ===\n")
lha <- fread("lha_rates_all_years.csv")

# Compute the gap: % increase from 2015-16 (frozen) to 2020-21 (re-linked)
# Use 2-bed rate as the modal category for LHA claimants
lha_gap <- data.table(
  brma_name = lha[["BRMA name"]],
  lha_2bed_1516 = as.numeric(lha[["2015-16 2 bed weekly rate"]]),
  lha_2bed_2021 = as.numeric(lha[["2020-21 2 bed weekly rate"]])
)

# The gap = how much the LHA WOULD HAVE been vs how much it WAS (frozen)
# Treatment intensity = (counterfactual - frozen) / frozen
# Since 2020-21 is the re-linked rate, it reflects what the rate should have been
lha_gap[, gap_pct := (lha_2bed_2021 - lha_2bed_1516) / lha_2bed_1516 * 100]

cat("LHA gap distribution:\n")
cat(sprintf("  Mean: %.1f%%\n", mean(lha_gap$gap_pct, na.rm = TRUE)))
cat(sprintf("  SD: %.1f%%\n", sd(lha_gap$gap_pct, na.rm = TRUE)))
cat(sprintf("  Min: %.1f%% (%s)\n", min(lha_gap$gap_pct, na.rm = TRUE),
            lha_gap$brma_name[which.min(lha_gap$gap_pct)]))
cat(sprintf("  Max: %.1f%% (%s)\n", max(lha_gap$gap_pct, na.rm = TRUE),
            lha_gap$brma_name[which.max(lha_gap$gap_pct)]))

## -----------------------------------------------------------------------
## 2. BRMA-to-LA mapping (from spatial centroid analysis)
## -----------------------------------------------------------------------
cat("\n=== Loading BRMA-to-LA mapping ===\n")
brma_la <- fread("brma_la_mapping_combined.csv")
cat("  BRMAs mapped:", nrow(brma_la), "\n")

# Merge LHA gap onto the mapping
brma_la <- merge(brma_la, lha_gap[, .(brma_name, gap_pct, lha_2bed_1516, lha_2bed_2021)],
                 by = "brma_name", all.x = TRUE)
stopifnot(all(!is.na(brma_la$gap_pct)))

## -----------------------------------------------------------------------
## 3. Build LA-level BRMA assignment
## -----------------------------------------------------------------------
# Note: This maps BRMA centroids to their primary LA. BRMAs that span
# multiple LAs will be assigned to the LA containing the centroid.
# We'll also create a reverse lookup: for each LA in the homelessness data,
# assign the BRMA whose centroid falls in that LA.

# For LAs that don't have a BRMA centroid, we need to assign them to the
# nearest BRMA. We'll do this after loading the homelessness data.

## -----------------------------------------------------------------------
## 4. Homelessness data: Table 784a (quarterly, 2014Q2-2018Q1)
## -----------------------------------------------------------------------
cat("\n=== Processing Table 784a (quarterly homelessness) ===\n")
library(readxl)

# Sheet names correspond to quarters
sheet_names <- excel_sheets("table_784a.xlsx")
quarter_sheets <- sheet_names[grepl("(Jun|Sep|Dec|Mar|March|June|Sept|September|December)_\\d{4}", sheet_names)]
cat("  Quarter sheets:", length(quarter_sheets), "\n")

# Parse each sheet
all_quarters <- list()
for (sh in quarter_sheets) {
  # Extract quarter from sheet name
  parts <- strsplit(sh, "_")[[1]]
  month_str <- parts[1]
  year_str <- parts[2]

  # Map month names to quarter numbers
  qmap <- c("Jun" = 1, "June" = 1, "Sep" = 2, "Sept" = 2, "September" = 2,
            "Dec" = 3, "December" = 3, "Mar" = 4, "March" = 4)
  q_num <- qmap[month_str]

  # Financial year quarter: Q1=Apr-Jun, Q2=Jul-Sep, Q3=Oct-Dec, Q4=Jan-Mar
  # Calendar quarter: Jun=Q2, Sep=Q3, Dec=Q4, Mar=Q1(next year)
  # Let's use calendar year-quarter for simplicity
  cal_year <- as.integer(year_str)
  cal_qmap <- c("Jun" = 2, "June" = 2, "Sep" = 3, "Sept" = 3, "September" = 3,
                "Dec" = 4, "December" = 4, "Mar" = 1, "March" = 1)
  cal_q <- cal_qmap[month_str]
  # March quarters belong to the calendar year of the sheet
  # But "Mar_2018" means Jan-Mar 2018, so cal_year is correct
  yq <- sprintf("%dQ%d", cal_year, cal_q)

  # Read data, skipping header rows
  d <- tryCatch({
    read_excel("table_784a.xlsx", sheet = sh, skip = 4, col_names = FALSE)
  }, error = function(e) NULL)

  if (is.null(d)) next

  # Clean: column 1 = ONS code, 2 = LA name, 3 = region,
  # 5 = number of households (000s), 12 = total acceptances,
  # 13 = acceptance rate per 1000, 17 = total decisions,
  # 23 = total in TA
  names(d) <- paste0("V", 1:ncol(d))

  # Filter to LA-level rows (ONS code starts with E)
  d <- as.data.table(d)
  d <- d[grepl("^E0[67890]", V1)]

  quarter_dt <- data.table(
    la_code = as.character(d$V1),
    la_name_raw = as.character(d$V2),
    region = as.character(d$V3),
    households_000 = suppressWarnings(as.numeric(d$V5)),
    acceptances = suppressWarnings(as.numeric(d$V12)),
    accept_rate_per1000 = suppressWarnings(as.numeric(d$V13)),
    total_decisions = suppressWarnings(as.numeric(d$V17)),
    total_ta = suppressWarnings(as.numeric(d$V23)),
    ta_rate_per1000 = suppressWarnings(as.numeric(d$V24)),
    yq = yq
  )

  all_quarters[[sh]] <- quarter_dt
}

homelessness <- rbindlist(all_quarters, fill = TRUE)
cat("  Total rows:", nrow(homelessness), "\n")
cat("  Unique LAs:", uniqueN(homelessness$la_code), "\n")
cat("  Quarters:", paste(sort(unique(homelessness$yq)), collapse = ", "), "\n")

# Replace "--" coded as NA (from Excel) — these are genuine zeros or suppressed
# For acceptances, treat NA as 0 (suppressed small counts)
homelessness[is.na(acceptances), acceptances := 0]

## -----------------------------------------------------------------------
## 5. Assign BRMAs to LAs
## -----------------------------------------------------------------------
cat("\n=== Assigning BRMAs to LAs ===\n")

# Strategy: for each LA in homelessness data, find the best BRMA match
# Step 1: Direct merge on la_code (from centroid mapping)
# This gives one BRMA to ~47 LAs directly
# Step 2: For unmapped LAs, use the BRMA shapefile spatial join

# First, create a complete LA→BRMA lookup
# The brma_la mapping has one LA per BRMA (centroid-based)
# Many LAs share a BRMA. We need the reverse: for each LA, which BRMA?

# Load the BRMA shapefile and do a proper spatial join
library(sf)
sf_use_s2(FALSE)

brma_shp <- st_read("brma_shp/BRMA_England_0412.shp", quiet = TRUE)
st_crs(brma_shp) <- 27700
brma_shp <- st_make_valid(brma_shp)

# Get unique LAs and their approximate locations
# Use postcodes.io to get coordinates for each LA
unique_las <- unique(homelessness$la_code)
cat("  Unique LAs to map:", length(unique_las), "\n")

# For efficiency, look up each LA via postcodes.io using outcode search
# First, try direct merge with existing mapping
la_brma <- merge(
  data.table(la_code = unique_las),
  brma_la[, .(la_code, brma_name, gap_pct)],
  by = "la_code", all.x = TRUE
)

cat("  Directly mapped:", sum(!is.na(la_brma$brma_name)), "\n")
cat("  Need mapping:", sum(is.na(la_brma$brma_name)), "\n")

# For unmapped LAs, use postcodes.io to get coordinates, then spatial join
unmapped_las <- la_brma[is.na(brma_name)]$la_code

if (length(unmapped_las) > 0) {
  cat("  Looking up", length(unmapped_las), "LAs via postcodes.io...\n")

  la_coords <- list()
  for (la in unmapped_las) {
    # Get a random postcode for this LA using the outcodes approach
    url <- sprintf("https://api.postcodes.io/postcodes?query=%s&limit=1",
                   URLencode(homelessness[la_code == la, la_name_raw[1]]))
    resp <- tryCatch({
      r <- request(url) |> req_perform()
      b <- resp_body_json(r)
      if (!is.null(b$result) && length(b$result) > 0) {
        data.table(la_code = la,
                   lon = b$result[[1]]$longitude,
                   lat = b$result[[1]]$latitude)
      } else NULL
    }, error = function(e) NULL)

    if (!is.null(resp)) la_coords[[la]] <- resp
    Sys.sleep(0.06)
  }

  if (length(la_coords) > 0) {
    la_pts <- rbindlist(la_coords)
    cat("  Got coordinates for", nrow(la_pts), "LAs\n")

    # Create sf points and spatial join with BRMA polygons
    la_sf <- st_as_sf(la_pts, coords = c("lon", "lat"), crs = 4326)
    la_sf_bng <- st_transform(la_sf, 27700)

    # Spatial join
    joined <- st_join(la_sf_bng, brma_shp[, "Name"])
    joined_dt <- data.table(la_code = joined$la_code, brma_name = joined$Name)

    # Update the mapping
    for (i in 1:nrow(joined_dt)) {
      if (!is.na(joined_dt$brma_name[i])) {
        la_brma[la_code == joined_dt$la_code[i], brma_name := joined_dt$brma_name[i]]
      }
    }

    # Get gap_pct for newly mapped LAs
    la_brma <- merge(la_brma[, .(la_code, brma_name)],
                     lha_gap[, .(brma_name, gap_pct)],
                     by = "brma_name", all.x = TRUE)
  }
}

cat("\n  Final mapping: ", sum(!is.na(la_brma$brma_name)), "/", nrow(la_brma), "LAs mapped\n")

# For any remaining unmapped LAs, assign median gap (conservative)
median_gap <- median(lha_gap$gap_pct, na.rm = TRUE)
la_brma[is.na(gap_pct), gap_pct := median_gap]
la_brma[is.na(brma_name), brma_name := "UNMAPPED"]
cat("  Assigned median gap (", round(median_gap, 1), "%) to unmapped LAs\n")

## -----------------------------------------------------------------------
## 6. Merge everything into analysis panel
## -----------------------------------------------------------------------
cat("\n=== Building analysis panel ===\n")

panel <- merge(homelessness, la_brma[, .(la_code, brma_name, gap_pct)],
               by = "la_code", all.x = TRUE)

# Create time variables
panel[, year := as.integer(substr(yq, 1, 4))]
panel[, quarter := as.integer(substr(yq, 6, 6))]

# Create a numeric time index for event study
# The freeze started April 2016 = 2016Q2
# Create relative time: quarters since/before 2016Q2
panel[, t_num := (year - 2016) * 4 + quarter]
# 2016Q2 -> t_num = 2, so normalize: relative_q = t_num - 2
panel[, relative_q := t_num - 2]

# Post indicator: 1 if >= 2016Q2
panel[, post := as.integer(relative_q >= 0)]

# Treatment variable: gap × post
panel[, treatment := gap_pct * post]

# Acceptance rate per 1,000 households (primary outcome)
# If accept_rate_per1000 is missing, compute from acceptances and households
panel[is.na(accept_rate_per1000) & households_000 > 0,
      accept_rate_per1000 := acceptances / (households_000) ]

cat("  Panel dimensions:", nrow(panel), "rows,", ncol(panel), "cols\n")
cat("  LAs:", uniqueN(panel$la_code), "\n")
cat("  Quarters:", uniqueN(panel$yq), "\n")
cat("  Post quarters:", sum(panel$post == 1) / uniqueN(panel$la_code), "\n")
cat("  Pre quarters:", sum(panel$post == 0) / uniqueN(panel$la_code), "\n")

# Summary statistics
cat("\n=== Key Statistics ===\n")
cat(sprintf("  Mean acceptances per LA-quarter: %.1f\n", mean(panel$acceptances, na.rm = TRUE)))
cat(sprintf("  Mean acceptance rate (per 1,000 HH): %.2f\n", mean(panel$accept_rate_per1000, na.rm = TRUE)))
cat(sprintf("  Mean TA households: %.1f\n", mean(panel$total_ta, na.rm = TRUE)))
cat(sprintf("  Mean gap (treatment intensity): %.1f%%\n", mean(panel$gap_pct, na.rm = TRUE)))
cat(sprintf("  SD gap: %.1f%%\n", sd(panel$gap_pct, na.rm = TRUE)))

## -----------------------------------------------------------------------
## 7. NOMIS claimant count (controls)
## -----------------------------------------------------------------------
cat("\n=== Processing NOMIS claimant count ===\n")
cc <- fread("nomis_claimant_count.csv")
# Parse date: format is "March 2023" or "2023 March"
cc[, date_clean := gsub(" ", "-", DATE_NAME)]
cc[, month_year := as.Date(paste0("01-", DATE_NAME), format = "%d-%B %Y")]
cc[, year := year(month_year)]
cc[, quarter := quarter(month_year)]
cc[, yq := sprintf("%dQ%d", year, quarter)]

# Aggregate monthly claimant count to quarterly mean by LA
cc_quarterly <- cc[, .(claimant_count = mean(OBS_VALUE, na.rm = TRUE)),
                   by = .(la_code = GEOGRAPHY_CODE, yq)]

# Merge onto panel
panel <- merge(panel, cc_quarterly, by = c("la_code", "yq"), all.x = TRUE)
cat("  Claimant count merged:", sum(!is.na(panel$claimant_count)), "/", nrow(panel), "\n")

## -----------------------------------------------------------------------
## 8. Save analysis panel
## -----------------------------------------------------------------------
fwrite(panel, "analysis_panel.csv")
cat("\n=== Analysis panel saved: analysis_panel.csv ===\n")
cat("  Dimensions:", nrow(panel), "x", ncol(panel), "\n")

# Save diagnostics for validator
diagnostics <- list(
  n_treated = uniqueN(panel[gap_pct > median(gap_pct)]$la_code),
  n_pre = uniqueN(panel[post == 0]$yq),
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, "diagnostics.json", auto_unbox = TRUE)
cat("  Diagnostics:", diagnostics$n_treated, "treated units,",
    diagnostics$n_pre, "pre-periods,", diagnostics$n_obs, "obs\n")

setwd("../code")
