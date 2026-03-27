# 01_fetch_data.R — Fetch all data for apep_1061
# Polish abortion ruling border-distance DiD

source("00_packages.R")

cat("=== Fetching Eurostat NUTS2 fertility data ===\n")

# ---------------------------------------------------------------
# 1. NUTS2 Total Fertility Rate (demo_r_find2)
# ---------------------------------------------------------------
tfr_raw <- get_eurostat("demo_r_find2", time_format = "num")

if (is.null(tfr_raw) || nrow(tfr_raw) == 0) {
  stop("FATAL: Eurostat demo_r_find2 returned no data. Cannot proceed.")
}

cat("Columns:", paste(names(tfr_raw), collapse = ", "), "\n")

# Filter to Poland (PL), total fertility rate
tfr_pl <- tfr_raw[grepl("^PL", tfr_raw$geo) & tfr_raw$indic_de == "TOTFERRT", ]
tfr_pl <- tfr_pl[!is.na(tfr_pl$values), ]

# Keep only NUTS2 level (4-character codes: PLxx)
tfr_pl$nuts_level <- nchar(as.character(tfr_pl$geo))
tfr_nuts2 <- tfr_pl[tfr_pl$nuts_level == 4, ]

# Rename for clarity — use TIME_PERIOD (eurostat pkg convention)
tfr_nuts2 <- data.frame(
  geo = as.character(tfr_nuts2$geo),
  year = as.numeric(tfr_nuts2$TIME_PERIOD),
  tfr = as.numeric(tfr_nuts2$values)
)

# Filter to 2013-2023 (extended pre-period for robustness)
tfr_nuts2 <- tfr_nuts2[tfr_nuts2$year >= 2013 & tfr_nuts2$year <= 2023, ]

cat(sprintf("NUTS2 TFR: %d observations, %d regions, years %d-%d\n",
            nrow(tfr_nuts2), length(unique(tfr_nuts2$geo)),
            min(tfr_nuts2$year), max(tfr_nuts2$year)))

# Validate: must have all 17 Polish voivodships
stopifnot(length(unique(tfr_nuts2$geo)) >= 16)
cat("Polish NUTS2 regions:", paste(sort(unique(tfr_nuts2$geo)), collapse = ", "), "\n")

# ---------------------------------------------------------------
# 2. NUTS3 Live Births (demo_r_gind3) for larger sample
# ---------------------------------------------------------------
cat("\n=== Fetching Eurostat NUTS3 live births data ===\n")

gind3_raw <- get_eurostat("demo_r_gind3", time_format = "num")

if (!is.null(gind3_raw) && nrow(gind3_raw) > 0) {
  # Live births (GBIRTHRT = crude birth rate, LIVBIRTH = live births count)
  births_pl <- gind3_raw[grepl("^PL", gind3_raw$geo) & gind3_raw$indic_de == "GBIRTHRT", ]
  births_pl <- births_pl[!is.na(births_pl$values), ]

  # NUTS3 = 5-character codes (PLxxx)
  births_pl$nuts_level <- nchar(as.character(births_pl$geo))
  births_nuts3 <- births_pl[births_pl$nuts_level == 5, ]

  births_nuts3 <- data.frame(
    geo = as.character(births_nuts3$geo),
    year = as.numeric(births_nuts3$TIME_PERIOD),
    cbr = as.numeric(births_nuts3$values)  # crude birth rate per 1000
  )

  births_nuts3 <- births_nuts3[births_nuts3$year >= 2013 & births_nuts3$year <= 2023, ]

  cat(sprintf("NUTS3 CBR: %d observations, %d regions, years %d-%d\n",
              nrow(births_nuts3), length(unique(births_nuts3$geo)),
              min(births_nuts3$year), max(births_nuts3$year)))
} else {
  cat("WARNING: NUTS3 birth data not available, will use NUTS2 only\n")
  births_nuts3 <- NULL
}

# ---------------------------------------------------------------
# 3. Regional controls: GDP per capita, unemployment
# ---------------------------------------------------------------
cat("\n=== Fetching regional GDP per capita ===\n")

