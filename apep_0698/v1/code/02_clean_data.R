# 02_clean_data.R — Link IRS 990 and SBA PPP data, construct variables
# PPP Nonprofit Employment RDD (apep_0698)

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load IRS Exempt Org Business Master File (name/address crosswalk)
# ============================================================
cat("=== Loading IRS BMF (name/address crosswalk) ===\n")

bmf_file <- file.path(data_dir, "eo_bmf.csv")
if (!file.exists(bmf_file) || file.size(bmf_file) < 1e6) {
  cat("  Downloading BMF by region...\n")
  bmf_parts <- list()
  for (i in 1:4) {
    url <- paste0("https://www.irs.gov/pub/irs-soi/eo", i, ".csv")
    tmp <- file.path(data_dir, paste0("eo", i, ".csv"))
    cat("    Region", i, "...")
    tryCatch({
      download.file(url, tmp, mode = "wb", quiet = TRUE)
      cat("OK (", round(file.size(tmp)/1e6, 1), "MB)\n")
      bmf_parts[[i]] <- fread(tmp)
    }, error = function(e) cat("FAILED\n"))
  }
  bmf <- rbindlist(bmf_parts, fill = TRUE)
  fwrite(bmf, bmf_file)
  cat("  Combined BMF:", nrow(bmf), "records\n")
  # Clean up parts
  for (i in 1:4) unlink(file.path(data_dir, paste0("eo", i, ".csv")))
} else {
  bmf <- fread(bmf_file)
  cat("  Loaded BMF:", nrow(bmf), "records\n")
}

cat("BMF columns:", paste(names(bmf), collapse = ", "), "\n")

# Standardize BMF columns
setnames(bmf, tolower(names(bmf)))
cat("BMF has", nrow(bmf), "organizations\n")

# Key columns: ein, name, city, state, zip, ntee_cd, subsection
# Standardize for matching
bmf[, ein := as.character(ein)]
bmf[, ein := str_pad(ein, 9, pad = "0")]
bmf[, name_std := toupper(trimws(name))]
bmf[, name_std := gsub("[^A-Z0-9 ]", "", name_std)]
bmf[, zip5 := substr(as.character(zip), 1, 5)]

# ============================================================
# 2. Load IRS SOI 990 Financial Data
# ============================================================
cat("\n=== Loading IRS SOI 990 data ===\n")

load_990 <- function(year) {
  f <- file.path(data_dir, paste0("soi990_", year, ".csv"))
  cat("  Loading", year, "...")

  # Read header to find matching columns
  header <- names(fread(f, nrows = 0))
  keep_patterns <- c("^ein$", "^tax_pd$", "^subseccd$", "^elf$",
                      "noemplyeesw3cnt", "totrevenue", "totfuncexpns",
                      "totcntrbgfts", "progrevnue", "grsinc509",
                      "totassetsend", "netassetsend")
  keep <- header[sapply(header, function(h) any(grepl(paste(keep_patterns, collapse = "|"), h, ignore.case = TRUE)))]
  dt <- fread(f, select = keep)
  setnames(dt, tolower(names(dt)))
  dt[, filing_year := year]
  cat(" rows:", nrow(dt), "\n")
  return(dt)
}

soi_list <- lapply(2018:2023, load_990)
soi <- rbindlist(soi_list, fill = TRUE)
soi[, ein := as.character(ein)]
soi[, ein := str_pad(ein, 9, pad = "0")]

cat("Total 990 records:", format(nrow(soi), big.mark = ","), "\n")
cat("Unique EINs in 990:", format(length(unique(soi$ein)), big.mark = ","), "\n")

# Convert numeric fields
num_cols <- c("noemplyeesw3cnt", "totrevenue", "totfuncexpns",
              "totcntrbgfts", "progrevnue", "totassetsend", "netassetsend")
for (col in intersect(num_cols, names(soi))) {
  soi[, (col) := as.numeric(get(col))]
}

# ============================================================
# 3. Load SBA PPP Data (Nonprofits Only)
# ============================================================
cat("\n=== Loading SBA PPP data (nonprofits only) ===\n")

load_ppp <- function(f) {
  cat("  Loading", basename(f), "...")
  cols_want <- c("BorrowerName", "BorrowerCity",
                 "BorrowerState", "BorrowerZip",
                 "CurrentApprovalAmount", "ProcessingMethod",
                 "BusinessType", "NAICSCode",
                 "ForgivenessAmount", "LoanStatus",
                 "JobsReported", "DateApproved")
  header <- names(fread(f, nrows = 0))
  cols_use <- intersect(cols_want, header)
  dt <- fread(f, select = cols_use)

  # Filter to nonprofits
  dt <- dt[grepl("Non-Profit|501\\(c\\)|Tribal", BusinessType, ignore.case = TRUE)]
  cat(" nonprofits:", format(nrow(dt), big.mark = ","), "\n")
  return(dt)
}

