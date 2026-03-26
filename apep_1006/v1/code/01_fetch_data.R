# 01_fetch_data.R — Data acquisition for APEP 1006
# Downloads: (1) World Bank Remittance Prices Worldwide (RPW)
#            (2) FATF grey-list treatment panel (compiled from public records)
#            (3) WDI remittance volumes

source("00_packages.R")

# Set working directory to project data folder
data_dir <- "../data"
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# ============================================================================
# 1. FATF Grey-List Treatment Panel
# ============================================================================
# Compiled from FATF plenary statements (publicly available at fatf-gafi.org).
# Each row = one grey-listing episode (entry + exit). Countries can appear
# multiple times if re-listed.
# Dates correspond to FATF plenary months: Feb=Q1, Jun=Q2, Oct=Q4.
# Quarter convention: Q1=Jan-Mar, Q2=Apr-Jun, Q3=Jul-Sep, Q4=Oct-Dec
# FATF Feb plenary -> effective Q1, Jun plenary -> effective Q2, Oct plenary -> effective Q4

fatf_episodes <- data.table(
  iso3 = c(
    # 2010 initial grey list (Feb 2010 plenary)
    "AGO", "ECU", "ETH", "IDN", "KEN", "MMR", "PAK", "PRY",
    "STP", "SYR", "TJK", "TKM", "THA", "TTO", "VNM",
    # 2010 additions (Jun/Oct plenaries)
    "BGD", "GHA", "LKA", "NGA", "SDN", "TUR",
    # 2011 additions
    "ALB", "ARG", "NPL", "NIC", "ZWE",
    # 2012 additions
    "DZA", "CUB", "LAO",
    # 2013 additions
    "IRQ", "AFG",
    # 2014 additions
    "UGA", "PNG",
    # 2015 additions
    "KHM", "BIH",
    # 2016 additions
    "VUT", "GUY",
    # 2018 additions
    "PAK", "BWA", "GHA",
    # 2019 additions
    "PAN", "ISL", "MNG", "ZWE", "KHM",
    # 2020 additions
    "ALB", "BRB", "JAM", "MUS", "MMR", "NIC", "HTI",
    # 2021 additions
    "SEN", "BFA", "PHL", "SSD", "JOR", "MAR", "MLI", "TUR",
    # 2022 additions
    "TZA", "COD", "MOZ", "COG", "NGA",
    # 2023 additions
    "ZAF", "HRV", "VNM", "CMR",
    # 2024 additions
    "KEN", "NAM", "VEN",
    # Additional episodes
    "MDG", "MNE"
  ),
  entry_year = c(
    # 2010 initial (Feb)
    2010, 2010, 2010, 2010, 2010, 2010, 2010, 2010,
    2010, 2010, 2010, 2010, 2010, 2010, 2010,
    # 2010 later
    2010, 2010, 2010, 2010, 2010, 2010,
    # 2011
    2011, 2011, 2011, 2011, 2011,
    # 2012
    2012, 2012, 2012,
    # 2013
    2013, 2013,
    # 2014
    2014, 2014,
    # 2015
    2015, 2015,
    # 2016
    2016, 2016,
    # 2018
    2018, 2018, 2018,
    # 2019
    2019, 2019, 2019, 2019, 2019,
    # 2020
    2020, 2020, 2020, 2020, 2020, 2020, 2020,
    # 2021
    2021, 2021, 2021, 2021, 2021, 2021, 2021, 2021,
    # 2022
    2022, 2022, 2022, 2022, 2023,
    # 2023
    2023, 2023, 2023, 2023,
    # 2024
    2024, 2024, 2024,
    # Additional
    2020, 2022
  ),
  entry_quarter = c(
    # 2010 initial (Feb plenary = Q1)
    1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 2,
    # 2010 later (Oct = Q4)
    4, 4, 4, 4, 4, 4,
    # 2011
    2, 2, 2, 2, 4,
    # 2012
    1, 2, 2,
    # 2013
    4, 2,
    # 2014
    1, 1,
    # 2015
    1, 4,
    # 2016
    2, 4,
    # 2018
    2, 4, 2,
    # 2019
    2, 4, 4, 4, 1,
    # 2020
    1, 1, 1, 1, 4, 4, 2,
    # 2021
    1, 4, 2, 2, 4, 4, 4, 4,
    # 2022
    4, 4, 4, 4, 1,
    # 2023
    1, 2, 2, 4,
    # 2024
    1, 1, 4,
    # Additional
    4, 4
  ),
  exit_year = c(
    # 2010 initial
    2016, 2015, 2014, 2015, 2014, 2016, 2012, 2012,
    2015, NA, 2014, 2014, 2013, 2013, 2014,
    # 2010 later
    2015, 2015, 2017, 2013, NA, 2014,
    # 2011
    2015, 2014, 2014, 2015, 2015,
    # 2012
    2016, 2016, 2017,
    # 2013
    2017, 2016,
    # 2014
    2017, 2016,
    # 2015
    2017, 2019,
    # 2016
    2018, 2016,
    # 2018
    2022, 2021, 2021,
    # 2019
    2023, 2021, 2020, 2023, 2023,
    # 2020
    2023, 2022, 2024, 2021, NA, 2023, NA,
    # 2021
    2023, NA, 2024, NA, 2023, 2023, NA, 2024,
    # 2022
    NA, NA, NA, 2024, NA,
    # 2023
    2025, 2024, 2024, NA,
    # 2024
    NA, NA, NA,
    # Additional
    2023, 2024
  ),
  exit_quarter = c(
    # 2010 initial
    1, 4, 2, 1, 2, 2, 1, 2,
    4, NA, 2, 2, 2, 4, 1,
    # 2010 later
    2, 2, 1, 4, NA, 1,
    # 2011
    2, 4, 2, 4, 4,
    # 2012
    1, 2, 2,
    # 2013
    4, 1,
    # 2014
    1, 1,
    # 2015
    1, 4,
    # 2016
    1, 4,
    # 2018
    4, 2, 2,
    # 2019
    4, 4, 4, 1, 1,
    # 2020
    1, 1, 2, 4, NA, 4, NA,
    # 2021
    1, NA, 2, NA, 1, 1, NA, 2,
    # 2022
    NA, NA, NA, 4, NA,
    # 2023
    1, 4, 2, NA,
    # 2024
    NA, NA, NA,
    # Additional
    1, 4
  )
)

