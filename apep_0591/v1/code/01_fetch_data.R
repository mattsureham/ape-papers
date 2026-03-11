# =============================================================================
# 01_fetch_data.R — Fetch Erasmus flows + Eurostat outcomes
# APEP-0591: The Erasmus Drain
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------
# 1. Erasmus aggregate NUTS flows (Zenodo)
# ---------------------------------------------------------------
erasmus_file <- file.path(data_dir, "Erasmus_2014-2023_aggregate_NUTS.csv")

if (!file.exists(erasmus_file)) {
  cat("Downloading Erasmus aggregate NUTS flows from Zenodo...\n")
  tryCatch({
    download.file(
      url = "https://zenodo.org/api/records/16737523/files/Erasmus_2014-2023_aggregate_NUTS.csv/content",
      destfile = erasmus_file,
      mode = "wb",
      quiet = FALSE
    )
  }, error = function(e) {
    stop("Failed to download Erasmus data from Zenodo: ", e$message,
         "\nCheck network connectivity and Zenodo availability.")
  })
}

erasmus_nuts <- fread(erasmus_file)
# Standardize column names to lowercase
setnames(erasmus_nuts, tolower(names(erasmus_nuts)))
cat("Erasmus NUTS flows loaded:", nrow(erasmus_nuts), "rows\n")
cat("  Columns:", names(erasmus_nuts), "\n")
cat("  Years:", sort(unique(erasmus_nuts$year)), "\n")
cat("  Sample origins:", head(unique(erasmus_nuts$origin), 5), "\n")
cat("  Sample destinations:", head(unique(erasmus_nuts$destination), 5), "\n")

# ---------------------------------------------------------------
# 2. Eurostat outcomes at NUTS2
# ---------------------------------------------------------------

# 2a. Tertiary education attainment by age (edat_lfse_04)
cat("Fetching Eurostat: edat_lfse_04 (tertiary education share)...\n")
tryCatch({
  educ_raw <- get_eurostat("edat_lfse_04", time_format = "num")
  educ <- as.data.table(educ_raw)
  cat("  edat_lfse_04:", nrow(educ), "rows\n")
}, error = function(e) {
  stop("Failed to fetch edat_lfse_04 from Eurostat: ", e$message)
})

# 2b. Employment by age (lfst_r_lfe2emp)
cat("Fetching Eurostat: lfst_r_lfe2emp (employment)...\n")
tryCatch({
  emp_raw <- get_eurostat("lfst_r_lfe2emp", time_format = "num")
  emp <- as.data.table(emp_raw)
  cat("  lfst_r_lfe2emp:", nrow(emp), "rows\n")
}, error = function(e) {
  stop("Failed to fetch lfst_r_lfe2emp from Eurostat: ", e$message)
})

# 2c. Activity rate / LFP (lfst_r_lfp2act)
cat("Fetching Eurostat: lfst_r_lfp2act (labor force participation)...\n")
tryCatch({
  lfp_raw <- get_eurostat("lfst_r_lfp2act", time_format = "num")
  lfp <- as.data.table(lfp_raw)
  cat("  lfst_r_lfp2act:", nrow(lfp), "rows\n")
}, error = function(e) {
  stop("Failed to fetch lfst_r_lfp2act from Eurostat: ", e$message)
})

# 2d. GDP per capita at NUTS2 (nama_10r_2gdp) — for controls and heterogeneity
cat("Fetching Eurostat: nama_10r_2gdp (GDP)...\n")
tryCatch({
  gdp_raw <- get_eurostat("nama_10r_2gdp", time_format = "num")
  gdp <- as.data.table(gdp_raw)
  cat("  nama_10r_2gdp:", nrow(gdp), "rows\n")
}, error = function(e) {
  stop("Failed to fetch nama_10r_2gdp from Eurostat: ", e$message)
})

# 2e. Population at NUTS2 (demo_r_pjangrp3) — for scaling
cat("Fetching Eurostat: demo_r_pjangrp3 (population by age)...\n")
tryCatch({
  pop_raw <- get_eurostat("demo_r_pjangrp3", time_format = "num")
  pop <- as.data.table(pop_raw)
  cat("  demo_r_pjangrp3:", nrow(pop), "rows\n")
}, error = function(e) {
  # Try alternative population dataset
  cat("  Trying alternative: demo_r_pjanaggr3...\n")
  tryCatch({
    pop_raw <- get_eurostat("demo_r_pjanaggr3", time_format = "num")
    pop <- as.data.table(pop_raw)
    cat("  demo_r_pjanaggr3:", nrow(pop), "rows\n")
  }, error = function(e2) {
    stop("Failed to fetch population data from Eurostat: ", e2$message)
  })
})

# ---------------------------------------------------------------
# 3. Save raw data
# ---------------------------------------------------------------
fwrite(educ, file.path(data_dir, "eurostat_edat_lfse_04.csv"))
fwrite(emp, file.path(data_dir, "eurostat_lfst_r_lfe2emp.csv"))
fwrite(lfp, file.path(data_dir, "eurostat_lfst_r_lfp2act.csv"))
fwrite(gdp, file.path(data_dir, "eurostat_nama_10r_2gdp.csv"))
fwrite(pop, file.path(data_dir, "eurostat_population.csv"))

cat("\nAll raw data saved to", data_dir, "\n")

# ---------------------------------------------------------------
# 4. Data validation
# ---------------------------------------------------------------
stopifnot("Erasmus data has >100k rows" = nrow(erasmus_nuts) > 100000)
stopifnot("Erasmus covers 2014-2022" = all(2014:2022 %in% erasmus_nuts$year))
stopifnot("Education data has rows" = nrow(educ) > 1000)
stopifnot("Employment data has rows" = nrow(emp) > 1000)
stopifnot("LFP data has rows" = nrow(lfp) > 1000)
stopifnot("GDP data has rows" = nrow(gdp) > 1000)
stopifnot("Population data has rows" = nrow(pop) > 1000)

cat("\n=== DATA VALIDATION PASSED ===\n")
cat("Erasmus flows:", nrow(erasmus_nuts), "rows,",
    length(unique(erasmus_nuts$Year)), "years\n")
cat("Eurostat datasets: educ=", nrow(educ), "emp=", nrow(emp),
    "lfp=", nrow(lfp), "gdp=", nrow(gdp), "pop=", nrow(pop), "\n")
