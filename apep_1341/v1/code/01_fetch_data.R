# 01_fetch_data.R — Download EPA RCRAInfo Biennial Report data
# apep_1341: RCRA Hazardous Waste Generator Thresholds

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# Helper: download BR_REPORTING for one cycle
# ============================================================
download_br_cycle <- function(cycle, data_dir, batch_size = 1000) {
  rds_file <- file.path(data_dir, sprintf("br_%d_raw.rds", cycle))
  if (file.exists(rds_file)) {
    cat(sprintf("Already have cycle %d\n", cycle))
    return(readRDS(rds_file))
  }

  base_url <- "https://data.epa.gov/efservice/BR_REPORTING"
  all_chunks <- list()
  offset <- 0
  max_retries <- 3

  cat(sprintf("Downloading cycle %d...\n", cycle))
  repeat {
    url <- sprintf("%s/report_cycle/%d/ROWS/%d:%d/JSON",
                   base_url, cycle, offset, offset + batch_size - 1)

    success <- FALSE
    for (attempt in 1:max_retries) {
      resp <- tryCatch(
        GET(url, timeout(180)),
        error = function(e) NULL
      )
      if (!is.null(resp) && status_code(resp) == 200) {
        success <- TRUE
        break
      }
      cat(sprintf("  Retry %d for offset %d\n", attempt, offset))
      Sys.sleep(5 * attempt)
    }

    if (!success) {
      cat(sprintf("  Failed at offset %d after %d retries. Stopping.\n", offset, max_retries))
      break
    }

    chunk <- tryCatch(
      fromJSON(content(resp, as = "text", encoding = "UTF-8")),
      error = function(e) NULL
    )
    if (is.null(chunk) || nrow(chunk) == 0) break

    keep_cols <- intersect(names(chunk),
      c("handler_id", "activity_location", "report_cycle",
        "generation_tons", "calculated_generator_status",
        "primary_naics", "source_code", "waste_code_group"))
    chunk <- chunk[, keep_cols, drop = FALSE]

    all_chunks[[length(all_chunks) + 1]] <- chunk
    n_total <- sum(sapply(all_chunks, nrow))
    cat(sprintf("  Offset %d: +%d rows (total: %d)\n", offset, nrow(chunk), n_total))

    if (nrow(chunk) < batch_size) break
    offset <- offset + batch_size
    Sys.sleep(1)
  }

  if (length(all_chunks) == 0) {
    stop(sprintf("FATAL: No data for cycle %d", cycle))
  }

  result <- bind_rows(all_chunks)
  saveRDS(result, rds_file)
  cat(sprintf("  Saved: %d rows, %d handlers\n",
              nrow(result), length(unique(result$handler_id))))
  return(result)
}

# ============================================================
# Download 3 most recent cycles (2019, 2021, 2023)
# ============================================================
br_list <- list()
for (cycle in c(2019, 2021, 2023)) {
  br_list[[as.character(cycle)]] <- download_br_cycle(cycle, data_dir)
}

br_all <- bind_rows(br_list)

# ============================================================
# Load RCRA_FACILITIES for supplementary info
# ============================================================
fac_file <- file.path(data_dir, "RCRA_FACILITIES.csv")
if (file.exists(fac_file)) {
  fac <- read_csv(fac_file, col_types = cols(.default = "c"),
                  col_select = c("ID_NUMBER", "FACILITY_NAME",
                                 "ACTIVITY_LOCATION", "HREPORT_UNIVERSE_RECORD",
                                 "STATE_CODE", "LATITUDE83", "LONGITUDE83",
                                 "FED_WASTE_GENERATOR", "ACTIVE_SITE"))
  cat("\nRCRA_FACILITIES loaded:", nrow(fac), "facilities\n")
  cat("Generator universe:\n")
  print(table(fac$HREPORT_UNIVERSE_RECORD, useNA = "ifany"))
}

# ============================================================
# Validation
# ============================================================
cat("\n=== Validation ===\n")
cat("Total rows:", nrow(br_all), "\n")
cat("Unique handlers:", length(unique(br_all$handler_id)), "\n")
cat("Cycles:", paste(sort(unique(br_all$report_cycle)), collapse = ", "), "\n")

cat("\nGenerator status:\n")
print(table(br_all$calculated_generator_status, useNA = "ifany"))

br_all$gen_tons <- as.numeric(br_all$generation_tons)
cat("\nGeneration tons:\n")
print(summary(br_all$gen_tons))
cat("Non-zero:", sum(br_all$gen_tons > 0, na.rm = TRUE), "\n")

cat("\n01_fetch_data.R complete.\n")
