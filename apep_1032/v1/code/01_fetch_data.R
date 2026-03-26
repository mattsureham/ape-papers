## 01_fetch_data.R — Fetch FDIC Call Report data via BankFind API
## APEP-1032: The Deterrence Gap

source("00_packages.R")

# ── FDIC BankFind Suite API ──────────────────────────────────────────────────
# Documentation: https://banks.data.fdic.gov/docs/
# No API key required. Endpoint: /api/financials
# We need quarterly financials for banks with assets $500M–$10B, 2014Q1–2023Q4

BASE_URL <- "https://banks.data.fdic.gov/api/financials"

# Fields to fetch
fields <- paste(
  "CERT", "REPDTE", "REPNM", "ASSET", "DEP", "LNLSGR",
  "NCLNLS", "NTLNLS", "ROA", "ROAPTX", "IDT1CER", "RBCT1J",
  "LNCI", "LNCON", "LNRE", "LNAG", "NUMEMP", "SC",
  "EINTEXP", "ELNATR", "NITEFEE",
  sep = ","
)

# Query dates (quarters from 2014Q1 to 2023Q4)
quarters <- c()
for (yr in 2014:2023) {
  for (q in c("0331", "0630", "0930", "1231")) {
    quarters <- c(quarters, paste0(yr, q))
  }
}

cat("Fetching FDIC data for", length(quarters), "quarters...\n")

# Fetch in chunks by quarter to stay within API limits
all_data <- list()

for (i in seq_along(quarters)) {
  qtr <- quarters[i]

  # Filter: assets between $500M and $10B (in thousands: 500000 to 10000000)
  filters <- paste0(
    'REPDTE:', qtr,
    ' AND ASSET:[500000 TO 10000000]'
  )

  url <- paste0(
    BASE_URL,
    "?filters=", URLencode(filters),
    "&fields=", fields,
    "&limit=10000",
    "&sort_by=ASSET",
    "&sort_order=ASC"
  )

  resp <- GET(url)

  if (status_code(resp) != 200) {
    stop("FDIC API returned HTTP ", status_code(resp), " for quarter ", qtr)
  }

  json <- content(resp, as = "parsed", simplifyVector = TRUE)

  if (is.null(json$data) || length(json$data) == 0) {
    warning("No data returned for quarter ", qtr, " — skipping")
    next
  }

  df_qtr <- as.data.frame(json$data)
  cat(sprintf("  %s: %d banks\n", qtr, nrow(df_qtr)))
  all_data[[qtr]] <- df_qtr

  # Respect rate limits
  Sys.sleep(0.3)
}

cat("Combining data...\n")
raw <- bind_rows(all_data)

# Verify we have data
stopifnot("No data fetched from FDIC API" = nrow(raw) > 0)
cat("Raw data:", nrow(raw), "bank-quarters\n")

# ── Clean column names ───────────────────────────────────────────────────────
# The API nests data columns; flatten if needed
if ("data" %in% names(raw)) {
  raw <- as.data.frame(raw$data)
}

# Convert to numeric
num_cols <- c("ASSET", "DEP", "LNLSGR", "NCLNLS", "NTLNLS", "ROA", "ROAPTX",
              "IDT1CER", "RBCT1J", "LNCI", "LNCON", "LNRE", "LNAG", "NUMEMP",
              "SC", "EINTEXP", "ELNATR", "NITEFEE")

for (col in num_cols) {
  if (col %in% names(raw)) {
    raw[[col]] <- as.numeric(raw[[col]])
  }
}

raw$CERT <- as.integer(raw$CERT)
raw$REPDTE <- as.character(raw$REPDTE)

# Save raw data
saveRDS(raw, "../data/fdic_raw.rds")
cat("Saved:", nrow(raw), "rows to data/fdic_raw.rds\n")
cat("Unique banks:", n_distinct(raw$CERT), "\n")
cat("Date range:", min(raw$REPDTE), "to", max(raw$REPDTE), "\n")

cat("\n✓ Data fetch complete.\n")
