## 01_fetch_data.R — Download FJC IDB criminal data and construct AVR panel
## apep_0944: AVR and Federal Jury Acquittal Rates

library(data.table)
library(jsonlite)

# setwd handled by caller
cat("Working directory:", getwd(), "\n")

# ── 1. Download FJC Integrated Database (Criminal) ──────────────────────
fjc_url <- "https://www.fjc.gov/sites/default/files/idb/textfiles/cr96on.zip"
zip_path <- "data/cr96on.zip"
txt_dir <- "data/fjc_raw"
txt_file <- file.path(txt_dir, "cr96on.txt")

dir.create(txt_dir, showWarnings = FALSE, recursive = TRUE)

if (!file.exists(zip_path)) {
  cat("Downloading FJC IDB criminal data (240MB)...\n")
  download.file(fjc_url, zip_path, mode = "wb", timeout = 600)
  stopifnot("Download failed" = file.exists(zip_path) && file.size(zip_path) > 1e6)
  cat("Download complete:", round(file.size(zip_path) / 1e6, 1), "MB\n")
} else {
  cat("FJC zip already exists:", round(file.size(zip_path) / 1e6, 1), "MB\n")
}

# Use system unzip (R unzip cannot handle deflate64 compression)
if (!file.exists(txt_file)) {
  cat("Extracting with system unzip (deflate64)...\n")
  rc <- system2("unzip", c("-o", zip_path, "-d", txt_dir), stdout = TRUE, stderr = TRUE)
  cat(tail(rc, 3), sep = "\n")
  stopifnot("Extraction failed" = file.exists(txt_file))
}
cat("Extracted file:", round(file.size(txt_file) / 1e9, 2), "GB\n")

# ── 2. Read only needed columns (memory efficient) ──────────────────────
cat("Reading FJC dataset (select columns only)...\n")
fjc <- fread(txt_file, sep = "\t", header = TRUE, fill = TRUE, quote = "",
             select = c("FISCALYR", "CIRCUIT", "DISTRICT", "DISP1"),
             na.strings = c("", "NA", "-8", "-9"),
             colClasses = c(FISCALYR = "integer", CIRCUIT = "integer",
                            DISTRICT = "integer", DISP1 = "integer"))
cat("Rows:", nrow(fjc), " Cols:", ncol(fjc), "\n")

# Standardize names
setnames(fjc, c("fiscalyr", "circuit", "district", "disp1"))

# Examine disposition values
cat("\nDisposition code distribution:\n")
print(fjc[, .N, by = disp1][order(disp1)])

cat("\nFiscal year range:", range(fjc$fiscalyr, na.rm = TRUE), "\n")
cat("Circuit values:", sort(unique(fjc$circuit)), "\n")

# ── 3. Save parsed data ─────────────────────────────────────────────────
fwrite(fjc, "data/fjc_criminal_parsed.csv")
cat("\nSaved parsed FJC data:", nrow(fjc), "rows\n")

# ── 4. Construct AVR treatment panel ─────────────────────────────────────
avr_states <- data.table(
  state_abbr = c("OR", "GA", "AK", "CO", "VT", "WV",
                 "CA", "DC", "IL", "NJ", "RI",
                 "MD", "MI", "WA",
                 "ME", "MA", "NV", "VA",
                 "HI",
                 "CT", "DE", "MN", "NM", "NY", "PA"),
  avr_year   = c(2016, 2016, 2017, 2017, 2017, 2017,
                 2018, 2018, 2018, 2018, 2018,
                 2019, 2019, 2019,
                 2020, 2020, 2020, 2020,
                 2022,
                 2023, 2023, 2023, 2023, 2023, 2023)
)

cat("\nAVR treatment panel:\n")
print(avr_states[order(avr_year, state_abbr)])
cat("Total AVR states:", nrow(avr_states), "\n")
cat("Adoption cohort sizes:\n")
print(avr_states[, .N, by = avr_year][order(avr_year)])

fwrite(avr_states, "data/avr_treatment.csv")
cat("Saved AVR treatment panel\n")

cat("\n=== 01_fetch_data.R complete ===\n")
