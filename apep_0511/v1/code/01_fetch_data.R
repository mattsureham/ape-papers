## ============================================================================
## 01_fetch_data.R — Fetch all data for 340B × Medicaid RDD
## ============================================================================

source("00_packages.R")

SHARED_DATA <- file.path("..", "..", "..", "..", "data", "medicaid_provider_spending")
DATA <- "../data"
dir.create(DATA, showWarnings = FALSE, recursive = TRUE)

## ============================================================================
## 1. T-MSIS: Medicaid billing by NPI × year
## ============================================================================

cat("\n=== 1. T-MSIS ===\n")
tmsis_path <- file.path(SHARED_DATA, "tmsis.parquet")
stopifnot("T-MSIS not found" = file.exists(tmsis_path))
tmsis_ds <- open_dataset(tmsis_path)

# J-code (drug) billing
cat("J-code billing...\n")
medicaid_drugs <- tmsis_ds |>
  filter(substr(HCPCS_CODE, 1, 1) == "J") |>
  mutate(year = as.integer(substr(CLAIM_FROM_MONTH, 1, 4))) |>
  group_by(BILLING_PROVIDER_NPI_NUM, year) |>
  summarize(mcaid_drug_paid = sum(TOTAL_PAID, na.rm = TRUE),
            mcaid_drug_claims = sum(TOTAL_CLAIMS, na.rm = TRUE),
            mcaid_drug_benes = sum(TOTAL_UNIQUE_BENEFICIARIES, na.rm = TRUE),
            mcaid_drug_codes = n_distinct(HCPCS_CODE), .groups = "drop") |>
  collect() |> as.data.table()
setnames(medicaid_drugs, "BILLING_PROVIDER_NPI_NUM", "npi")
cat(sprintf("  %s NPI-years, %s NPIs\n", format(nrow(medicaid_drugs), big.mark=","),
            format(uniqueN(medicaid_drugs$npi), big.mark=",")))

# Non-drug billing (placebo)
cat("Non-drug billing (placebo)...\n")
medicaid_nondrug <- tmsis_ds |>
  filter(substr(HCPCS_CODE, 1, 1) != "J") |>
  mutate(year = as.integer(substr(CLAIM_FROM_MONTH, 1, 4))) |>
  group_by(BILLING_PROVIDER_NPI_NUM, year) |>
  summarize(mcaid_nondrug_paid = sum(TOTAL_PAID, na.rm = TRUE),
            mcaid_nondrug_claims = sum(TOTAL_CLAIMS, na.rm = TRUE), .groups = "drop") |>
  collect() |> as.data.table()
setnames(medicaid_nondrug, "BILLING_PROVIDER_NPI_NUM", "npi")

# HCBS billing (T/H/S codes — second placebo)
cat("HCBS billing (placebo)...\n")
medicaid_hcbs <- tmsis_ds |>
  filter(substr(HCPCS_CODE, 1, 1) %in% c("T", "H", "S")) |>
  mutate(year = as.integer(substr(CLAIM_FROM_MONTH, 1, 4))) |>
  group_by(BILLING_PROVIDER_NPI_NUM, year) |>
  summarize(mcaid_hcbs_paid = sum(TOTAL_PAID, na.rm = TRUE),
            mcaid_hcbs_claims = sum(TOTAL_CLAIMS, na.rm = TRUE), .groups = "drop") |>
  collect() |> as.data.table()
setnames(medicaid_hcbs, "BILLING_PROVIDER_NPI_NUM", "npi")

## ============================================================================
## 2. CMS HCRIS: Hospital DSH adjustment percentages
## ============================================================================

cat("\n=== 2. HCRIS ===\n")
hcris_dir <- file.path(DATA, "hcris")
dir.create(hcris_dir, showWarnings = FALSE)

hcris_years <- 2019:2023
all_hcris <- list()

