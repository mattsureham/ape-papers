## 01_fetch_data.R — Download and parse CDC NCHS natality microdata
## APEP-1232: Medicaid Doula Reimbursement and Birth Outcomes
##
## Source: NCHS Natality Public-Use Files 2018-2023
## https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/natality/
##
## Field positions verified against raw data inspection (2018 file):
##   DOB_YY:     9-12  (year, confirmed)
##   DOB_MM:    13-14  (month, confirmed)
##   STATE:     21-22  (NCHS state code, 61 unique values 00-59+99)
##   MRACE6:      107  (race, 6 categories; 1=White thru 6=Multi)
##   DMETH_REC:   408  (delivery method; 1=Vaginal, 2=C-section, 9=Unk)
##   PAY_REC:     436  (payment; 1=Medicaid, 2=Private, 3=Self, 4=Other, 9=Unk)
##   OEGEST_R10: 492-493 (gestational age 10-cat recode; 01-05=preterm)
##   DBWT:      504-507 (birth weight in grams)

source("00_packages.R")

# Increase download timeout for large files (~230MB each)
options(timeout = 600)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

out_file <- file.path(data_dir, "natality_panel.rds")

if (file.exists(out_file)) {
  cat("Collapsed panel already exists:", out_file, "\n")
  quit(save = "no")
}

# ─── NCHS state code → state abbreviation mapping ────────────────────────────
# NCHS codes are alphabetical: 01=AL, 02=AK, ..., 09=DC, ..., 51=WY
# Source: NCHS Natality User Guide
nchs_states <- c(
  "01" = "AL", "02" = "AK", "03" = "AZ", "04" = "AR", "05" = "CA",
  "06" = "CO", "07" = "CT", "08" = "DE", "09" = "DC", "10" = "FL",
  "11" = "GA", "12" = "HI", "13" = "ID", "14" = "IL", "15" = "IN",
  "16" = "IA", "17" = "KS", "18" = "KY", "19" = "LA", "20" = "ME",
  "21" = "MD", "22" = "MA", "23" = "MI", "24" = "MN", "25" = "MS",
  "26" = "MO", "27" = "MT", "28" = "NE", "29" = "NV", "30" = "NH",
  "31" = "NJ", "32" = "NM", "33" = "NY", "34" = "NC", "35" = "ND",
  "36" = "OH", "37" = "OK", "38" = "OR", "39" = "PA", "40" = "RI",
  "41" = "SC", "42" = "SD", "43" = "TN", "44" = "TX", "45" = "UT",
  "46" = "VT", "47" = "VA", "48" = "WA", "49" = "WV", "50" = "WI",
  "51" = "WY"
)

# ─── Column positions ────────────────────────────────────────────────────────
col_spec <- fwf_positions(
  start = c( 9, 13, 21, 107, 408, 436, 492, 504),
  end   = c(12, 14, 22, 107, 408, 436, 493, 507),
  col_names = c("dob_yy", "dob_mm", "nchs_state", "mrace6",
                "dmeth_rec", "pay_rec", "oegest_r10", "dbwt")
)

years <- 2018:2023
all_collapsed <- list()

