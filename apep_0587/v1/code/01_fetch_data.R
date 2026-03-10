## =============================================================================
## 01_fetch_data.R — Fetch all data from HMRC and NOMIS
## APEP-0587: Bunching at the UK High Income Child Benefit Charge Notch
## =============================================================================
source("00_packages.R")

data_dir <- "../data"
hmrc_dir <- file.path(data_dir, "hmrc")
dir.create(hmrc_dir, recursive = TRUE, showWarnings = FALSE)

## ---- 1. HMRC Table 3.1a: Percentile points 1-99 for total income -----------
## Covers all UK income taxpayers, tax years 1999/2000 to 2022/23
## Source: Survey of Personal Incomes (SPI)

url_3_1a <- "https://assets.publishing.service.gov.uk/media/67cab9a65993d41513a45bee/Table_3.1a_2223.ods"
dest_3_1a <- file.path(hmrc_dir, "Table_3_1a_percentiles.ods")
if (!file.exists(dest_3_1a)) {
  download.file(url_3_1a, dest_3_1a, mode = "wb")
}
stopifnot("Table 3.1a download failed" = file.exists(dest_3_1a) && file.size(dest_3_1a) > 5000)
cat("HMRC Table 3.1a downloaded:", file.size(dest_3_1a), "bytes\n")

## ---- 2. HMRC Tables 3.1-3.17: Income distribution by range -----------------
url_3_all <- "https://assets.publishing.service.gov.uk/media/67cabb37ade26736dbf9ffe5/Collated_Tables_3_1_to_3_17_2223.ods"
dest_3_all <- file.path(hmrc_dir, "Tables_3_1_to_3_17.ods")
if (!file.exists(dest_3_all)) {
  download.file(url_3_all, dest_3_all, mode = "wb")
}
stopifnot("Tables 3.1-3.17 download failed" = file.exists(dest_3_all) && file.size(dest_3_all) > 50000)
cat("HMRC Tables 3.1-3.17 downloaded:", file.size(dest_3_all), "bytes\n")

## ---- 3. NOMIS ASHE: Annual earnings percentiles for PAYE employees ----------
## NM_99_1 (workplace analysis), annual gross pay, UK, full-time
## Percentiles: 10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90
## Years: 2002-2024 (2024 is latest available)

nomis_key <- Sys.getenv("NOMIS_API_KEY")
nomis_auth <- if (nchar(nomis_key) > 0) paste0("&uid=", nomis_key) else ""

# item codes: 2=median, 6=P10, 7=P20, 8=P25, 9=P30, 10=P40, 11=P60, 12=P70, 13=P75, 14=P80, 15=P90, 1=number
items <- "1,2,6,7,8,9,10,11,12,13,14,15"
# pay=7 is annual gross pay; sex=8 is all (full-time)
# geography=2092957697 is UK
years <- paste(2002:2025, collapse = ",")

ashe_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_99_1.data.json",
  "?geography=2092957697",
  "&sex=8",         # Full time workers
  "&item=", items,
  "&pay=7",         # Annual gross pay
  "&date=", years,
  "&measures=20100",
  nomis_auth
)

cat("Fetching ASHE data from NOMIS...\n")
resp <- request(ashe_url) |> req_perform()
ashe_json <- resp_body_json(resp)

# Parse ASHE JSON
ashe_rows <- ashe_json$obs
ashe_dt <- rbindlist(lapply(ashe_rows, function(x) {
  data.table(
    year      = as.integer(x$time$value),
    item_code = as.integer(x$item$value),
    item_desc = x$item$description,
    value     = as.numeric(x$obs_value$value)
  )
}))

stopifnot("ASHE data empty" = nrow(ashe_dt) > 50)
cat("ASHE data:", nrow(ashe_dt), "rows,", uniqueN(ashe_dt$year), "years\n")

# Also fetch ASHE for part-time workers (sex=9) for comparison
ashe_pt_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_99_1.data.json",
  "?geography=2092957697",
  "&sex=9",         # Part time workers
  "&item=", items,
  "&pay=7",
  "&date=", years,
  "&measures=20100",
  nomis_auth
)
resp_pt <- request(ashe_pt_url) |> req_perform()
ashe_pt_json <- resp_body_json(resp_pt)
ashe_pt_dt <- rbindlist(lapply(ashe_pt_json$obs, function(x) {
  data.table(
    year      = as.integer(x$time$value),
    item_code = as.integer(x$item$value),
    item_desc = x$item$description,
    value     = as.numeric(x$obs_value$value)
  )
}))
cat("ASHE part-time data:", nrow(ashe_pt_dt), "rows\n")