for (yr in hcris_years) {
  zip_file <- file.path(hcris_dir, sprintf("hosp10FY%d.zip", yr))
  if (!file.exists(zip_file)) {
    url <- sprintf("https://downloads.cms.gov/files/hcris/hosp10FY%d.zip", yr)
    cat(sprintf("Downloading HCRIS FY%d...\n", yr))
    tryCatch(download.file(url, zip_file, mode = "wb", quiet = TRUE),
             error = function(e) stop("HCRIS FY", yr, " download failed: ", e$message))
  }

  zip_contents <- unzip(zip_file, list = TRUE)$Name
  rpt_file <- zip_contents[grepl("rpt\\.csv$", zip_contents, ignore.case = TRUE)]
  nmrc_file <- zip_contents[grepl("nmrc\\.csv$", zip_contents, ignore.case = TRUE)]
  tmp <- tempdir()
  unzip(zip_file, files = c(rpt_file, nmrc_file), exdir = tmp, overwrite = TRUE)

  # Report-level data
  rpt <- fread(file.path(tmp, rpt_file), header = FALSE,
               select = c(1, 3, 6, 7),
               col.names = c("rpt_rec_num", "prvdr_num", "fy_bgn_dt", "fy_end_dt"))
  # Preserve leading zeros in 6-digit CCN
  rpt[, prvdr_num := sprintf("%06d", as.integer(prvdr_num))]
  rpt[, fy_bgn_dt := as.Date(fy_bgn_dt, format = "%m/%d/%Y")]
  rpt[, fy_end_dt := as.Date(fy_end_dt, format = "%m/%d/%Y")]
  rpt[, fiscal_year := as.integer(format(fy_end_dt, "%Y"))]

  # Numeric data — extract DSH fields from Worksheet E Part A
  nmrc <- fread(file.path(tmp, nmrc_file), header = FALSE,
                col.names = c("rpt_rec_num", "wksht_cd", "line_num", "clmn_num", "itm_val_num"))

  e_data <- nmrc[wksht_cd == "E00A18A" & clmn_num == "00100"]

  # Line 3000 = SSI ratio, Line 3100 = Medicaid ratio, Line 3200 = DSH patient %
  ssi <- e_data[line_num == 3000, .(rpt_rec_num, ssi_ratio = itm_val_num)]
  mcaid <- e_data[line_num == 3100, .(rpt_rec_num, medicaid_ratio = itm_val_num)]
  dsh_pct <- e_data[line_num == 3200, .(rpt_rec_num, dsh_pct = itm_val_num)]

  # Beds from Worksheet S-2
  s2 <- nmrc[wksht_cd == "S200001" & line_num == 200 & clmn_num == "00200",
             .(rpt_rec_num, total_beds = itm_val_num)]

  # Total days from S-3 (for reference)
  hosp <- merge(rpt[, .(rpt_rec_num, prvdr_num, fiscal_year)],
                dsh_pct, by = "rpt_rec_num", all.x = TRUE)
  hosp <- merge(hosp, ssi, by = "rpt_rec_num", all.x = TRUE)
  hosp <- merge(hosp, mcaid, by = "rpt_rec_num", all.x = TRUE)
  hosp <- merge(hosp, s2, by = "rpt_rec_num", all.x = TRUE)

  # If DSH % missing, compute from SSI + Medicaid
  hosp[is.na(dsh_pct) & !is.na(ssi_ratio) & !is.na(medicaid_ratio),
       dsh_pct := ssi_ratio + medicaid_ratio]

  n_dsh <- sum(!is.na(hosp$dsh_pct))
  cat(sprintf("  FY%d: %d hospitals, %d with DSH%%\n", yr, nrow(hosp), n_dsh))

  all_hcris[[as.character(yr)]] <- hosp
  file.remove(file.path(tmp, rpt_file), file.path(tmp, nmrc_file))
}

hcris_panel <- rbindlist(all_hcris, fill = TRUE)
cat(sprintf("HCRIS total: %d hospital-years, %d with DSH%%\n",
            nrow(hcris_panel), sum(!is.na(hcris_panel$dsh_pct))))

## ============================================================================
## 3. Medicare PUF: Drug billing via CMS API (paginated, J-codes only)
## ============================================================================

cat("\n=== 3. Medicare PUF (drugs) ===\n")
medicare_file <- file.path(DATA, "medicare_drugs.rds")

