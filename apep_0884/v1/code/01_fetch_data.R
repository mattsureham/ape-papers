## 01_fetch_data.R — Fetch BFS STATENT, UDEMO, and cross-border data via PXWeb
## APEP-0884: The World's Highest Minimum Wage

source("00_packages.R")

if (!requireNamespace("pxweb", quietly = TRUE)) {
  install.packages("pxweb", repos = "https://cloud.r-project.org")
}
library(pxweb)

# ============================================================================
# Table 1: STATENT — Establishments and employed persons by canton and NOGA
# BFS table: px-x-0602010000_101
# "Arbeitsstätten und Beschäftigte nach Kanton und Wirtschaftsabteilung"
# ============================================================================

cat("=== Fetching STATENT data ===\n")

statent_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_101/px-x-0602010000_101.px"

# Get metadata to see variable codes
statent_meta <- pxweb_get(statent_url)
cat("STATENT variables:\n")
for (v in statent_meta$variables) {
  cat("  ", v$code, ":", v$text, " (", length(v$values), " values)\n")
  if (length(v$values) <= 50) {
    cat("    Codes:", paste(head(v$values, 10), collapse = ", "), "\n")
    cat("    Labels:", paste(head(v$valueTexts, 10), collapse = ", "), "\n")
  }
}

# Build query: all cantons, all NOGA divisions, all years, all variables
# We need at least Geneva (25) and Vaud (22)
statent_query <- pxweb_query(list(
  # Select all available values for each dimension
  # Variable codes come from the metadata
))

# First, get all variable codes
var_codes <- list()
for (v in statent_meta$variables) {
  var_codes[[v$code]] <- v$values
}

cat("\nVariable dimensions:\n")
for (nm in names(var_codes)) {
  cat("  ", nm, ":", length(var_codes[[nm]]), "values\n")
}

# Query all data (should be manageable — canton x NOGA x year ~ few thousand cells)
statent_query <- pxweb_query(var_codes)

cat("\nDownloading STATENT data...\n")
statent_raw <- pxweb_get(url = statent_url, query = statent_query)
statent_df <- as.data.frame(statent_raw, column.name.type = "code", variable.value.type = "code")
statent_df_labels <- as.data.frame(statent_raw, column.name.type = "text", variable.value.type = "text")

cat("STATENT dimensions:", nrow(statent_df), "rows x", ncol(statent_df), "cols\n")
cat("Columns:", paste(names(statent_df), collapse = ", "), "\n")
cat("Label columns:", paste(names(statent_df_labels), collapse = ", "), "\n")

# Save both code and label versions
saveRDS(statent_df, "../data/statent_raw_codes.rds")
saveRDS(statent_df_labels, "../data/statent_raw_labels.rds")
cat("STATENT saved to data/\n")

# Quick check: Geneva and Vaud data
cat("\nSample STATENT rows (Geneva = 25, Vaud = 22):\n")
print(head(statent_df[statent_df[[1]] %in% c("25", "22", "GE", "VD"), ], 10))

# ============================================================================
# Table 2: UDEMO — Enterprise demography by canton, sector, size
# BFS table: px-x-0602030000_204
# "Gründungen, Schliessungen und Bestand nach Kanton, Wirtschaftssektor"
# ============================================================================

cat("\n=== Fetching UDEMO data ===\n")

udemo_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602030000_204/px-x-0602030000_204.px"

udemo_meta <- pxweb_get(udemo_url)
cat("UDEMO variables:\n")
for (v in udemo_meta$variables) {
  cat("  ", v$code, ":", v$text, " (", length(v$values), " values)\n")
  if (length(v$values) <= 50) {
    cat("    Codes:", paste(head(v$values, 15), collapse = ", "), "\n")
    cat("    Labels:", paste(head(v$valueTexts, 15), collapse = ", "), "\n")
  }
}

# Build query for all data
udemo_var_codes <- list()
for (v in udemo_meta$variables) {
  udemo_var_codes[[v$code]] <- v$values
}

udemo_query <- pxweb_query(udemo_var_codes)

cat("\nDownloading UDEMO data...\n")
udemo_raw <- pxweb_get(url = udemo_url, query = udemo_query)
udemo_df <- as.data.frame(udemo_raw, column.name.type = "code", variable.value.type = "code")
udemo_df_labels <- as.data.frame(udemo_raw, column.name.type = "text", variable.value.type = "text")

