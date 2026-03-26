# 01_fetch_data.R — Fetch Latvia Enterprise Register data
# apep_1021: Latvia AML Shell-Company Ban

source("00_packages.R")

# --- Download Latvia Enterprise Register ---
url <- "https://dati.ur.gov.lv/register/register.csv"
dest <- "../data/register.csv"

if (!file.exists(dest)) {
  cat("Downloading Latvia Enterprise Register (121MB)...\n")
  download.file(url, dest, mode = "wb", timeout = 600)
  cat("Download complete.\n")
} else {
  cat("Register file already exists, skipping download.\n")
}

# Validate download
stopifnot("Download failed: file does not exist" = file.exists(dest))
file_size <- file.info(dest)$size
stopifnot("Download failed: file too small (< 50MB)" = file_size > 50e6)
cat(sprintf("File size: %.1f MB\n", file_size / 1e6))

# --- Read and validate ---
# The file uses semicolon delimiter
reg <- fread(dest, sep = ";", encoding = "UTF-8", fill = TRUE)
cat(sprintf("Rows read: %d\n", nrow(reg)))
stopifnot("Data empty or corrupted" = nrow(reg) > 100000)

# Inspect column names
cat("Columns:", paste(names(reg), collapse = ", "), "\n")

# Standardize column names (handle potential BOM or encoding issues)
names(reg) <- trimws(names(reg))

# Basic validation
stopifnot("Missing 'registered' column" = "registered" %in% names(reg))
stopifnot("Missing 'regcode' column" = "regcode" %in% names(reg))

# Parse dates
reg[, registered := as.Date(registered, format = "%Y-%m-%d")]
reg[, terminated := as.Date(terminated, format = "%Y-%m-%d")]

# Summary stats
cat(sprintf("\nTotal firms: %d\n", nrow(reg)))
cat(sprintf("With termination date: %d (%.1f%%)\n",
            sum(!is.na(reg$terminated)),
            100 * mean(!is.na(reg$terminated))))
cat(sprintf("Date range (registered): %s to %s\n",
            min(reg$registered, na.rm = TRUE),
            max(reg$registered, na.rm = TRUE)))
cat(sprintf("Date range (terminated): %s to %s\n",
            min(reg$terminated, na.rm = TRUE),
            max(reg$terminated, na.rm = TRUE)))

# Check firm types
cat("\nFirm type distribution:\n")
print(reg[, .N, by = type_text][order(-N)][1:10])

# Check region distribution
cat("\nRegion distribution:\n")
print(reg[, .N, by = region][order(-N)][1:10])

# Save parsed data
saveRDS(reg, "../data/register_parsed.rds")
cat("\nParsed data saved to data/register_parsed.rds\n")
