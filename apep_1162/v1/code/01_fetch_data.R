# 01_fetch_data.R — Fetch Eurostat data for Belgium SSC study
# apep_1162

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

cat("=== Fetching Eurostat data ===\n")

# ─────────────────────────────────────────────────────────────
# 1. Quarterly employment by NACE A*10 sector
#    Table: namq_10_a10_e
#    Countries: BE, NL, DE, LU, AT, FR, DK, FI, SE (for SCM pool)
# ─────────────────────────────────────────────────────────────

cat("Fetching quarterly employment (namq_10_a10_e)...\n")
emp_raw <- get_eurostat(
  id = "namq_10_a10_e",
  filters = list(
    geo = c("BE", "NL", "DE", "LU", "AT", "FR", "DK", "FI", "SE"),
    s_adj = "SCA",       # Seasonally and calendar adjusted
    unit = "THS_PER",    # Thousands of persons
    na_item = "EMP_DC"   # Total employment (domestic concept)
  ),
  time_format = "date"
)
stopifnot("Empty employment data" = nrow(emp_raw) > 0)
cat(sprintf("  Employment: %d rows fetched\n", nrow(emp_raw)))
saveRDS(emp_raw, "emp_raw.rds")

# ─────────────────────────────────────────────────────────────
# 2. Labor Cost Index — wages vs non-wage
#    Table: lc_lci_r2_q
# ─────────────────────────────────────────────────────────────

cat("Fetching labor cost index (lc_lci_r2_q)...\n")
lci_raw <- get_eurostat(
  id = "lc_lci_r2_q",
  filters = list(
    geo = c("BE", "NL", "DE", "LU", "AT", "FR"),
    s_adj = "SCA",
    unit = "I20",         # Index 2020 = 100
    lcstruct = c("D11", "D12_D4_MD5"),  # Wages; Non-wage costs
    nace_r2 = "B-S"       # Total business economy
  ),
  time_format = "date"
)
stopifnot("Empty LCI data" = nrow(lci_raw) > 0)
cat(sprintf("  LCI: %d rows fetched\n", nrow(lci_raw)))
saveRDS(lci_raw, "lci_raw.rds")

# ─────────────────────────────────────────────────────────────
# 3. National accounts: compensation breakdown by sector
#    Table: namq_10_a10
#    Items: D1 (compensation), D11 (wages), D12 (employer SSC)
# ─────────────────────────────────────────────────────────────

cat("Fetching compensation breakdown (namq_10_a10)...\n")
comp_raw <- get_eurostat(
  id = "namq_10_a10",
  filters = list(
    geo = c("BE", "NL", "DE", "LU", "AT", "FR"),
    s_adj = "SCA",
    unit = "CP_MNAC",      # Current prices, million national currency
    na_item = c("D1", "D11", "D12")  # Compensation, wages, employer SSC
  ),
  time_format = "date"
)
stopifnot("Empty compensation data" = nrow(comp_raw) > 0)
cat(sprintf("  Compensation: %d rows fetched\n", nrow(comp_raw)))
saveRDS(comp_raw, "comp_raw.rds")

# ─────────────────────────────────────────────────────────────
# 4. Annual GVA and compensation by sector (for labor intensity)
#    Table: nama_10_a10
# ─────────────────────────────────────────────────────────────

cat("Fetching annual GVA and compensation (nama_10_a10)...\n")
gva_raw <- get_eurostat(
  id = "nama_10_a10",
  filters = list(
    geo = c("BE", "NL", "DE", "LU", "AT", "FR"),
    unit = "CP_MNAC",
    na_item = c("B1G", "D1")  # GVA and compensation
  ),
  time_format = "date"
)
stopifnot("Empty GVA data" = nrow(gva_raw) > 0)
cat(sprintf("  GVA: %d rows fetched\n", nrow(gva_raw)))
saveRDS(gva_raw, "gva_raw.rds")

cat("\n=== All data fetched successfully ===\n")
cat(sprintf("Files saved to: %s\n", getwd()))