cat("UDEMO dimensions:", nrow(udemo_df), "rows x", ncol(udemo_df), "cols\n")
cat("Columns:", paste(names(udemo_df), collapse = ", "), "\n")

saveRDS(udemo_df, "../data/udemo_raw_codes.rds")
saveRDS(udemo_df_labels, "../data/udemo_raw_labels.rds")
cat("UDEMO saved to data/\n")

# ============================================================================
# Table 3: Cross-border workers by canton, country, NOGA, sex
# BFS table: px-x-0302010000_105
# "Grenzgänger nach Arbeitskanton, Wohnsitzstaat, Wirtschaftsabteilung"
# ============================================================================

cat("\n=== Fetching cross-border worker data ===\n")

xborder_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0302010000_105/px-x-0302010000_105.px"

xborder_meta <- tryCatch(
  pxweb_get(xborder_url),
  error = function(e) {
    cat("Cross-border metadata failed:", e$message, "\n")
    # Try without subdirectory
    tryCatch(
      pxweb_get("https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0302010000_105.px"),
      error = function(e2) {
        cat("Alternate path also failed:", e2$message, "\n")
        NULL
      }
    )
  }
)

if (!is.null(xborder_meta)) {
  cat("Cross-border variables:\n")
  for (v in xborder_meta$variables) {
    cat("  ", v$code, ":", v$text, " (", length(v$values), " values)\n")
    if (length(v$values) <= 30) {
      cat("    Codes:", paste(head(v$values, 10), collapse = ", "), "\n")
      cat("    Labels:", paste(head(v$valueTexts, 10), collapse = ", "), "\n")
    }
  }

  xborder_var_codes <- list()
  for (v in xborder_meta$variables) {
    xborder_var_codes[[v$code]] <- v$values
  }

  xborder_query <- pxweb_query(xborder_var_codes)

  cat("\nDownloading cross-border data...\n")
  xborder_raw <- pxweb_get(url = xborder_url, query = xborder_query)
  xborder_df <- as.data.frame(xborder_raw, column.name.type = "code", variable.value.type = "code")
  xborder_df_labels <- as.data.frame(xborder_raw, column.name.type = "text", variable.value.type = "text")

  cat("Cross-border dimensions:", nrow(xborder_df), "rows x", ncol(xborder_df), "cols\n")

  saveRDS(xborder_df, "../data/xborder_raw_codes.rds")
  saveRDS(xborder_df_labels, "../data/xborder_raw_labels.rds")
  cat("Cross-border data saved to data/\n")
} else {
  cat("WARNING: Cross-border data could not be fetched. Proceeding without it.\n")
}

# ============================================================================
# Also fetch the more detailed STATENT by canton and economic TYPE
# px-x-0602010000_103: "Arbeitsstätten und Beschäftigte nach Kanton und Wirtschaftsart"
# ============================================================================

cat("\n=== Fetching detailed STATENT by canton and economic type ===\n")

statent2_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_103/px-x-0602010000_103.px"

statent2_meta <- tryCatch(pxweb_get(statent2_url), error = function(e) {
  cat("Detailed STATENT meta failed:", e$message, "\n")
  NULL
})

if (!is.null(statent2_meta)) {
  cat("Detailed STATENT variables:\n")
  for (v in statent2_meta$variables) {
    cat("  ", v$code, ":", v$text, " (", length(v$values), " values)\n")
  }

  s2_var_codes <- list()
  for (v in statent2_meta$variables) {
    s2_var_codes[[v$code]] <- v$values
  }

  # Check if total cells are reasonable
  total_cells <- prod(sapply(s2_var_codes, length))
  cat("Total cells:", total_cells, "\n")

  if (total_cells <= 500000) {
    cat("Downloading detailed STATENT...\n")
    s2_query <- pxweb_query(s2_var_codes)
    s2_raw <- pxweb_get(url = statent2_url, query = s2_query)
    s2_df <- as.data.frame(s2_raw, column.name.type = "code", variable.value.type = "code")
    s2_df_labels <- as.data.frame(s2_raw, column.name.type = "text", variable.value.type = "text")
    cat("Detailed STATENT:", nrow(s2_df), "rows\n")
    saveRDS(s2_df, "../data/statent_detailed_codes.rds")
    saveRDS(s2_df_labels, "../data/statent_detailed_labels.rds")
  } else {
    cat("Too many cells (", total_cells, "), skipping detailed download\n")
  }
}

cat("\n=== All data fetched successfully ===\n")
