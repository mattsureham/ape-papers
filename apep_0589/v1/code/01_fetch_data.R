## ============================================================
## 01_fetch_data.R — Fetch all data from Eurostat + Cohesion API
## ERDF Treatment Withdrawal RDD
## ============================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("=== FETCHING DATA ===\n\n")

## ---------------------------------------------------------
## 1. GDP per capita (PPS), % of EU27 average — tgs00006
## ---------------------------------------------------------
cat("1. Fetching GDP per capita (% EU27)...\n")
gdp_pct <- get_eurostat("tgs00006", time_format = "num")
gdp_pct <- as.data.table(gdp_pct)

# Standardize column names
if ("TIME_PERIOD" %in% names(gdp_pct)) setnames(gdp_pct, "TIME_PERIOD", "time")

# Keep only NUTS2 regions (4-character codes)
gdp_pct <- gdp_pct[nchar(geo) == 4]

cat("  GDP pct data:", nrow(gdp_pct), "obs,",
    uniqueN(gdp_pct$geo), "NUTS2 regions,",
    paste(range(gdp_pct$time, na.rm = TRUE), collapse = "-"), "\n")

fwrite(gdp_pct, paste0(data_dir, "gdp_pct_eu27.csv"))

## ---------------------------------------------------------
## 2. GDP in millions EUR — nama_10r_2gdp
## ---------------------------------------------------------
cat("2. Fetching GDP (millions EUR)...\n")
gdp_eur <- get_eurostat("nama_10r_2gdp", time_format = "num")
gdp_eur <- as.data.table(gdp_eur)
if ("TIME_PERIOD" %in% names(gdp_eur)) setnames(gdp_eur, "TIME_PERIOD", "time")

# Filter: NUTS2, MIO_EUR
gdp_eur <- gdp_eur[nchar(geo) == 4]
if ("unit" %in% names(gdp_eur)) {
  gdp_eur <- gdp_eur[unit == "MIO_EUR"]
} else if ("currency" %in% names(gdp_eur)) {
  gdp_eur <- gdp_eur[currency == "MIO_EUR"]
}

cat("  GDP EUR data:", nrow(gdp_eur), "obs,",
    uniqueN(gdp_eur$geo), "NUTS2 regions\n")

fwrite(gdp_eur, paste0(data_dir, "gdp_eur.csv"))

## ---------------------------------------------------------
## 3. Employment rate — lfst_r_lfe2emprtn
## ---------------------------------------------------------
cat("3. Fetching employment rates...\n")
emp_rate <- get_eurostat("lfst_r_lfe2emprtn", time_format = "num")
emp_rate <- as.data.table(emp_rate)
if ("TIME_PERIOD" %in% names(emp_rate)) setnames(emp_rate, "TIME_PERIOD", "time")

# NUTS2, total population (15-64), both sexes
emp_rate <- emp_rate[nchar(geo) == 4 & age == "Y15-64" & sex == "T"]

cat("  Employment rate data:", nrow(emp_rate), "obs,",
    uniqueN(emp_rate$geo), "NUTS2 regions\n")

fwrite(emp_rate, paste0(data_dir, "emp_rate.csv"))

## ---------------------------------------------------------
## 4. GVA by NACE sector — nama_10r_3gva
## ---------------------------------------------------------
cat("4. Fetching GVA by sector...\n")
gva <- get_eurostat("nama_10r_3gva", time_format = "num")
gva <- as.data.table(gva)
if ("TIME_PERIOD" %in% names(gva)) setnames(gva, "TIME_PERIOD", "time")

# NUTS2, current prices in million EUR
gva <- gva[nchar(geo) == 4 & unit == "CP_MEUR"]

cat("  GVA data:", nrow(gva), "obs,",
    uniqueN(gva$geo), "NUTS2 regions,",
    uniqueN(gva$nace_r2), "sectors\n")

fwrite(gva, paste0(data_dir, "gva_sector.csv"))

## ---------------------------------------------------------
## 5. Compensation of employees — nama_10r_2coe
## ---------------------------------------------------------
cat("5. Fetching compensation of employees...\n")
coe <- get_eurostat("nama_10r_2coe", time_format = "num")
coe <- as.data.table(coe)
if ("TIME_PERIOD" %in% names(coe)) setnames(coe, "TIME_PERIOD", "time")

# NUTS2, MIO_EUR (note: column is 'currency', not 'unit')
coe <- coe[nchar(geo) == 4 & currency == "MIO_EUR"]

