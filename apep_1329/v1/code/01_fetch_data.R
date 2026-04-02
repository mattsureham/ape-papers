## 01_fetch_data.R — Download Ofgem FIT Installation Report
## APEP-1329: UK FIT Triple-Threshold Bunching

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ── Ofgem FIT Installation Report (3 parts, Dec 2024) ──
base_url <- "https://www.ofgem.gov.uk/sites/default/files/2025-02"
parts <- c(
  "Feed-in%20Tariff%20installation%20report%20part%201_0.xlsx",
  "Feed-in%20Tariff%20installation%20report%20part%202_0.xlsx",
  "Feed-in%20Tariff%20installation%20report%20part%203_0.xlsx"
)

for (i in seq_along(parts)) {
  outfile <- file.path(data_dir, sprintf("fit_part%d.xlsx", i))
  if (!file.exists(outfile)) {
    url <- paste0(base_url, "/", parts[i])
    cat(sprintf("Downloading part %d...\n", i))
    resp <- GET(url, write_disk(outfile, overwrite = TRUE),
                timeout(300), progress())
    if (status_code(resp) != 200 || file.size(outfile) < 1e6) {
      stop(sprintf("FATAL: Failed to download part %d. Status: %d", i, status_code(resp)))
    }
    cat(sprintf("  Part %d: %.1f MB\n", i, file.size(outfile) / 1e6))
  } else {
    cat(sprintf("Part %d already exists: %.1f MB\n", i, file.size(outfile) / 1e6))
  }
}

# ── Read and combine all parts ──
cat("\nReading Excel files...\n")
all_parts <- list()

for (i in 1:3) {
  f <- file.path(data_dir, sprintf("fit_part%d.xlsx", i))
  cat(sprintf("Reading part %d...\n", i))
  sheets <- excel_sheets(f)
  cat("  Sheets:", paste(sheets, collapse = ", "), "\n")

  # Read the first/main sheet
  df_i <- read_excel(f, sheet = 1, guess_max = 50000)
  cat(sprintf("  Part %d: %d rows, %d cols\n", i, nrow(df_i), ncol(df_i)))
  cat("  Columns:", paste(names(df_i), collapse = ", "), "\n")
  all_parts[[i]] <- df_i
}

# Combine
df_raw <- bind_rows(all_parts)
cat(sprintf("\nCombined: %d rows, %d cols\n", nrow(df_raw), ncol(df_raw)))

# ── Filter to Solar PV only ──
cat("\nColumn names:\n")
print(names(df_raw))

# Check technology column
tech_col <- grep("technol|tech|type", names(df_raw), ignore.case = TRUE, value = TRUE)
cat("Technology column candidates:", paste(tech_col, collapse = ", "), "\n")

if (length(tech_col) > 0) {
  cat("Technology values:\n")
  print(table(df_raw[[tech_col[1]]]))
}

# Save combined raw data
saveRDS(df_raw, file.path(data_dir, "fit_raw.rds"))
cat("\nRaw data saved to fit_raw.rds\n")
cat("DONE: Data fetch complete.\n")
