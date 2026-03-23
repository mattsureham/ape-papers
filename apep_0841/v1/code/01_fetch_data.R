## 01_fetch_data.R — Fetch Eurostat data for Poland 500+ analysis
## apep_0841

source("00_packages.R")

cat("=== Fetching Eurostat data ===\n")

# CEE countries: Poland (PL), Czech Republic (CZ), Slovakia (SK),
#                Hungary (HU), Romania (RO), Bulgaria (BG)
cee_countries <- c("PL", "CZ", "SK", "HU", "RO", "BG")

# ─── 1. Employment rates by sex, age, NUTS2 ─────────────────────────────────
cat("Fetching employment rates (lfst_r_lfe2emprt)...\n")
emp_raw <- get_eurostat("lfst_r_lfe2emprt", time_format = "num")
stopifnot("Failed to fetch employment data" = nrow(emp_raw) > 0)
cat(sprintf("  Retrieved %d rows\n", nrow(emp_raw)))
cat(sprintf("  Columns: %s\n", paste(names(emp_raw), collapse = ", ")))

# Filter: females, age 25-64 (prime working age), years 2010-2023
emp <- emp_raw[emp_raw$sex == "F" &
               emp_raw$age == "Y25-64" &
               emp_raw$TIME_PERIOD >= 2010 &
               emp_raw$TIME_PERIOD <= 2023, ]

# Keep NUTS2 regions for CEE countries (4-char codes)
emp$country <- substr(emp$geo, 1, 2)
emp <- emp[emp$country %in% cee_countries & nchar(emp$geo) == 4, ]
emp <- emp[, c("geo", "TIME_PERIOD", "values")]
names(emp) <- c("nuts2", "year", "emp_rate_f")

stopifnot("No Polish NUTS2 regions found" = any(substr(emp$nuts2, 1, 2) == "PL"))
cat(sprintf("  Female employment (Y25-64): %d obs, %d regions, years %d-%d\n",
            nrow(emp), length(unique(emp$nuts2)),
            min(emp$year), max(emp$year)))
cat(sprintf("  Polish regions: %s\n",
            paste(sort(unique(emp$nuts2[substr(emp$nuts2, 1, 2) == "PL"])), collapse = ", ")))

# Also get Y25-34 for heterogeneity (young mothers)
emp_young <- emp_raw[emp_raw$sex == "F" &
                     emp_raw$age == "Y25-34" &
                     emp_raw$TIME_PERIOD >= 2010 &
                     emp_raw$TIME_PERIOD <= 2023, ]
emp_young$country <- substr(emp_young$geo, 1, 2)
emp_young <- emp_young[emp_young$country %in% cee_countries & nchar(emp_young$geo) == 4, ]
emp_young <- emp_young[, c("geo", "TIME_PERIOD", "values")]
names(emp_young) <- c("nuts2", "year", "emp_rate_f_young")

# ─── 2. Male employment rates (placebo outcome) ─────────────────────────────
cat("Fetching male employment rates (placebo)...\n")
emp_m <- emp_raw[emp_raw$sex == "M" &
                 emp_raw$age == "Y25-64" &
                 emp_raw$TIME_PERIOD >= 2010 &
                 emp_raw$TIME_PERIOD <= 2023, ]
emp_m$country <- substr(emp_m$geo, 1, 2)
emp_m <- emp_m[emp_m$country %in% cee_countries & nchar(emp_m$geo) == 4, ]
emp_m <- emp_m[, c("geo", "TIME_PERIOD", "values")]
names(emp_m) <- c("nuts2", "year", "emp_rate_m")
cat(sprintf("  Male employment data: %d obs\n", nrow(emp_m)))

# ─── 3. Total fertility rate by NUTS2 ───────────────────────────────────────
cat("Fetching fertility rates (demo_r_frate2)...\n")
fert_raw <- get_eurostat("demo_r_frate2", time_format = "num")

if (is.null(fert_raw) || nrow(fert_raw) == 0) {
  cat("  demo_r_frate2 returned 0 rows, trying demo_r_frate3...\n")
  fert_raw <- get_eurostat("demo_r_frate3", time_format = "num")
}

stopifnot("Failed to fetch fertility data" = !is.null(fert_raw) && nrow(fert_raw) > 0)
cat(sprintf("  Retrieved %d rows of fertility data\n", nrow(fert_raw)))
cat(sprintf("  Columns: %s\n", paste(names(fert_raw), collapse = ", ")))

