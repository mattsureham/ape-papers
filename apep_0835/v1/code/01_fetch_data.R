# 01_fetch_data.R — Fetch Eurostat SBS data for Greece
# apep_0835: Greece POS Terminal Mandates

source("00_packages.R")

cat("=== Fetching Eurostat Structural Business Statistics ===\n")

# -------------------------------------------------------------------
# 1a. National-level SBS for industry sectors (B-E)
#     Dataset: sbs_na_ind_r2
# -------------------------------------------------------------------

cat("--- Fetching national SBS (industry, B-E) ---\n")
sbs_ind <- tryCatch(
  get_eurostat("sbs_na_ind_r2", time_format = "num", filters = list(
    geo = "EL",
    indic_sb = c("V11110", "V16110", "V13310"),
    nace_r2 = c("B", "C", "D", "E")
  )),
  error = function(e) {
    stop("FATAL: Eurostat SBS industry fetch failed: ", e$message)
  }
)

if (is.null(sbs_ind) || nrow(sbs_ind) == 0) {
  stop("FATAL: SBS industry returned zero rows.")
}
cat(sprintf("SBS industry: %d rows\n", nrow(sbs_ind)))

# -------------------------------------------------------------------
# 1b. National-level SBS for trade sector (G)
#     Dataset: sbs_na_dt_r2 (distributive trades)
# -------------------------------------------------------------------

cat("--- Fetching national SBS (trade, G) ---\n")
sbs_trade <- tryCatch(
  get_eurostat("sbs_na_dt_r2", time_format = "num", filters = list(
    geo = "EL",
    indic_sb = c("V11110", "V16110", "V13310"),
    nace_r2 = "G"
  )),
  error = function(e) {
    stop("FATAL: Eurostat SBS trade fetch failed: ", e$message)
  }
)
cat(sprintf("SBS trade (G): %d rows\n", nrow(sbs_trade)))

# -------------------------------------------------------------------
# 1c. National-level SBS for services sectors (H-S)
#     Dataset: sbs_na_1a_se_r2
# -------------------------------------------------------------------

cat("--- Fetching national SBS (services, H-S) ---\n")
sbs_srv <- tryCatch(
  get_eurostat("sbs_na_1a_se_r2", time_format = "num", filters = list(
    geo = "EL",
    indic_sb = c("V11110", "V16110", "V13310"),
    nace_r2 = c("H", "I", "J", "L", "M", "N", "S95")
  )),
  error = function(e) {
    stop("FATAL: Eurostat SBS services fetch failed: ", e$message)
  }
)

if (is.null(sbs_srv) || nrow(sbs_srv) == 0) {
  stop("FATAL: SBS services returned zero rows.")
}
cat(sprintf("SBS services: %d rows\n", nrow(sbs_srv)))

# -------------------------------------------------------------------
# 2. Combine industry + services into one national panel
# -------------------------------------------------------------------

sbs_raw <- rbind(
  as.data.table(sbs_ind),
  as.data.table(sbs_trade),
  as.data.table(sbs_srv),
  fill = TRUE
)

cat(sprintf("Combined SBS: %d rows\n", nrow(sbs_raw)))
fwrite(sbs_raw, "../data/sbs_raw.csv")

# -------------------------------------------------------------------
# 3. Regional-level SBS (employment only, for regional heterogeneity)
#    Dataset: sbs_r_nuts06_r2
# -------------------------------------------------------------------

cat("--- Fetching regional SBS (employment) ---\n")
sbs_reg <- tryCatch(
  get_eurostat("sbs_r_nuts06_r2", time_format = "num", filters = list(
    geo = c("EL30", "EL41", "EL42", "EL43", "EL51", "EL52", "EL53",
            "EL54", "EL61", "EL62", "EL63", "EL64", "EL65"),
    indic_sb = "V16110",
    nace_r2 = c("B", "C", "D", "E", "F", "G", "H", "I", "J", "L", "M", "N")
  )),
  error = function(e) {
    cat("WARNING: Regional SBS failed:", e$message, "\n")
    NULL
  }
)

if (!is.null(sbs_reg) && nrow(sbs_reg) > 0) {
  cat(sprintf("Regional SBS: %d rows\n", nrow(sbs_reg)))
  fwrite(as.data.table(sbs_reg), "../data/sbs_regional.csv")
} else {
  cat("Regional SBS not available.\n")
}

# -------------------------------------------------------------------
# 4. VAT revenue for aggregate validation
# -------------------------------------------------------------------

cat("--- Fetching VAT revenue ---\n")
vat_raw <- tryCatch(
  get_eurostat("gov_10a_taxag", time_format = "num", filters = list(
    geo = c("EL", "ES", "IT", "PT", "DE", "FR"),
    na_item = "D211",
    sector = "S13",
    unit = "MIO_EUR"
  )),
  error = function(e) {
    cat("WARNING: VAT fetch failed:", e$message, "\n")
    NULL
  }
)

if (!is.null(vat_raw) && nrow(vat_raw) > 0) {
  cat(sprintf("VAT: %d rows\n", nrow(vat_raw)))
  fwrite(as.data.table(vat_raw), "../data/vat_raw.csv")
}

cat("\n=== Data fetch complete ===\n")
