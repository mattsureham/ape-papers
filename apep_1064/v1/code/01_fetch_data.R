## 01_fetch_data.R — Fetch data from Brazilian public APIs
## Sources: IBGE SIDRA (population, business counts, census), BCB (Pix aggregate)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Helper: Parse IBGE SIDRA response (first row = header, coded columns)
# ============================================================================
parse_sidra <- function(resp) {
  raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  as.data.table(raw[-1, ])  # Drop header row
}

# ============================================================================
# 1. IBGE SIDRA — Municipal population estimates (Table 6579, 2019-2022)
# ============================================================================
cat("=== 1. IBGE population estimates ===\n")

pop_url <- "https://apisidra.ibge.gov.br/values/t/6579/n6/all/v/9324/p/2019,2020,2021,2022"
pop_resp <- httr::GET(pop_url, httr::timeout(180))
stopifnot("IBGE population API failed" = httr::status_code(pop_resp) == 200)

pop_dt <- parse_sidra(pop_resp)
pop_dt[, muni_code := as.integer(substr(D1C, 1, 7))]
pop_dt[, year := as.integer(D3C)]
pop_dt[, population := as.numeric(gsub("[^0-9]", "", V))]
pop_dt <- pop_dt[!is.na(population) & population > 0, .(muni_code, year, population)]
pop_dt[, state_code := as.integer(substr(as.character(muni_code), 1, 2))]

cat(sprintf("Population: %d rows, %d municipalities, years %s\n",
            nrow(pop_dt), uniqueN(pop_dt$muni_code),
            paste(sort(unique(pop_dt$year)), collapse=",")))
stopifnot("Insufficient population data" = nrow(pop_dt) > 10000)
fwrite(pop_dt, file.path(data_dir, "population.csv"))

# ============================================================================
# 2. Census 2010 — Urbanization rate (treatment intensity instrument)
# ============================================================================
cat("\n=== 2. Census 2010 urbanization ===\n")

# Urban population (c1/1 = urban)
urban_resp <- httr::GET(
  "https://apisidra.ibge.gov.br/values/t/202/n6/all/v/93/p/2010/c1/1",
  httr::timeout(120)
)
stopifnot("Census urban pop failed" = httr::status_code(urban_resp) == 200)
dt_urban <- parse_sidra(urban_resp)
dt_urban[, muni_code := as.integer(substr(D1C, 1, 7))]
dt_urban[, urban_pop_2010 := as.numeric(V)]
dt_urban <- dt_urban[!is.na(urban_pop_2010), .(muni_code, urban_pop_2010)]

# Total population
total_resp <- httr::GET(
  "https://apisidra.ibge.gov.br/values/t/202/n6/all/v/93/p/2010",
  httr::timeout(120)
)
stopifnot("Census total pop failed" = httr::status_code(total_resp) == 200)
dt_total <- parse_sidra(total_resp)
dt_total[, muni_code := as.integer(substr(D1C, 1, 7))]
dt_total[, total_pop_2010 := as.numeric(V)]
dt_total <- dt_total[!is.na(total_pop_2010), .(muni_code, total_pop_2010)]

census <- merge(dt_urban, dt_total, by = "muni_code", all = TRUE)
census[, urban_share := urban_pop_2010 / total_pop_2010]
census[is.na(urban_share), urban_share := 0]

cat(sprintf("Census: %d municipalities, urbanization mean=%.3f sd=%.3f\n",
            nrow(census), mean(census$urban_share), sd(census$urban_share)))
fwrite(census, file.path(data_dir, "census_2010.csv"))

# ============================================================================
# 3. IBGE SIDRA — Business counts (CEMPRE, Table 6450, annual)
# ============================================================================
cat("\n=== 3. IBGE CEMPRE business counts ===\n")