cat("  Compensation data:", nrow(coe), "obs,",
    uniqueN(coe$geo), "NUTS2 regions\n")

fwrite(coe, paste0(data_dir, "compensation.csv"))

## ---------------------------------------------------------
## 6. Population — demo_r_pjanaggr3
## ---------------------------------------------------------
cat("6. Fetching population...\n")
pop <- get_eurostat("demo_r_pjanaggr3", time_format = "num")
pop <- as.data.table(pop)
if ("TIME_PERIOD" %in% names(pop)) setnames(pop, "TIME_PERIOD", "time")

# NUTS2, total population, both sexes
pop <- pop[nchar(geo) == 4 & age == "TOTAL" & sex == "T"]

cat("  Population data:", nrow(pop), "obs,",
    uniqueN(pop$geo), "NUTS2 regions\n")

fwrite(pop, paste0(data_dir, "population.csv"))

## ---------------------------------------------------------
## 7. ERDF payment data — cohesiondata.ec.europa.eu
## ---------------------------------------------------------
cat("7. Fetching ERDF payment data from cohesion API...\n")

base_url <- "https://cohesiondata.ec.europa.eu/resource/tc55-7ysv.json"
all_erdf <- list()
offset <- 0
batch_size <- 5000
repeat {
  url <- paste0(base_url,
    "?$where=fund='ERDF'",
    "&$limit=", batch_size,
    "&$offset=", offset,
    "&$order=:id")
  resp <- GET(url)
  if (status_code(resp) != 200) {
    stop("Cohesion API returned status ", status_code(resp))
  }
  batch <- fromJSON(content(resp, "text", encoding = "UTF-8"))
  if (nrow(batch) == 0) break
  all_erdf[[length(all_erdf) + 1]] <- batch
  offset <- offset + batch_size
  cat("  Fetched", offset, "records...\n")
  if (nrow(batch) < batch_size) break
  Sys.sleep(0.5)
}

erdf <- rbindlist(all_erdf, fill = TRUE)

cat("  ERDF data:", nrow(erdf), "total records,",
    uniqueN(erdf$nuts2_id), "NUTS2 regions\n")

# Convert numeric columns
num_cols <- c("eu_payment_annual", "modelled_annual_eu_payments",
              "standard_deviation", "standard_error")
for (col in intersect(num_cols, names(erdf))) {
  erdf[, (col) := as.numeric(get(col))]
}
if ("year" %in% names(erdf)) erdf[, year := as.integer(year)]

fwrite(erdf, paste0(data_dir, "erdf_payments.csv"))

## ---------------------------------------------------------
## === DATA VALIDATION (required) ===
## ---------------------------------------------------------
cat("\n=== DATA VALIDATION ===\n")

stopifnot("GDP pct: need 200+ NUTS2 regions" =
  uniqueN(gdp_pct$geo) >= 200)
stopifnot("GDP pct: need data covering 2013" =
  2013 %in% gdp_pct$time)
stopifnot("Employment: need 200+ NUTS2 regions" =
  uniqueN(emp_rate$geo) >= 200)
stopifnot("ERDF: need 100+ NUTS2 regions" =
  uniqueN(erdf$nuts2_id) >= 100)

# Check key graduating regions
key_regions <- c("PL51", "CZ03", "CZ02")
for (reg in key_regions) {
  if (!(reg %in% gdp_pct$geo)) stop("Key region ", reg, " missing from GDP data")
}

cat("\nData validation passed.\n")
cat("  GDP pct:", nrow(gdp_pct), "rows,", uniqueN(gdp_pct$geo), "regions,",
    paste(range(gdp_pct$time, na.rm = TRUE), collapse = "-"), "\n")
cat("  GDP EUR:", nrow(gdp_eur), "rows,", uniqueN(gdp_eur$geo), "regions\n")
cat("  Employment:", nrow(emp_rate), "rows,", uniqueN(emp_rate$geo), "regions\n")
cat("  GVA:", nrow(gva), "rows,", uniqueN(gva$geo), "regions\n")
cat("  Compensation:", nrow(coe), "rows,", uniqueN(coe$geo), "regions\n")
cat("  Population:", nrow(pop), "rows,", uniqueN(pop$geo), "regions\n")
cat("  ERDF:", nrow(erdf), "rows,", uniqueN(erdf$nuts2_id), "regions\n")

cat("\n=== ALL DATA FETCHED SUCCESSFULLY ===\n")