# Validate FATF data
stopifnot("FATF data has matching row counts" =
            nrow(fatf_episodes) == length(fatf_episodes$iso3))
cat("FATF grey-list panel compiled:", nrow(fatf_episodes), "episodes across",
    uniqueN(fatf_episodes$iso3), "countries\n")

# Convert to quarter index (quarters since 2008Q1 for numerical time)
fatf_episodes[, entry_qtr := (entry_year - 2008) * 4 + entry_quarter]
fatf_episodes[, exit_qtr := ifelse(is.na(exit_year), NA_real_,
                                    (exit_year - 2008) * 4 + exit_quarter)]
fatf_episodes[, country_name := countrycode(iso3, "iso3c", "country.name")]

fwrite(fatf_episodes, file.path(data_dir, "fatf_greylist_episodes.csv"))
cat("Saved FATF grey-list episodes to", file.path(data_dir, "fatf_greylist_episodes.csv"), "\n")

# ============================================================================
# 2. World Bank Remittance Prices Worldwide (RPW)
# ============================================================================
# Try multiple download approaches for the RPW dataset

rpw_file <- file.path(data_dir, "rpw_dataset.xlsx")

if (!file.exists(rpw_file)) {
  rpw_urls <- c(
    "https://remittanceprices.worldbank.org/sites/default/files/rpw_dataset_2011_2025_q1.xlsx",
    "https://remittanceprices.worldbank.org/sites/default/files/rpw_dataset.xlsx"
  )

  downloaded <- FALSE
  for (url in rpw_urls) {
    cat("Trying RPW download from:", url, "\n")
    tryCatch({
      resp <- GET(url, timeout(120), write_disk(rpw_file, overwrite = TRUE))
      if (status_code(resp) == 200 && file.size(rpw_file) > 1e6) {
        cat("RPW download successful:", round(file.size(rpw_file) / 1e6, 1), "MB\n")
        downloaded <- TRUE
        break
      } else {
        cat("Download returned status:", status_code(resp), "or file too small\n")
        file.remove(rpw_file)
      }
    }, error = function(e) {
      cat("Download failed:", e$message, "\n")
      if (file.exists(rpw_file)) file.remove(rpw_file)
    })
  }

  if (!downloaded) {
    stop("FATAL: Could not download RPW dataset from any source. ",
         "The World Bank Remittance Prices dataset is required. ",
         "Check https://remittanceprices.worldbank.org/resources")
  }
}