cempre_list <- list()
for (yr in c(2018, 2019, 2020, 2021, 2022)) {
  url <- sprintf("https://apisidra.ibge.gov.br/values/t/6450/n6/all/v/9793/p/%d", yr)
  resp <- httr::GET(url, httr::timeout(180))
  code <- httr::status_code(resp)
  cat(sprintf("  CEMPRE %d: HTTP %d", yr, code))
  if (code == 200) {
    dt <- parse_sidra(resp)
    dt[, muni_code := as.integer(substr(D1C, 1, 7))]
    dt[, year := yr]
    dt[, n_businesses := as.numeric(gsub("[^0-9]", "", V))]
    dt <- dt[!is.na(n_businesses) & n_businesses > 0, .(muni_code, year, n_businesses)]
    cempre_list[[length(cempre_list) + 1]] <- dt
    cat(sprintf(" → %d munis\n", nrow(dt)))
  } else {
    cat("\n")
  }
  Sys.sleep(1)
}

if (length(cempre_list) > 0) {
  cempre_dt <- rbindlist(cempre_list)
  cat(sprintf("CEMPRE total: %d rows, %d munis, years %s\n",
              nrow(cempre_dt), uniqueN(cempre_dt$muni_code),
              paste(sort(unique(cempre_dt$year)), collapse=",")))
  fwrite(cempre_dt, file.path(data_dir, "cempre_businesses.csv"))
} else {
  stop("CEMPRE data completely unavailable")
}

# ============================================================================
# 4. IBGE SIDRA — Microenterprise counts (Table 6444 or similar)
# ============================================================================
cat("\n=== 4. IBGE microenterprise counts ===\n")

# Table 6444 with c12762/117405 (0 employees — closest MEI proxy)
micro_list <- list()
for (yr in c(2018, 2019, 2020, 2021, 2022)) {
  url <- sprintf("https://apisidra.ibge.gov.br/values/t/6444/n6/all/v/9793/p/%d/c12762/117405", yr)
  resp <- httr::GET(url, httr::timeout(180))
  code <- httr::status_code(resp)
  cat(sprintf("  Micro %d: HTTP %d", yr, code))
  if (code == 200) {
    dt <- parse_sidra(resp)
    if (nrow(dt) > 100) {
      dt[, muni_code := as.integer(substr(D1C, 1, 7))]
      dt[, year := yr]
      dt[, n_micro := as.numeric(gsub("[^0-9]", "", V))]
      dt <- dt[!is.na(n_micro) & n_micro > 0, .(muni_code, year, n_micro)]
      micro_list[[length(micro_list) + 1]] <- dt
      cat(sprintf(" → %d munis\n", nrow(dt)))
    } else {
      cat(" → too few rows\n")
    }
  } else {
    cat("\n")
  }
  Sys.sleep(1)
}

if (length(micro_list) > 0) {
  micro_dt <- rbindlist(micro_list)
  cat(sprintf("Micro total: %d rows\n", nrow(micro_dt)))
  fwrite(micro_dt, file.path(data_dir, "microenterprises.csv"))
}

# ============================================================================
# 5. IBGE SIDRA — Employed persons (CEMPRE Table 6450, personnel variable)
# ============================================================================
cat("\n=== 5. IBGE CEMPRE employment ===\n")

emp_list <- list()
for (yr in c(2018, 2019, 2020, 2021, 2022)) {
  # v/1985 = Personnel occupied (assalariado + sócio + etc.)
  url <- sprintf("https://apisidra.ibge.gov.br/values/t/6450/n6/all/v/1985/p/%d", yr)
  resp <- httr::GET(url, httr::timeout(180))
  code <- httr::status_code(resp)
  cat(sprintf("  Employment %d: HTTP %d", yr, code))
  if (code == 200) {
    dt <- parse_sidra(resp)
    dt[, muni_code := as.integer(substr(D1C, 1, 7))]
    dt[, year := yr]
    dt[, n_employed := as.numeric(gsub("[^0-9]", "", V))]
    dt <- dt[!is.na(n_employed), .(muni_code, year, n_employed)]
    emp_list[[length(emp_list) + 1]] <- dt
    cat(sprintf(" → %d munis\n", nrow(dt)))
  } else {
    cat("\n")
  }
  Sys.sleep(1)
}

