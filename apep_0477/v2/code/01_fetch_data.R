###############################################################################
# 01_fetch_data.R — Load Chi et al. (2023) pre-linked LR-EPC dataset
# apep_0477 v2: Do Energy Labels Move Markets?
#
# Data source: Chi, Dennett, Onji & Slaw (2023)
# "A New Attribute-Linked Residential Property Price Dataset for
#  England and Wales, 2011–2019" (UKDS ReShare SN 856542)
#
# The pre-linked dataset was converted from CSV to parquet by
# convert_to_parquet.py (run before this script).
###############################################################################

source("00_packages.R")

DATA_DIR <- "../data"
LINKED_PARQUET <- file.path(DATA_DIR, "linked_transactions_2015.parquet")

if (!file.exists(LINKED_PARQUET)) {
  stop(paste0(
    "Linked transactions parquet not found at: ", LINKED_PARQUET, "\n",
    "Run convert_to_parquet.py first to create it from the Chi et al. CSV.\n",
    "Source: UK Data Service ReShare SN 856542"
  ))
}

cat("=== Loading Chi et al. (2023) pre-linked dataset ===\n")
df <- as.data.table(read_parquet(LINKED_PARQUET))

cat(sprintf("Linked transactions: %s rows\n", format(nrow(df), big.mark = ",")))
cat(sprintf("Date range: %s to %s\n",
            min(df$dateoftransfer, na.rm = TRUE),
            max(df$dateoftransfer, na.rm = TRUE)))
cat(sprintf("Columns: %s\n", paste(names(df), collapse = ", ")))

# Quick summary of key fields
cat(sprintf("\nEPC score range: %d to %d\n",
            min(df$CURRENT_ENERGY_EFFICIENCY, na.rm = TRUE),
            max(df$CURRENT_ENERGY_EFFICIENCY, na.rm = TRUE)))
cat(sprintf("EPC bands: %s\n",
            paste(sort(unique(df$CURRENT_ENERGY_RATING)), collapse = ", ")))

cat("\nUPRN_SOURCE distribution:\n")
print(df[, .(N = .N, pct = round(.N/nrow(df)*100, 1)), by = UPRN_SOURCE])

cat("\nProperty types (LR):\n")
print(df[, .(N = .N), by = propertytype][order(-N)])

cat("\nTenure distribution:\n")
print(df[, .(N = .N, pct = round(.N/nrow(df)*100, 1)), by = TENURE][order(-N)])

# Near boundaries
for (i in seq_along(EPC_BOUNDARIES)) {
  b <- EPC_BOUNDARIES[i]
  n_near <- sum(abs(df$CURRENT_ENERGY_EFFICIENCY - b) <= 10)
  cat(sprintf("  Near %s boundary (±10): %s transactions\n",
              EPC_BAND_NAMES[i], format(n_near, big.mark = ",")))
}

cat("\nData load complete.\n")
