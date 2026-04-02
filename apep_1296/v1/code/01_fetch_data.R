## 01_fetch_data.R — Fetch Eurostat data for Lithuania i.SAF study
## apep_1296

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

countries <- c("LT", "LV", "EE", "FI", "PL")
years <- 2010:2022

# ─── 1. VAT revenue (gov_10a_taxag, D211) ───────────────────────────
cat("Fetching VAT revenue data (gov_10a_taxag)...\n")
vat_raw <- get_eurostat("gov_10a_taxag", time_format = "num",
                        filters = list(
                          geo = countries,
                          na_item = "D211",
                          sector = "S13",
                          unit = "MIO_EUR"
                        ))
if (is.null(vat_raw) || nrow(vat_raw) == 0) {
  stop("FATAL: VAT revenue data fetch returned empty. Cannot proceed.")
}
vat <- as.data.table(vat_raw)
vat <- vat[time >= 2010 & time <= 2022]
cat(sprintf("  VAT revenue: %d rows, %d countries, years %d-%d\n",
            nrow(vat), uniqueN(vat$geo), min(vat$time), max(vat$time)))
fwrite(vat, file.path(DATA_DIR, "vat_revenue.csv"))

# ─── 2. Total tax revenue (for GDP ratios) ──────────────────────────
cat("Fetching total tax revenue...\n")
tax_raw <- get_eurostat("gov_10a_taxag", time_format = "num",
                        filters = list(
                          geo = countries,
                          na_item = "D2",
                          sector = "S13",
                          unit = "MIO_EUR"
                        ))
if (!is.null(tax_raw) && nrow(tax_raw) > 0) {
  tax <- as.data.table(tax_raw)
  tax <- tax[time >= 2010 & time <= 2022]
  cat(sprintf("  Total tax: %d rows\n", nrow(tax)))
  fwrite(tax, file.path(DATA_DIR, "total_tax.csv"))
} else {
  cat("  WARNING: Total tax data not available\n")
}

# ─── 3. GDP (nama_10_gdp) ───────────────────────────────────────────
cat("Fetching GDP data...\n")
gdp_raw <- get_eurostat("nama_10_gdp", time_format = "num",
                        filters = list(
                          geo = countries,
                          na_item = "B1GQ",
                          unit = "CP_MEUR"
                        ))
if (is.null(gdp_raw) || nrow(gdp_raw) == 0) {
  stop("FATAL: GDP data fetch returned empty. Cannot proceed.")
}
gdp <- as.data.table(gdp_raw)
gdp <- gdp[time >= 2010 & time <= 2022]
cat(sprintf("  GDP: %d rows\n", nrow(gdp)))
fwrite(gdp, file.path(DATA_DIR, "gdp.csv"))

# ─── 4. Sector-level GVA (nama_10_a64) ──────────────────────────────
cat("Fetching sector GVA (nama_10_a64)...\n")
gva_raw <- get_eurostat("nama_10_a64", time_format = "num",
                        filters = list(
                          geo = countries,
                          na_item = "B1G",
                          unit = "CP_MEUR"
                        ))
if (is.null(gva_raw) || nrow(gva_raw) == 0) {
  stop("FATAL: Sector GVA data fetch returned empty. Cannot proceed.")
}
gva <- as.data.table(gva_raw)
gva <- gva[time >= 2010 & time <= 2022]
cat(sprintf("  Sector GVA: %d rows, %d sectors\n",
            nrow(gva), uniqueN(gva$nace_r2)))
fwrite(gva, file.path(DATA_DIR, "sector_gva.csv"))

# ─── 5. Business demography (bd_9bd_sz_cl_r2) ───────────────────────
cat("Fetching business demography...\n")
bd_raw <- tryCatch(
  get_eurostat("bd_9bd_sz_cl_r2", time_format = "num",
               filters = list(
                 geo = countries,
                 indic_sb = c("V11910", "V11920"),  # births, deaths
                 sizeclas = "TOTAL"
               )),
  error = function(e) {
    cat(sprintf("  WARNING: Business demography not available: %s\n", e$message))
    NULL
  }
)
if (!is.null(bd_raw) && nrow(bd_raw) > 0) {
  bd <- as.data.table(bd_raw)
  bd <- bd[time >= 2010 & time <= 2022]
  cat(sprintf("  Business demography: %d rows\n", nrow(bd)))
  fwrite(bd, file.path(DATA_DIR, "business_demography.csv"))
} else {
  cat("  Business demography unavailable — will use GVA only\n")
}

# ─── 6. Input-output table for Lithuania (naio_10_cp1700) ────────────
cat("Fetching Lithuanian input-output table...\n")
io_raw <- tryCatch(
  get_eurostat("naio_10_cp1700", time_format = "num",
               filters = list(
                 geo = "LT",
                 unit = "MIO_EUR",
                 stk_flow = "TOTAL"
               )),
  error = function(e) {
    cat(sprintf("  WARNING: I-O table fetch error: %s\n", e$message))
    NULL
  }
)
if (!is.null(io_raw) && nrow(io_raw) > 0) {
  io <- as.data.table(io_raw)
  cat(sprintf("  I-O table: %d rows\n", nrow(io)))
  fwrite(io, file.path(DATA_DIR, "io_table_lt.csv"))
} else {
  cat("  I-O table unavailable — will construct proxy from GVA shares\n")
}

# ─── Summary ─────────────────────────────────────────────────────────
cat("\n=== Fetch Summary ===\n")
files <- list.files(DATA_DIR, pattern = "\\.csv$")
for (f in files) {
  sz <- file.info(file.path(DATA_DIR, f))$size
  cat(sprintf("  %s: %.1f KB\n", f, sz / 1024))
}
cat("Done.\n")