for (yr in years) {
  cat("\n========== Processing", yr, "==========\n")

  zip_file <- file.path(data_dir, paste0("Nat", yr, "us.zip"))

  # Download if not present (or if file is too small = corrupt)
  if (!file.exists(zip_file) || file.size(zip_file) < 100000000) {
    if (file.exists(zip_file)) file.remove(zip_file)
    url <- paste0("https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/natality/Nat",
                  yr, "us.zip")
    cat("Downloading:", url, "\n")
    # Use curl for reliable large-file downloads
    dl_exit <- system2("curl", args = c("-L", "-o", zip_file, url,
                                        "--max-time", "600", "--retry", "3"),
                       stdout = FALSE, stderr = "")
    if (dl_exit != 0 || !file.exists(zip_file) || file.size(zip_file) < 1e8) {
      stop("FATAL: Cannot download natality data for ", yr, ". Aborting.")
    }
  }
  cat("Zip size:", round(file.size(zip_file) / 1e6, 1), "MB\n")

  # Find text file inside zip
  zip_contents <- unzip(zip_file, list = TRUE)$Name
  cat("Zip contents:", paste(zip_contents, collapse = ", "), "\n")
  txt_file <- zip_contents[1]
  cat("Extracting:", txt_file, "\n")

  # Extract using system unzip (R's unzip() fails on large files)
  tmp_dir <- tempdir()
  system2("unzip", args = c("-o", zip_file, txt_file, "-d", tmp_dir),
          stdout = FALSE, stderr = FALSE)
  extracted_path <- file.path(tmp_dir, txt_file)

  # Handle potential subdirectory or name mismatch
  if (!file.exists(extracted_path)) {
    possible <- list.files(tmp_dir, pattern = paste0("Nat", yr), recursive = TRUE,
                           full.names = TRUE)
    if (length(possible) > 0) {
      extracted_path <- possible[1]
      cat("Found at:", extracted_path, "\n")
    } else {
      stop("FATAL: Extracted file not found for ", yr)
    }
  }

  cat("File size:", round(file.size(extracted_path) / 1e6, 1), "MB\n")

  # Parse
  cat("Parsing fixed-width columns...\n")
  raw <- read_fwf(
    extracted_path,
    col_positions = col_spec,
    col_types = cols(
      dob_yy = col_integer(),
      dob_mm = col_integer(),
      nchs_state = col_character(),
      mrace6 = col_character(),
      dmeth_rec = col_integer(),
      pay_rec = col_integer(),
      oegest_r10 = col_integer(),
      dbwt = col_integer()
    ),
    progress = TRUE
  )

  cat("  Rows parsed:", nrow(raw), "\n")
  stopifnot("No rows parsed" = nrow(raw) > 0)

  # Clean up large extracted file immediately to save disk
  unlink(extracted_path)

  # Map NCHS state code to state abbreviation
  raw <- raw %>%
    mutate(state = nchs_states[nchs_state]) %>%
    filter(!is.na(state))  # Drop territories and unknown

  cat("  Rows with valid state:", nrow(raw), "\n")
  cat("  States:", n_distinct(raw$state), "\n")

  # Validate year
  yr_check <- table(raw$dob_yy)
  cat("  Year distribution:", paste(names(yr_check), yr_check, sep = "=", collapse = ", "), "\n")

  # Check delivery method distribution
  dmeth_tab <- table(raw$dmeth_rec, useNA = "always")
  cat("  DMETH_REC:", paste(names(dmeth_tab), dmeth_tab, sep = "=", collapse = ", "), "\n")

  # Check payer distribution
  pay_tab <- table(raw$pay_rec, useNA = "always")
  cat("  PAY_REC:", paste(names(pay_tab), pay_tab, sep = "=", collapse = ", "), "\n")

  # ─── Collapse to state × year × payer cells ────────────────────────────────
  collapsed <- raw %>%
    filter(
      dmeth_rec %in% c(1, 2),   # Vaginal or C-section (drop unknown)
      pay_rec %in% c(1, 2)      # Medicaid or Private (drop other/unknown)
    ) %>%
    mutate(
      csection = as.integer(dmeth_rec == 2),
      # Preterm: OEGEST_R10 categories 01-05 are < 37 weeks
      preterm = as.integer(!is.na(oegest_r10) & oegest_r10 <= 5),
      lbw = as.integer(!is.na(dbwt) & dbwt > 0 & dbwt < 2500),
      payer = ifelse(pay_rec == 1, "medicaid", "private"),
      race_cat = case_when(
        mrace6 == "1" ~ "white",
        mrace6 == "2" ~ "black",
        TRUE ~ "other"
      )
    ) %>%
    group_by(dob_yy, state, payer) %>%
    summarise(
      births = n(),
      csections = sum(csection),
      preterm_births = sum(preterm),
      lbw_births = sum(lbw),
      csection_rate = mean(csection),
      preterm_rate = mean(preterm),
      lbw_rate = mean(lbw),
      mean_bw = mean(dbwt[dbwt > 0], na.rm = TRUE),
      # Race-specific C-section counts
      births_black = sum(race_cat == "black"),
      csection_black = sum(csection[race_cat == "black"]),
      births_white = sum(race_cat == "white"),
      csection_white = sum(csection[race_cat == "white"]),
      .groups = "drop"
    ) %>%
    mutate(
      csrate_black = ifelse(births_black > 0, csection_black / births_black, NA_real_),
      csrate_white = ifelse(births_white > 0, csection_white / births_white, NA_real_),
      csrate_bw_gap = csrate_black - csrate_white
    )

  cat("  Collapsed cells:", nrow(collapsed), "\n")
  cat("  Total births (Medicaid+Private):", sum(collapsed$births), "\n")
  cat("  Mean C-section rate:", round(mean(collapsed$csection_rate), 3), "\n")

  all_collapsed[[as.character(yr)]] <- collapsed

  rm(raw)
  gc()
}

# Bind all years
panel <- bind_rows(all_collapsed)

cat("\n========== PANEL SUMMARY ==========\n")
cat("Years:", paste(sort(unique(panel$dob_yy)), collapse = ", "), "\n")
cat("States:", n_distinct(panel$state), "\n")
cat("Total cells:", nrow(panel), "\n")
cat("Total births:", format(sum(panel$births), big.mark = ","), "\n")
cat("Overall C-section rate:", round(weighted.mean(panel$csection_rate, panel$births), 3), "\n")
cat("Medicaid births:", format(sum(panel$births[panel$payer == "medicaid"]), big.mark = ","), "\n")
cat("Private births:", format(sum(panel$births[panel$payer == "private"]), big.mark = ","), "\n")

# Save
saveRDS(panel, out_file)
cat("Saved collapsed panel to:", out_file, "\n")

# Clean up zip files to save disk space
for (yr in years) {
  zf <- file.path(data_dir, paste0("Nat", yr, "us.zip"))
  if (file.exists(zf)) {
    file.remove(zf)
    cat("Removed:", zf, "\n")
  }
}