if (length(emp_list) > 0) {
  emp_dt <- rbindlist(emp_list)
  fwrite(emp_dt, file.path(data_dir, "cempre_employment.csv"))
  cat(sprintf("Employment total: %d rows\n", nrow(emp_dt)))
}

# ============================================================================
# 6. BCB — Aggregate Pix time series (national, monthly)
# ============================================================================
cat("\n=== 6. BCB Pix aggregate statistics ===\n")

# Series 29649: Pix transactions quantity (monthly)
sgs_qty_url <- "https://api.bcb.gov.br/dados/serie/bcdata.sgs.29649/dados?formato=json&dataInicial=01/11/2020&dataFinal=31/12/2022"
sgs_qty_resp <- httr::GET(sgs_qty_url, httr::timeout(60))

if (httr::status_code(sgs_qty_resp) == 200) {
  qty_raw <- jsonlite::fromJSON(httr::content(sgs_qty_resp, "text", encoding = "UTF-8"))
  cat(sprintf("Pix quantity series: %d months\n", nrow(qty_raw)))
  fwrite(as.data.table(qty_raw), file.path(data_dir, "pix_aggregate_qty.csv"))
} else {
  cat(sprintf("Pix SGS quantity: HTTP %d — trying alternative series\n", httr::status_code(sgs_qty_resp)))

  # Try different series numbers
  for (series_id in c(29649, 29650, 25402, 25403, 25404)) {
    url <- sprintf("https://api.bcb.gov.br/dados/serie/bcdata.sgs.%d/dados?formato=json&dataInicial=01/01/2020&dataFinal=31/12/2022", series_id)
    resp <- httr::GET(url, httr::timeout(30))
    if (httr::status_code(resp) == 200) {
      data <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
      if (nrow(data) > 0) {
        cat(sprintf("  Series %d: %d rows, saved\n", series_id, nrow(data)))
        fwrite(as.data.table(data), file.path(data_dir, sprintf("bcb_series_%d.csv", series_id)))
      }
    }
    Sys.sleep(0.3)
  }
}

# ============================================================================
# 7. State-level GDP (Table 5938)
# ============================================================================
cat("\n=== 7. State GDP ===\n")
gdp_url <- "https://apisidra.ibge.gov.br/values/t/5938/n3/all/v/37/p/2018,2019,2020,2021,2022"
gdp_resp <- httr::GET(gdp_url, httr::timeout(120))

if (httr::status_code(gdp_resp) == 200) {
  gdp_dt <- parse_sidra(gdp_resp)
  gdp_dt[, state_code := as.integer(D1C)]
  gdp_dt[, year := as.integer(D3C)]
  gdp_dt[, gdp := as.numeric(gsub("[^0-9.]", "", V))]
  gdp_dt <- gdp_dt[!is.na(gdp), .(state_code, year, gdp)]
  cat(sprintf("State GDP: %d rows, years %s\n", nrow(gdp_dt),
              paste(sort(unique(gdp_dt$year)), collapse=",")))
  fwrite(gdp_dt, file.path(data_dir, "state_gdp.csv"))
} else {
  cat(sprintf("State GDP: HTTP %d\n", httr::status_code(gdp_resp)))
}

# ============================================================================
# Summary
# ============================================================================
cat("\n=== DATA FETCH COMPLETE ===\n")
files <- list.files(data_dir, full.names = FALSE)
cat(sprintf("Files saved (%d):\n", length(files)))
for (f in files) {
  sz <- file.size(file.path(data_dir, f))
  cat(sprintf("  %-40s %s bytes\n", f, format(sz, big.mark = ",")))
}
