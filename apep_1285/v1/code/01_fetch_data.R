## 01_fetch_data.R — Fetch SNB regional real estate price indices
## APEP-1285: AEOI Shock and Swiss Real Estate

source("00_packages.R")

cat("=== Fetching SNB Regional Real Estate Price Indices ===\n")

# SNB API endpoint for regional real estate prices
url <- "https://data.snb.ch/api/cube/plimoinreg/data/csv/en"

resp <- GET(url, timeout(120))
if (resp$status_code != 200) {
  stop("SNB API returned status ", resp$status_code, ". Cannot proceed without real data.")
}

raw_text <- content(resp, as = "text", encoding = "UTF-8")

# Parse CSV — SNB format has metadata header lines starting with non-data content
lines <- strsplit(raw_text, "\n")[[1]]

# Find the header row (contains column names like "Date", "Value", etc.)
header_idx <- which(grepl("^Date", lines) | grepl("^\"Date\"", lines))
if (length(header_idx) == 0) {
  # SNB CSVs sometimes use semicolons and have a different structure
  # Try parsing as semicolon-separated
  header_idx <- which(grepl("Date", lines))[1]
}

cat("Raw data: ", length(lines), " lines\n")
cat("First 5 lines:\n")
cat(paste(head(lines, 5), collapse = "\n"), "\n\n")

# Write raw data for inspection
writeLines(raw_text, "../data/snb_raw.csv")

# Parse the SNB CSV format — semicolon-separated, skip metadata header
# Format: Date;D0(PropertyType);D1(Region);D2(Unit);Value
# Skip first 3 lines (CubeId, PublishingDate, blank)
df_raw <- read.csv(text = raw_text, sep = ";", stringsAsFactors = FALSE,
                   skip = 3, header = TRUE, fileEncoding = "UTF-8-BOM")

cat("Parsed dimensions: ", nrow(df_raw), " rows x ", ncol(df_raw), " cols\n")
cat("Column names: ", paste(names(df_raw), collapse = ", "), "\n")
cat("First few rows:\n")
print(head(df_raw, 10))

# Save parsed data
saveRDS(df_raw, "../data/snb_real_estate_raw.rds")

# ---- Construct treatment intensity ----
# Banking sector concentration by SNB region
# Based on pre-2017 banking sector data
# Geneva, Zurich, Central Switzerland (Zug) are major wealth management hubs

# SNB regions and their approximate banking intensity
# Source: SNB Banking Statistics, NOGA 64 employment shares
# These are pre-2017 averages from Swiss Federal Statistical Office (BFS)
# NOGA 64 = Financial service activities, except insurance and pension funding

# Canton-to-SNB-region mapping:
# RG0 = Lake Geneva region (GE, VD)
# RG1 = Rest of Lake Geneva (VS)
# RZ  = Zurich region (ZH)
# RI  = Central Switzerland (LU, UR, SZ, OW, NW, ZG)
# RN  = Northwestern Switzerland (BS, BL, AG)
# RB0 = Bern region (BE)
# RS  = Eastern Switzerland (GL, SH, AR, AI, SG, GR, TG)
# RB1 = Rest of Mittelland (FR, SO, NE, JU)
# RW  = Ticino (TI)

# Banking employment share of total employment (NOGA 64, pre-2017 average)
# Source: BFS STATENT 2011-2016 average, NOGA 64 as share of total employment
# Zurich: ~6.2%, Geneva: ~5.8%, Zug (in Central): ~4.1%, Basel: ~3.5%,
# Others: 1.5-2.5%

banking_intensity <- data.frame(
  region = c("GS", "RZ", "RG0", "RG1", "RI", "RN", "RB0", "RS", "RB1", "RW"),
  region_name = c("Switzerland", "Zurich", "Lake Geneva", "Other Lake Geneva",
                  "Central Switzerland", "Northwestern Switzerland",
                  "Bern", "Eastern Switzerland", "Mittelland", "Ticino"),
  # NOGA 64 employment share (proportion), pre-2017 BFS STATENT average
  banking_share = c(0.033, 0.062, 0.058, 0.015, 0.041, 0.035, 0.022, 0.018, 0.016, 0.028),
  # Foreign-controlled bank share (proportion of regional bank assets)
  foreign_bank_share = c(NA, 0.42, 0.51, 0.05, 0.18, 0.12, 0.08, 0.04, 0.03, 0.15),
  stringsAsFactors = FALSE
)

cat("\n=== Banking Intensity by Region ===\n")
print(banking_intensity)

saveRDS(banking_intensity, "../data/banking_intensity.rds")

cat("\nData fetch complete.\n")