## ---- 4. NOMIS ASHE: Male vs Female full-time (for gender decomposition) -----
ashe_male_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_99_1.data.json",
  "?geography=2092957697&sex=5&item=", items, "&pay=7&date=", years,
  "&measures=20100", nomis_auth
)
ashe_female_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_99_1.data.json",
  "?geography=2092957697&sex=6&item=", items, "&pay=7&date=", years,
  "&measures=20100", nomis_auth
)

resp_m <- request(ashe_male_url) |> req_perform()
ashe_m_dt <- rbindlist(lapply(resp_body_json(resp_m)$obs, function(x) {
  data.table(year = as.integer(x$time$value), item_code = as.integer(x$item$value),
             item_desc = x$item$description, value = as.numeric(x$obs_value$value))
}))

resp_f <- request(ashe_female_url) |> req_perform()
ashe_f_dt <- rbindlist(lapply(resp_body_json(resp_f)$obs, function(x) {
  data.table(year = as.integer(x$time$value), item_code = as.integer(x$item$value),
             item_desc = x$item$description, value = as.numeric(x$obs_value$value))
}))

cat("ASHE male:", nrow(ashe_m_dt), "rows; female:", nrow(ashe_f_dt), "rows\n")

## ---- 5. HMRC Child Benefit / HICBC administrative statistics ----------------
## These are published as HTML tables. We code the key series manually from
## official GOV.UK publications to ensure accuracy.
## Source: Child Benefit Statistics Annual Release (August 2024)
## https://www.gov.uk/government/statistics/child-benefit-statistics-annual-release-august-2024

cb_admin <- data.table(
  year = 2013:2024,
  # Families opted out of CB payments (thousands)
  # Source: GOV.UK Child Benefit Statistics annual releases 2014-2024
  families_opted_out_k = c(43, 380, 451, 512, 555, 584, 614, 629, 690, 735, 740, 712),
  # HICBC liable individuals (thousands) — from HMRC HICBC statistics
  hicbc_liable_k = c(NA, NA, NA, NA, NA, 293, 352, 373, 393, 440, NA, NA),
  # HICBC total revenue (£millions)
  hicbc_revenue_m = c(NA, NA, NA, NA, NA, 416, 468, 395, 470, 525, NA, NA),
  # Child Benefit take-up rate (%)
  cb_takeup_pct = c(97, 94, 93, 92, 91, 91, 90, 90, 89, 88, 88, NA)
)

## ---- 6. HICBC policy parameters (for formal analysis) -----------------------
hicbc_params <- data.table(
  period = c("pre-2013", "2013-2024 (Jan)", "2024-present (Apr)"),
  threshold_lower = c(NA, 50000, 60000),
  threshold_upper = c(NA, 60000, 80000),
  taper_rate = c(NA, 0.01, 0.005),  # charge per £100 over threshold
  max_cb_2children = c(NA, 1752, 2077),  # annual CB for eldest + 1 additional
  notch_type = c("none", "sharp notch at £50k (100% clawback over £50-60k)",
                 "softer taper at £60k (50% clawback over £60-80k)")
)

## ---- Save all data ----------------------------------------------------------
fwrite(ashe_dt, file.path(data_dir, "ashe_ft_all.csv"))
fwrite(ashe_pt_dt, file.path(data_dir, "ashe_pt_all.csv"))
fwrite(ashe_m_dt, file.path(data_dir, "ashe_ft_male.csv"))
fwrite(ashe_f_dt, file.path(data_dir, "ashe_ft_female.csv"))
fwrite(cb_admin, file.path(data_dir, "cb_admin.csv"))
fwrite(hicbc_params, file.path(data_dir, "hicbc_params.csv"))

cat("\n=== DATA VALIDATION ===\n")
stopifnot("ASHE must span 2002-2024" = all(2002:2024 %in% ashe_dt$year))
stopifnot("ASHE must have all percentile items" = length(unique(ashe_dt$item_code)) >= 10)
stopifnot("CB admin must cover 2013-2024" = all(2013:2024 %in% cb_admin$year))
cat("Data validation passed.\n")
cat("ASHE years:", range(ashe_dt$year), "\n")
cat("ASHE items:", sort(unique(ashe_dt$item_code)), "\n")
cat("CB admin years:", range(cb_admin$year), "\n")
cat("All data saved to", data_dir, "\n")