ppp_files <- list.files(data_dir, pattern = "^ppp_", full.names = TRUE)
ppp_list <- lapply(ppp_files, load_ppp)
ppp <- rbindlist(ppp_list, fill = TRUE)

cat("Total nonprofit PPP loans:", format(nrow(ppp), big.mark = ","), "\n")

# Standardize PPP names
ppp[, name_std := toupper(trimws(BorrowerName))]
ppp[, name_std := gsub("[^A-Z0-9 ]", "", name_std)]
ppp[, zip5 := substr(as.character(BorrowerZip), 1, 5)]
ppp[, state := toupper(trimws(BorrowerState))]
ppp[, second_draw := as.integer(ProcessingMethod == "PPS")]

cat("First Draw:", sum(ppp$second_draw == 0), "\n")
cat("Second Draw:", sum(ppp$second_draw == 1), "\n")

# ============================================================
# 4. Match PPP → BMF → 990
# ============================================================
cat("\n=== Matching PPP to BMF (name + zip) ===\n")

# Step 1: Match PPP records to BMF by name + zip5 to get EINs
ppp_for_match <- unique(ppp[, .(name_std, zip5, state)])

# Exact name + zip match
m1 <- merge(ppp_for_match, bmf[, .(ein, name_std, zip5)],
            by = c("name_std", "zip5"), all.x = TRUE, allow.cartesian = TRUE)

# Remove duplicates: keep one EIN per name+zip
m1 <- m1[!is.na(ein)][!duplicated(paste0(name_std, "_", zip5))]
cat("  Name+ZIP matches:", format(nrow(m1), big.mark = ","), "\n")

# For unmatched, try name + state
unmatched_keys <- ppp_for_match[!paste0(name_std, "_", zip5) %in%
                                   paste0(m1$name_std, "_", m1$zip5)]
m2 <- merge(unmatched_keys, bmf[, .(ein, name_std, state)],
            by = c("name_std", "state"), all.x = TRUE, allow.cartesian = TRUE)
m2 <- m2[!is.na(ein)][!duplicated(paste0(name_std, "_", state))]
cat("  Name+State matches:", format(nrow(m2), big.mark = ","), "\n")

# Combine: name+zip takes priority
ppp_ein <- rbind(m1[, .(name_std, zip5, ein)],
                 m2[, .(name_std, zip5, ein)])
ppp_ein <- ppp_ein[!duplicated(paste0(name_std, "_", zip5))]
cat("  Total matched PPP borrowers:", format(nrow(ppp_ein), big.mark = ","),
    "out of", format(nrow(ppp_for_match), big.mark = ","),
    "(", round(100 * nrow(ppp_ein) / nrow(ppp_for_match), 1), "%)\n")

# Merge EINs back to full PPP data
ppp <- merge(ppp, ppp_ein, by = c("name_std", "zip5"), all.x = TRUE)

# Aggregate PPP at EIN level
ppp_by_ein <- ppp[!is.na(ein), .(
  ppp_any = 1L,
  ppp_first_draw = as.integer(any(second_draw == 0)),
  ppp_second_draw = as.integer(any(second_draw == 1)),
  ppp_total_amount = sum(CurrentApprovalAmount, na.rm = TRUE),
  ppp_forgiven = sum(ForgivenessAmount, na.rm = TRUE),
  ppp_jobs_reported = max(JobsReported, na.rm = TRUE),
  n_ppp_loans = .N
), by = ein]

cat("\nPPP by EIN:\n")
cat("  EINs with any PPP:", format(nrow(ppp_by_ein), big.mark = ","), "\n")
cat("  With Second Draw:", format(sum(ppp_by_ein$ppp_second_draw == 1), big.mark = ","), "\n")

# ============================================================
# 5. Build Analysis Panel
# ============================================================
cat("\n=== Building analysis panel ===\n")

# Add BMF info (name, state, zip, NTEE) to 990 data
bmf_info <- unique(bmf[, .(ein, name_std, state, zip5, city,
                            ntee_cd = if ("ntee_cd" %in% names(bmf)) get("ntee_cd") else NA_character_)])
soi <- merge(soi, bmf_info, by = "ein", all.x = TRUE)

# Merge PPP status
panel <- merge(soi, ppp_by_ein, by = "ein", all.x = TRUE)

# Fill NA PPP fields with 0
ppp_cols <- c("ppp_any", "ppp_first_draw", "ppp_second_draw",
              "ppp_total_amount", "ppp_forgiven", "ppp_jobs_reported", "n_ppp_loans")
for (col in ppp_cols) {
  if (col %in% names(panel)) panel[is.na(get(col)), (col) := 0]
}

# ============================================================
# 6. Construct Running Variable & Outcomes
# ============================================================
cat("=== Constructing running variable ===\n")

