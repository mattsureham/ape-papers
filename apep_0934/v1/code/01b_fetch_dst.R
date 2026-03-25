# 01b_fetch_dst.R — Fix DST StatBank fetches with correct variable codes
source("00_packages.R")

data_dir <- "../data"

# Helper: parse DST response
dst_fetch <- function(table_id, variables) {
  body <- list(
    table = table_id,
    format = "CSV",
    delimiter = "Semicolon",
    variables = variables
  )
  resp <- httr::POST("https://api.statbank.dk/v1/data",
                     body = body, encode = "json",
                     httr::timeout(180))
  if (httr::status_code(resp) != 200) {
    msg <- httr::content(resp, as = "text", encoding = "UTF-8")
    stop(sprintf("DST %s fetch failed (%d): %s", table_id, httr::status_code(resp), msg))
  }
  txt <- httr::content(resp, as = "text", encoding = "UTF-8")
  read.csv(text = txt, sep = ";", stringsAsFactors = FALSE)
}

# ============================================================================
# 1. EJDFOE1: Property values by municipality
# Variable codes from metadata: VAERDI, BOPKOM, ENHED, EJENTYP, Tid
# ============================================================================
cat("=== Fetching EJDFOE1 (property values) ===\n")

ejd_df <- dst_fetch("EJDFOE1", list(
  list(code = "VAERDI", values = list("100")),      # Market value
  list(code = "BOPKOM", values = list("*")),         # All municipalities
  list(code = "ENHED", values = list("120")),        # Average (Kr.)
  list(code = "EJENTYP", values = list("A")),        # Single-family houses
  list(code = "Tid", values = list("*"))             # All years
))
cat(sprintf("  EJDFOE1 rows: %d\n", nrow(ejd_df)))
cat(sprintf("  Columns: %s\n", paste(names(ejd_df), collapse = ", ")))
cat(sprintf("  Sample:\n"))
print(head(ejd_df, 3))
saveRDS(ejd_df, file.path(data_dir, "ejdfoe1_raw.rds"))

# Also fetch total property value (not just avg)
ejd_total <- dst_fetch("EJDFOE1", list(
  list(code = "VAERDI", values = list("100")),      # Market value
  list(code = "BOPKOM", values = list("*")),
  list(code = "ENHED", values = list("110")),        # Total (mio. kr.)
  list(code = "EJENTYP", values = list("T")),        # All property types
  list(code = "Tid", values = list("*"))
))
cat(sprintf("  EJDFOE1 total rows: %d\n", nrow(ejd_total)))
saveRDS(ejd_total, file.path(data_dir, "ejdfoe1_total.rds"))

# ============================================================================
# 2. VALGK3: Municipal election results
# Variables: OMRÅDE, PARTI, STEMMER, Tid
# ============================================================================
cat("\n=== Fetching VALGK3 (municipal elections) ===\n")

# Fetch vote counts (stemmer) for all parties in all municipalities
elec_df <- dst_fetch("VALGK3", list(
  list(code = "OMRÅDE", values = list("*")),
  list(code = "PARTI", values = list("*")),
  list(code = "STEMMER", values = list("1")),     # Number of votes/vote share
  list(code = "Tid", values = list("*"))
))
cat(sprintf("  VALGK3 rows: %d\n", nrow(elec_df)))
cat(sprintf("  Columns: %s\n", paste(names(elec_df), collapse = ", ")))
print(head(elec_df, 3))
saveRDS(elec_df, file.path(data_dir, "elections_raw.rds"))

# Also get total valid votes for computing shares
elec_total <- dst_fetch("VALGK3", list(
  list(code = "OMRÅDE", values = list("*")),
  list(code = "PARTI", values = list("*")),
  list(code = "STEMMER", values = list("*")),
  list(code = "Tid", values = list("*"))
))
cat(sprintf("  VALGK3 full rows: %d\n", nrow(elec_total)))
saveRDS(elec_total, file.path(data_dir, "elections_full.rds"))

# ============================================================================
# 3. INDKP106: Income by municipality
# Variables: OMRÅDE, ENHED, KOEN, ALDER1, INDKINTB, Tid
# ============================================================================
cat("\n=== Fetching INDKP106 (income) ===\n")

inc_df <- dst_fetch("INDKP106", list(
  list(code = "OMRÅDE", values = list("*")),
  list(code = "ENHED", values = list("118")),          # Average income (kr.)
  list(code = "KOEN", values = list("MOK")),            # Both sexes
  list(code = "ALDER1", values = list("00")),           # All ages
  list(code = "INDKINTB", values = list("000")),        # All income intervals
  list(code = "Tid", values = list("*"))
))
cat(sprintf("  INDKP106 rows: %d\n", nrow(inc_df)))
cat(sprintf("  Columns: %s\n", paste(names(inc_df), collapse = ", ")))
print(head(inc_df, 3))
saveRDS(inc_df, file.path(data_dir, "income_raw.rds"))

# ============================================================================
# Summary
# ============================================================================
cat("\n=== All DST data fetched ===\n")
files <- list.files(data_dir, pattern = "\\.rds$")
cat(sprintf("Total files: %d\n%s\n", length(files), paste(files, collapse = "\n")))