if (!file.exists(medicare_file)) {
  # Use CMS data API with drug indicator filter
  base_url <- "https://data.cms.gov/data-api/v1/dataset/92396110-2aed-4d63-a6a2-5d6207d46a29/data"

  all_records <- list()
  offset <- 0
  batch_size <- 5000
  keep_going <- TRUE

  cat("Fetching Medicare drug records via CMS API...\n")
  while (keep_going) {
    url <- sprintf("%s?filter[HCPCS_Drug_Ind]=Y&size=%d&offset=%d",
                   base_url, batch_size, offset)
    resp <- tryCatch(httr::GET(url, httr::timeout(120)), error = function(e) NULL)

    if (is.null(resp) || httr::status_code(resp) != 200) {
      if (offset == 0) stop("Medicare PUF API failed on first request. Status: ",
                             if(!is.null(resp)) httr::status_code(resp) else "error")
      keep_going <- FALSE
      next
    }

    batch <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
    if (is.null(batch) || nrow(batch) == 0) {
      keep_going <- FALSE
    } else {
      all_records[[length(all_records) + 1]] <- as.data.table(batch)
      offset <- offset + batch_size
      if (nrow(batch) < batch_size) keep_going <- FALSE
      if (offset %% 50000 == 0) cat(sprintf("  %s records fetched...\n",
                                              format(offset, big.mark = ",")))
    }
  }

  medicare_drugs_raw <- rbindlist(all_records, fill = TRUE)
  cat(sprintf("Medicare drug records: %s total\n", format(nrow(medicare_drugs_raw), big.mark = ",")))

  # Filter to J-codes specifically (HCPCS_Drug_Ind=Y includes vaccines too)
  medicare_drugs_raw[, is_jcode := grepl("^J", HCPCS_Cd)]

  # Aggregate to NPI level
  medicare_drugs <- medicare_drugs_raw[, .(
    mcare_drug_paid = sum(as.numeric(Avg_Mdcr_Pymt_Amt) * as.numeric(Tot_Srvcs), na.rm = TRUE),
    mcare_drug_srvcs = sum(as.numeric(Tot_Srvcs), na.rm = TRUE),
    mcare_drug_benes = sum(as.numeric(Tot_Benes), na.rm = TRUE),
    mcare_drug_codes = uniqueN(HCPCS_Cd),
    mcare_jcode_paid = sum(as.numeric(Avg_Mdcr_Pymt_Amt) * as.numeric(Tot_Srvcs) * is_jcode, na.rm = TRUE),
    mcare_jcode_srvcs = sum(as.numeric(Tot_Srvcs) * is_jcode, na.rm = TRUE)
  ), by = .(npi = Rndrng_NPI)]

  cat(sprintf("Medicare drug NPI summary: %s providers\n",
              format(nrow(medicare_drugs), big.mark = ",")))

  saveRDS(medicare_drugs, medicare_file)
  saveRDS(medicare_drugs_raw, file.path(DATA, "medicare_drugs_raw.rds"))
} else {
  cat("Loading cached Medicare drug data...\n")
  medicare_drugs <- readRDS(medicare_file)
}

## ============================================================================
## 4. NPPES: Provider geography and entity type
## ============================================================================

cat("\n=== 4. NPPES ===\n")
nppes_path <- file.path(SHARED_DATA, "nppes_extract.parquet")

if (file.exists(nppes_path)) {
  nppes <- as.data.table(read_parquet(nppes_path))
} else {
  nppes_csv <- list.files(SHARED_DATA, pattern = "npidata_pfile.*\\.csv$", full.names = TRUE)
  nppes_csv <- nppes_csv[!grepl("header", nppes_csv)]
  if (length(nppes_csv) == 0) stop("No NPPES data found in ", SHARED_DATA)
  nppes <- fread(nppes_csv[1], select = c(
    "NPI", "Entity Type Code",
    "Provider Organization Name (Legal Business Name)",
    "Provider Business Practice Location Address State Name",
    "Provider Business Practice Location Address Postal Code",
    "Healthcare Provider Taxonomy Code_1",
    "Provider Enumeration Date", "NPI Deactivation Date"
  ), showProgress = TRUE, nThread = 4)
  setnames(nppes, c("npi", "entity_type", "org_name", "state", "zip",
                     "taxonomy_1", "enumeration_date", "deactivation_date"))
  nppes[, zip5 := substr(gsub("[^0-9]", "", zip), 1, 5)]
  write_parquet(nppes, nppes_path)
}
nppes[, npi := as.character(npi)]
cat(sprintf("NPPES: %s providers\n", format(nrow(nppes), big.mark = ",")))

## ============================================================================
## 5. Validation
## ============================================================================

cat("\n=== VALIDATION ===\n")
stopifnot("Medicaid drugs loaded" = nrow(medicaid_drugs) > 0)
stopifnot("Medicaid drugs span years" = uniqueN(medicaid_drugs$year) >= 5)
stopifnot("HCRIS has DSH data" = sum(!is.na(hcris_panel$dsh_pct)) > 500)
stopifnot("Medicare drugs loaded" = nrow(medicare_drugs) > 0)
stopifnot("NPPES loaded" = nrow(nppes) > 100000)

cat(sprintf("T-MSIS drugs: %s NPI-years\n", format(nrow(medicaid_drugs), big.mark = ",")))
cat(sprintf("HCRIS: %d hospital-years with DSH%%\n", sum(!is.na(hcris_panel$dsh_pct))))
cat(sprintf("Medicare drugs: %s NPIs\n", format(nrow(medicare_drugs), big.mark = ",")))
cat(sprintf("NPPES: %s providers\n", format(nrow(nppes), big.mark = ",")))

## ============================================================================
## 6. Save
## ============================================================================

saveRDS(medicaid_drugs, file.path(DATA, "medicaid_drugs.rds"))
saveRDS(medicaid_nondrug, file.path(DATA, "medicaid_nondrug.rds"))
saveRDS(medicaid_hcbs, file.path(DATA, "medicaid_hcbs.rds"))
saveRDS(hcris_panel, file.path(DATA, "hcris_panel.rds"))

cat("\n=== Data fetch complete ===\n")