# Revenue decline: (rev_2020 - rev_2019) / |rev_2019|
rev_2019 <- panel[filing_year == 2019, .(ein, rev_2019 = totrevenue)]
rev_2020 <- panel[filing_year == 2020, .(ein, rev_2020 = totrevenue)]
rev_change <- merge(rev_2019, rev_2020, by = "ein")
rev_change <- rev_change[abs(rev_2019) > 10000]  # Require >$10K baseline revenue
rev_change[, rev_decline_pct := (rev_2020 - rev_2019) / abs(rev_2019) * 100]

# Winsorize extremes
rev_change[rev_decline_pct < -100, rev_decline_pct := -100]
rev_change[rev_decline_pct > 200, rev_decline_pct := 200]

cat("Revenue decline distribution:\n")
cat("  N:", nrow(rev_change), "\n")
cat("  Mean:", round(mean(rev_change$rev_decline_pct), 1), "%\n")
cat("  Median:", round(median(rev_change$rev_decline_pct), 1), "%\n")
cat("  SD:", round(sd(rev_change$rev_decline_pct), 1), "%\n")
cat("  Below -25%:", sum(rev_change$rev_decline_pct < -25), "\n")

# Merge running variable
panel <- merge(panel, rev_change[, .(ein, rev_decline_pct, rev_2019 = rev_2019, rev_2020 = rev_2020)],
               by = "ein", all.x = TRUE)

# ============================================================
# 7. Create Analysis Sample
# ============================================================
cat("\n=== Creating analysis sample ===\n")

# Require:
# 1. Filed in both 2019 and 2020
# 2. Positive employment in 2019
# 3. Valid running variable
eins_valid <- panel[filing_year == 2019 &
                      !is.na(noemplyeesw3cnt) & noemplyeesw3cnt > 0 &
                      !is.na(rev_decline_pct), ein]

analysis <- panel[ein %in% eins_valid]

cat("Analysis panel:\n")
cat("  Organizations:", format(length(unique(analysis$ein)), big.mark = ","), "\n")
cat("  Org-years:", format(nrow(analysis), big.mark = ","), "\n")
cat("  PPP recipients:", sum(analysis[filing_year == 2019]$ppp_any == 1), "\n")
cat("  Second Draw:", sum(analysis[filing_year == 2019]$ppp_second_draw == 1), "\n")

# Create cross-sectional RDD sample
rdd <- analysis[filing_year == 2019, .(
  ein, name_std, state, zip5,
  rev_decline_pct,
  ppp_any, ppp_first_draw, ppp_second_draw,
  ppp_total_amount, ppp_forgiven,
  emp_2019 = noemplyeesw3cnt,
  rev_base = totrevenue,
  exp_base = totfuncexpns,
  contrib_base = totcntrbgfts,
  assets_base = totassetsend
)]

# Add post-treatment outcomes (deduplicate: one row per EIN per year)
for (yr in 2020:2023) {
  yr_data <- analysis[filing_year == yr, .(
    emp = mean(noemplyeesw3cnt, na.rm = TRUE),
    rev = mean(totrevenue, na.rm = TRUE),
    exp = mean(totfuncexpns, na.rm = TRUE),
    contrib = mean(totcntrbgfts, na.rm = TRUE)
  ), by = ein]
  setnames(yr_data, c("emp", "rev", "exp", "contrib"),
           paste0(c("emp_", "rev_", "exp_", "contrib_"), yr))
  rdd <- merge(rdd, yr_data, by = "ein", all.x = TRUE)
}

# Outcome variables
rdd[, log_emp_2019 := log(emp_2019 + 1)]
for (yr in 2020:2023) {
  emp_col <- paste0("emp_", yr)
  if (emp_col %in% names(rdd)) {
    rdd[, paste0("log_emp_", yr) := log(get(emp_col) + 1)]
    rdd[, paste0("emp_change_", yr) := get(emp_col) - emp_2019]
    rdd[, paste0("emp_growth_", yr) := (get(emp_col) - emp_2019) / emp_2019]
  }
}

# Size categories
rdd[, size_cat := fcase(
  emp_2019 <= 10, "Micro (1-10)",
  emp_2019 <= 50, "Small (11-50)",
  emp_2019 <= 250, "Medium (51-250)",
  default = "Large (251+)"
)]

# NTEE broad category
if ("ntee_cd" %in% names(rdd)) {
  rdd[, ntee_broad := substr(ntee_cd, 1, 1)]
}

# Save
fwrite(analysis, file.path(data_dir, "analysis_panel.csv"))
fwrite(rdd, file.path(data_dir, "rdd_sample.csv"))

cat("\nFinal RDD sample:", format(nrow(rdd), big.mark = ","), "organizations\n")
cat("  With 2021 employment:", sum(!is.na(rdd$emp_2021)), "\n")
cat("  With 2022 employment:", sum(!is.na(rdd$emp_2022)), "\n")
cat("  With 2023 employment:", sum(!is.na(rdd$emp_2023)), "\n")

cat("\n=== Data cleaning complete ===\n")