# Get total fertility rate
fert_raw$country <- substr(fert_raw$geo, 1, 2)
fert <- fert_raw[fert_raw$country %in% cee_countries & nchar(fert_raw$geo) == 4, ]

# Check what indicators are available
if ("indic_de" %in% names(fert)) {
  cat(sprintf("  Fertility indicators: %s\n",
              paste(unique(fert$indic_de), collapse = ", ")))
  if ("TOTFERRT" %in% fert$indic_de) {
    fert <- fert[fert$indic_de == "TOTFERRT", ]
  }
}

# Use TIME_PERIOD if that's the column name
time_col <- intersect(c("TIME_PERIOD", "time"), names(fert))
if (length(time_col) > 0) {
  fert <- fert[, c("geo", time_col[1], "values")]
  names(fert) <- c("nuts2", "year", "tfr")
} else {
  stop("Cannot find time column in fertility data")
}

cat(sprintf("  Fertility data: %d obs, %d regions\n",
            nrow(fert), length(unique(fert$nuts2))))

# ─── 4. Regional GDP per capita ─────────────────────────────────────────────
cat("Fetching regional GDP (nama_10r_2gdp)...\n")
gdp_raw <- get_eurostat("nama_10r_2gdp", time_format = "num")

if (!is.null(gdp_raw) && nrow(gdp_raw) > 0) {
  gdp_raw$country <- substr(gdp_raw$geo, 1, 2)
  time_col_gdp <- intersect(c("TIME_PERIOD", "time"), names(gdp_raw))
  gdp <- gdp_raw[gdp_raw$country %in% cee_countries &
                  nchar(gdp_raw$geo) == 4 &
                  gdp_raw$unit == "EUR_HAB", ]
  gdp <- gdp[, c("geo", time_col_gdp[1], "values")]
  names(gdp) <- c("nuts2", "year", "gdp_pc")
  cat(sprintf("  GDP data: %d obs\n", nrow(gdp)))
} else {
  cat("  WARNING: GDP data not available, will proceed without.\n")
  gdp <- data.frame(nuts2 = character(), year = numeric(), gdp_pc = numeric())
}

# ─── 5. Population by NUTS2 ─────────────────────────────────────────────────
cat("Fetching population (demo_r_pjangrp3)...\n")
pop_raw <- get_eurostat("demo_r_pjangrp3", time_format = "num")

if (!is.null(pop_raw) && nrow(pop_raw) > 0) {
  pop_raw$country <- substr(pop_raw$geo, 1, 2)
  time_col_pop <- intersect(c("TIME_PERIOD", "time"), names(pop_raw))
  pop <- pop_raw[pop_raw$country %in% cee_countries &
                 nchar(pop_raw$geo) == 4 &
                 pop_raw$sex == "T" &
                 pop_raw$age == "TOTAL", ]
  if (length(time_col_pop) > 0) {
    pop <- pop[pop[[time_col_pop[1]]] >= 2010, ]
    pop <- pop[, c("geo", time_col_pop[1], "values")]
    names(pop) <- c("nuts2", "year", "population")
  }
  cat(sprintf("  Population data: %d obs\n", nrow(pop)))
} else {
  cat("  WARNING: Population data not available.\n")
  pop <- data.frame(nuts2 = character(), year = numeric(), population = numeric())
}

# ─── Save all fetched data ──────────────────────────────────────────────────
saveRDS(emp, "../data/employment_f.rds")
saveRDS(emp_young, "../data/employment_f_young.rds")
saveRDS(emp_m, "../data/employment_m.rds")
saveRDS(fert, "../data/fertility.rds")
saveRDS(gdp, "../data/gdp.rds")
saveRDS(pop, "../data/population.rds")

cat("\n=== All data saved to data/ ===\n")
cat(sprintf("Female employment (Y25-64): %d obs across %d NUTS2 regions\n",
            nrow(emp), length(unique(emp$nuts2))))
cat(sprintf("Female employment (Y25-34): %d obs\n", nrow(emp_young)))
cat(sprintf("Male employment: %d obs\n", nrow(emp_m)))
cat(sprintf("Fertility: %d obs\n", nrow(fert)))
cat(sprintf("GDP: %d obs\n", nrow(gdp)))
cat(sprintf("Population: %d obs\n", nrow(pop)))