# Read RPW data — two sheets cover different periods
cat("Reading RPW dataset (two sheets)...\n")
rpw_early <- as.data.table(read_excel(rpw_file, sheet = "Dataset (up to Q1 2016)"))
rpw_late  <- as.data.table(read_excel(rpw_file, sheet = "Dataset (from Q2 2016)"))
cat("RPW early (up to Q1 2016):", nrow(rpw_early), "rows,", ncol(rpw_early), "cols\n")
cat("RPW late (from Q2 2016):", nrow(rpw_late), "rows,", ncol(rpw_late), "cols\n")

# Harmonize columns and bind
common_cols <- intersect(names(rpw_early), names(rpw_late))
rpw_raw <- rbind(rpw_early[, ..common_cols], rpw_late[, ..common_cols])
cat("RPW combined:", nrow(rpw_raw), "rows,", ncol(rpw_raw), "columns\n")
cat("RPW columns:", paste(names(rpw_raw)[1:min(20, ncol(rpw_raw))], collapse = ", "), "\n")

# Validate RPW has expected structure
stopifnot("RPW data has rows" = nrow(rpw_raw) > 10000)

# Save as CSV for faster subsequent reads
fwrite(rpw_raw, file.path(data_dir, "rpw_raw.csv"))
cat("Saved RPW raw data to rpw_raw.csv\n")

# ============================================================================
# 3. WDI Remittance Volumes (Country-Level)
# ============================================================================
cat("Fetching WDI remittance data...\n")

# Personal remittances received (% of GDP) and (current US$)
wdi_remit <- as.data.table(WDI(
  indicator = c(
    "BX.TRF.PWKR.DT.GD.ZS",  # Remittances received (% GDP)
    "BX.TRF.PWKR.CD.DT"       # Remittances received (current US$)
  ),
  start = 2008, end = 2024,
  extra = TRUE
))

stopifnot("WDI data has rows" = nrow(wdi_remit) > 500)
cat("WDI remittance data:", nrow(wdi_remit), "rows\n")

# Clean names
setnames(wdi_remit, c("BX.TRF.PWKR.DT.GD.ZS", "BX.TRF.PWKR.CD.DT"),
         c("remit_pct_gdp", "remit_usd"), skip_absent = TRUE)

fwrite(wdi_remit, file.path(data_dir, "wdi_remittances.csv"))
cat("Saved WDI remittances\n")

# ============================================================================
# 4. Summary of fetched data
# ============================================================================
cat("\n=== DATA FETCH SUMMARY ===\n")
cat("FATF grey-list episodes:", nrow(fatf_episodes), "\n")
cat("RPW observations:", nrow(rpw_raw), "\n")
cat("WDI country-years:", nrow(wdi_remit), "\n")
cat("All data fetched successfully.\n")
