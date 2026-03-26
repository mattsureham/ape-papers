# 01c_fetch_historical.R — Fetch historical CZSO data and broader Eurostat coverage
source("00_packages.R")

# ---------------------------------------------------------------
# 1. Try CZSO year-specific tables (140133qYY format)
# ---------------------------------------------------------------
cat("=== Trying CZSO year-specific sector data ===\n")

# Check what year-specific tables exist
catalogue <- czso::czso_get_catalogue()
yearly_sector <- catalogue[grepl("^140133q", catalogue$dataset_id), ]
yearly_form <- catalogue[grepl("^140131q", catalogue$dataset_id), ]
cat("Available sector yearly tables:", paste(yearly_sector$dataset_id, collapse = ", "), "\n")
cat("Available form yearly tables:", paste(yearly_form$dataset_id, collapse = ", "), "\n")

# Fetch all available year-specific sector tables
sector_years <- list()
for (tid in yearly_sector$dataset_id) {
  cat("Fetching", tid, "...")
  tryCatch({
    d <- czso::czso_get_table(tid)
    cat(" OK:", nrow(d), "rows\n")
    # Extract year from ID (e.g., 140133q22 -> 2022)
    yr <- as.integer(paste0("20", gsub(".*q", "", tid)))
    d$source_year <- yr
    sector_years[[tid]] <- d
  }, error = function(e) cat(" FAILED:", e$message, "\n"))
}

if (length(sector_years) > 0) {
  sector_panel <- bind_rows(sector_years)
  cat("\nTotal sector panel:", nrow(sector_panel), "rows across", length(sector_years), "years\n")
  saveRDS(sector_panel, "../data/czso_sector_panel.rds")
}

# Fetch all available year-specific legal form tables
form_years <- list()
for (tid in yearly_form$dataset_id) {
  cat("Fetching", tid, "...")
  tryCatch({
    d <- czso::czso_get_table(tid)
    cat(" OK:", nrow(d), "rows\n")
    yr <- as.integer(paste0("20", gsub(".*q", "", tid)))
    d$source_year <- yr
    form_years[[tid]] <- d
  }, error = function(e) cat(" FAILED:", e$message, "\n"))
}

if (length(form_years) > 0) {
  form_panel <- bind_rows(form_years)
  cat("\nTotal form panel:", nrow(form_panel), "rows across", length(form_years), "years\n")
  saveRDS(form_panel, "../data/czso_form_panel.rds")
}

# ---------------------------------------------------------------
# 2. Broader Eurostat business statistics (all sectors, more countries)
# ---------------------------------------------------------------
cat("\n=== Fetching broader Eurostat data ===\n")

# National accounts: GDP by sector (quarterly)
cat("Fetching quarterly GDP by sector (namq_10_a10)...\n")
tryCatch({
  gdp_sector <- eurostat::get_eurostat("namq_10_a10",
    filters = list(
      geo = c("CZ", "SK", "PL", "HU", "AT"),
      nace_r2 = c("TOTAL", "A", "C", "F", "G", "H", "I", "J", "K", "L", "M_N", "M", "N"),
      na_item = "B1GQ",
      unit = "CLV10_MEUR",
      s_adj = "SCA"
    ),
    time_format = "date")
  cat("GDP by sector:", nrow(gdp_sector), "rows\n")
  saveRDS(gdp_sector, "../data/eurostat_gdp_sector.rds")
}, error = function(e) cat("GDP sector error:", e$message, "\n"))

# SBS: Enterprise counts (NACE Rev.2, all sections including non-service)
cat("\nFetching full SBS (sbs_na_ind_r2, sbs_na_1a_se_r2, sbs_na_con_r2)...\n")
for (tbl in c("sbs_na_ind_r2", "sbs_na_1a_se_r2", "sbs_na_con_r2", "sbs_na_dt_r2")) {
  tryCatch({
    d <- eurostat::get_eurostat(tbl,
      filters = list(
        geo = c("CZ", "SK", "PL", "HU", "AT"),
        indic_sb = c("V11110", "V11210", "V11920", "V16110")
      ),
      time_format = "num")
    cat(tbl, ":", nrow(d), "rows\n")
    saveRDS(d, paste0("../data/eurostat_", tbl, ".rds"))
  }, error = function(e) cat(tbl, "error:", e$message, "\n"))
}

# Business demography: births and deaths by sector
cat("\nFetching business demography (bd_9bd_sz_cl_r2)...\n")
tryCatch({
  bd <- eurostat::get_eurostat("bd_9bd_sz_cl_r2",
    filters = list(
      geo = c("CZ", "SK", "PL", "HU", "AT"),
      nace_r2 = c("I", "G", "H", "M", "C", "A", "B-S_X_O", "B-S_X_K")
    ),
    time_format = "num")
  cat("Business demography (size class):", nrow(bd), "rows\n")
  saveRDS(bd, "../data/eurostat_bd_size.rds")
}, error = function(e) cat("BD size error:", e$message, "\n"))

# ---------------------------------------------------------------
# 3. Eurostat: VAT revenue data (for compliance/revenue mechanism)
# ---------------------------------------------------------------
cat("\n=== Fetching tax revenue data ===\n")
tryCatch({
  tax <- eurostat::get_eurostat("gov_10a_taxag",
    filters = list(
      geo = c("CZ", "SK", "PL", "HU", "AT"),
      na_item = c("D211", "D2122A"),  # VAT, other taxes on products
      sector = "S13",
      unit = "MIO_EUR"
    ),
    time_format = "num")
  cat("Tax revenue:", nrow(tax), "rows\n")
  saveRDS(tax, "../data/eurostat_tax_revenue.rds")
}, error = function(e) cat("Tax revenue error:", e$message, "\n"))

cat("\n=== All data fetching complete ===\n")
cat("Files in data/:\n")
print(list.files("../data/", pattern = "\\.rds$"))