gdp_raw <- get_eurostat("nama_10r_2gdp", time_format = "num")
if (!is.null(gdp_raw) && nrow(gdp_raw) > 0) {
  gdp_pl <- gdp_raw[grepl("^PL", gdp_raw$geo) & gdp_raw$unit == "EUR_HAB", ]
  gdp_pl <- gdp_pl[nchar(as.character(gdp_pl$geo)) == 4, ]  # NUTS2
  gdp_pl <- data.frame(
    geo = as.character(gdp_pl$geo),
    year = as.numeric(gdp_pl$TIME_PERIOD),
    gdp_pc = as.numeric(gdp_pl$values)
  )
  gdp_pl <- gdp_pl[gdp_pl$year >= 2013 & gdp_pl$year <= 2023 & !is.na(gdp_pl$gdp_pc), ]
  cat(sprintf("GDP per capita: %d observations\n", nrow(gdp_pl)))
} else {
  cat("WARNING: GDP data not available\n")
  gdp_pl <- NULL
}

cat("\n=== Fetching regional unemployment rate ===\n")
unemp_raw <- get_eurostat("lfst_r_lfu3rt", time_format = "num")
if (!is.null(unemp_raw) && nrow(unemp_raw) > 0) {
  unemp_pl <- unemp_raw[grepl("^PL", unemp_raw$geo) &
                          unemp_raw$sex == "T" &
                          unemp_raw$age == "Y15-74" &
                          unemp_raw$isced11 == "TOTAL", ]
  unemp_pl <- unemp_pl[nchar(as.character(unemp_pl$geo)) == 4, ]
  unemp_pl <- data.frame(
    geo = as.character(unemp_pl$geo),
    year = as.numeric(unemp_pl$TIME_PERIOD),
    unemp_rate = as.numeric(unemp_pl$values)
  )
  unemp_pl <- unemp_pl[unemp_pl$year >= 2013 & unemp_pl$year <= 2023 & !is.na(unemp_pl$unemp_rate), ]
  cat(sprintf("Unemployment: %d observations\n", nrow(unemp_pl)))
} else {
  cat("WARNING: Unemployment data not available\n")
  unemp_pl <- NULL
}

# ---------------------------------------------------------------
# 4. NUTS2 Population (for weighting)
# ---------------------------------------------------------------
cat("\n=== Fetching NUTS2 population ===\n")
pop_raw <- get_eurostat("demo_r_pjangrp3", time_format = "num")
if (!is.null(pop_raw) && nrow(pop_raw) > 0) {
  pop_pl <- pop_raw[grepl("^PL", pop_raw$geo) &
                     pop_raw$sex == "T" &
                     pop_raw$age == "TOTAL", ]
  pop_pl <- pop_pl[nchar(as.character(pop_pl$geo)) == 4, ]
  pop_pl <- data.frame(
    geo = as.character(pop_pl$geo),
    year = as.numeric(pop_pl$TIME_PERIOD),
    population = as.numeric(pop_pl$values)
  )
  pop_pl <- pop_pl[pop_pl$year >= 2013 & pop_pl$year <= 2023 & !is.na(pop_pl$population), ]
  cat(sprintf("Population: %d observations\n", nrow(pop_pl)))
} else {
  cat("WARNING: Population data not available\n")
  pop_pl <- NULL
}

# ---------------------------------------------------------------
# 5. Save raw data
# ---------------------------------------------------------------
saveRDS(tfr_nuts2, "../data/tfr_nuts2.rds")
if (!is.null(births_nuts3)) saveRDS(births_nuts3, "../data/births_nuts3.rds")
if (!is.null(gdp_pl)) saveRDS(gdp_pl, "../data/gdp_nuts2.rds")
if (!is.null(unemp_pl)) saveRDS(unemp_pl, "../data/unemp_nuts2.rds")
if (!is.null(pop_pl)) saveRDS(pop_pl, "../data/pop_nuts2.rds")

cat("\n=== All data saved to ../data/ ===\n")
cat("Datasets:\n")
cat(sprintf("  tfr_nuts2.rds: %d obs\n", nrow(tfr_nuts2)))
if (!is.null(births_nuts3)) cat(sprintf("  births_nuts3.rds: %d obs\n", nrow(births_nuts3)))
if (!is.null(gdp_pl)) cat(sprintf("  gdp_nuts2.rds: %d obs\n", nrow(gdp_pl)))
if (!is.null(unemp_pl)) cat(sprintf("  unemp_nuts2.rds: %d obs\n", nrow(unemp_pl)))
if (!is.null(pop_pl)) cat(sprintf("  pop_nuts2.rds: %d obs\n", nrow(pop_pl)))
