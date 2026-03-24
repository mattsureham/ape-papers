# 01_fetch_data.R — Fetch HDB resale transactions and Census 2020 ethnic data
# Data sources:
#   - HDB resale transactions: data.gov.sg (227K+ records, 2017-2026)
#   - Census 2020 ethnic composition: SingStat Table Builder (table 17561)

source("00_packages.R")

# ============================================================
# Part 1: HDB Resale Transactions
# ============================================================
cat("=== Loading HDB Resale Flat Prices ===\n")

batch_dir <- "../data/hdb_batches"
if (!dir.exists(batch_dir)) {
  stop("FATAL: HDB batch directory not found at ", batch_dir,
       ". Run the curl fetch script first.")
}

batch_files <- list.files(batch_dir, pattern = "^batch_.*\\.json$", full.names = TRUE)
if (length(batch_files) == 0) {
  stop("FATAL: No batch files found in ", batch_dir)
}

cat("Found", length(batch_files), "batch files.\n")

all_records <- list()
for (bf in batch_files) {
  raw <- jsonlite::fromJSON(bf, flatten = TRUE)
  if (!is.null(raw$result$records) && nrow(raw$result$records) > 0) {
    all_records[[length(all_records) + 1]] <- raw$result$records
  }
}

hdb_raw <- bind_rows(all_records)
cat("HDB resale transactions loaded:", nrow(hdb_raw), "\n")
cat("Columns:", paste(names(hdb_raw), collapse = ", "), "\n")
cat("Date range:", min(hdb_raw$month, na.rm = TRUE), "to",
    max(hdb_raw$month, na.rm = TRUE), "\n")

if (nrow(hdb_raw) < 50000) {
  stop("FATAL: Only ", nrow(hdb_raw), " HDB records loaded. Expected 50K+.")
}
cat("NOTE: Loaded", nrow(hdb_raw), "of ~227K total records.\n")
cat("      More batches may still be downloading.\n")

saveRDS(hdb_raw, "../data/hdb_resale_raw.rds")
cat("Saved hdb_resale_raw.rds\n")

# ============================================================
# Part 2: Census 2020 Ethnic Composition by Subzone
# ============================================================
cat("\n=== Parsing Census 2020 Ethnic Data ===\n")

census_file <- "../data/census_ethnic_subzone.json"
if (!file.exists(census_file)) {
  stop("FATAL: Census data not found at ", census_file,
       ". Fetch from SingStat Table Builder (table 17561) first.")
}

census_raw <- jsonlite::fromJSON(census_file)
rows <- census_raw$Data$row

# Parse the nested structure
parse_row <- function(i) {
  name <- rows$rowText[i]
  cols_df <- rows$columns[[i]]
  result <- list(subzone = name)
  for (j in seq_len(nrow(cols_df))) {
    ethnic <- cols_df$key[j]
    inner <- cols_df$columns[[j]]
    total_val <- as.numeric(inner$value[inner$key == "Total"])
    if (length(total_val) == 1 && !is.na(total_val)) {
      col_name <- tolower(gsub("s$", "", ethnic))
      result[[paste0(col_name, "_pop")]] <- total_val
    }
  }
  as.data.frame(result, stringsAsFactors = FALSE)
}

census_list <- lapply(seq_len(nrow(rows)), parse_row)

census_df <- bind_rows(census_list)
cat("Census records parsed:", nrow(census_df), "\n")
cat("Columns:", paste(names(census_df), collapse = ", "), "\n")

saveRDS(census_df, "../data/census_ethnic_parsed.rds")
cat("Saved census_ethnic_parsed.rds\n")

# Show planning area totals
planning_areas <- census_df %>%
  filter(grepl("- Total$", subzone)) %>%
  mutate(
    town = str_trim(gsub(" - Total$", "", subzone)),
    total = total_pop,
    chinese_pct = 100 * chinese_pop / total_pop,
    malay_pct = 100 * malay_pop / total_pop,
    indian_pct = 100 * indian_pop / total_pop,
    other_pct = 100 * other_pop / total_pop
  )

cat("\nPlanning Area Ethnic Composition (Census 2020):\n")
pa_display <- planning_areas %>%
  select(town, total, chinese_pct, malay_pct, indian_pct) %>%
  arrange(desc(chinese_pct)) %>%
  filter(!is.na(chinese_pct))
print(as.data.frame(pa_display), row.names = FALSE)

cat("\n=== Data Fetch Complete ===\n")
