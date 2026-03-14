## 01_fetch_data.R — Fetch MHCLG planning data and construct treatment variable
## Paper: apep_0687 — Nutrient Neutrality and Housing Supply
## Data: MHCLG PS1 Planning Application Statistics (quarterly by LA)
##        MHCLG Live Table 122 (annual net additional dwellings by LA)

source("00_packages.R")

# ============================================================
# 1. NUTRIENT NEUTRALITY TREATED LPAs
# ============================================================
# Source: Natural England guidance documents
# Wave 1 (2019): Solent, Somerset Levels, Stodmarsh (Kent)
# Wave 2 (March 2022): Broads, Teesmouth, Humber, etc.

# Wave 1 LPAs (received nutrient neutrality advice in 2019)
# Solent catchment, Somerset Levels & Moors, Stodmarsh (Kent)
wave1_lpas <- c(
  # Solent catchment (Hampshire/IoW/Dorset/Wiltshire/West Sussex)
  "Basingstoke and Deane", "East Hampshire", "Eastleigh", "Fareham",
  "Gosport", "Hart", "Havant", "Isle of Wight", "New Forest",
  "Portsmouth", "Rushmoor", "Southampton", "South Downs",
  "Test Valley", "Winchester",
  # Wiltshire (Solent connection)
  "Wiltshire",
  # West Sussex (Solent connection)
  "Chichester",
  # Dorset (Solent connection via Poole Harbour)
  "Bournemouth, Christchurch and Poole", "Dorset",
  # Somerset Levels & Moors
  "Mendip", "Sedgemoor", "Somerset West and Taunton", "South Somerset",
  # Stodmarsh (Kent)
  "Ashford", "Canterbury", "Dover", "Folkestone and Hythe",
  "Maidstone", "Swale", "Thanet"
)
# Note: Some sources list 32 LPAs but boundary changes mean some are merged.
# We use the names as they appear in MHCLG data.

# Wave 2 LPAs (received nutrient neutrality advice March 2022)
# Broads, Teesmouth & Cleveland Coast, Humber Estuary, etc.
wave2_lpas <- c(
  # Teesmouth & Cleveland Coast
  "Darlington", "Hartlepool", "Middlesbrough", "Redcar and Cleveland",
  "Stockton-on-Tees",
  # Humber Estuary / Lincolnshire
  "East Riding of Yorkshire", "Hull", "North East Lincolnshire",
  "North Lincolnshire", "West Lindsey", "East Lindsey",
  # Norfolk Broads / Norfolk
  "Broadland", "Great Yarmouth", "North Norfolk", "Norwich",
  "South Norfolk", "Breckland", "King's Lynn and West Norfolk",
  # Suffolk
  "East Suffolk", "West Suffolk", "Babergh", "Mid Suffolk", "Ipswich",
  # River Wye / Herefordshire / Gloucestershire / Shropshire
  "Herefordshire", "Forest of Dean", "Monmouthshire",
  # Northumberland / Tyne
  "Northumberland", "Newcastle upon Tyne", "Gateshead",
  "North Tyneside", "South Tyneside", "Sunderland",
  # Others in various catchments
  "County Durham", "Carlisle", "Eden",
  "Cheltenham", "Tewkesbury", "Stroud", "Cotswold",
  "Shropshire", "Telford and Wrekin"
)

treatment_df <- bind_rows(
  tibble(lpa_name = wave1_lpas, wave = 1L, treat_year = 2019L, treat_quarter = "2019-Q2"),
  tibble(lpa_name = wave2_lpas, wave = 2L, treat_year = 2022L, treat_quarter = "2022-Q1")
)

cat("Treatment assignment:\n")
cat("  Wave 1 (2019):", length(wave1_lpas), "LPAs\n")
cat("  Wave 2 (2022):", length(wave2_lpas), "LPAs\n")

# ============================================================
# 2. FETCH MHCLG PS1 PLANNING APPLICATION STATISTICS
# ============================================================
# PS1: Planning applications by district
# Available from: https://www.gov.uk/government/statistical-data-sets/live-tables-on-planning-application-statistics

# Try to download the CSV from gov.uk
# PS1 open data CSV — full historical quarterly series back to Q2 1996
ps1_url <- "https://assets.publishing.service.gov.uk/media/694160e71ec67214e98f2fd7/PS1_data_-_open_data_table__202509_.csv"

ps1_file <- "data/ps1_decisions.csv"
if (!file.exists(ps1_file)) {
  cat("Downloading PS1 planning decisions CSV...\n")
  resp <- request(ps1_url) |>
    req_perform()
  writeBin(resp_body_raw(resp), ps1_file)
  cat("  Downloaded:", file.size(ps1_file), "bytes\n")
}
stopifnot("PS1 download failed" = file.exists(ps1_file) && file.size(ps1_file) > 1000)

# Read the CSV
ps1_raw <- fread(ps1_file)
cat("PS1 raw dimensions:", nrow(ps1_raw), "x", ncol(ps1_raw), "\n")
cat("PS1 columns:", paste(head(names(ps1_raw), 15), collapse = ", "), "\n")

# ============================================================
# 3. FETCH MHCLG LIVE TABLE 122 — NET ADDITIONAL DWELLINGS
# ============================================================
lt122_url <- "https://assets.publishing.service.gov.uk/media/691f395e9c8e8f345bf985d3/Live_Table_122.ods"
lt122_file <- "data/lt122_dwellings.ods"

if (!file.exists(lt122_file)) {
  cat("Downloading Live Table 122...\n")
  resp <- request(lt122_url) |>
    req_perform()
  writeBin(resp_body_raw(resp), lt122_file)
  cat("  Downloaded:", file.size(lt122_file), "bytes\n")
}
stopifnot("LT122 download failed" = file.exists(lt122_file) && file.size(lt122_file) > 1000)

lt122_raw <- readODS::read_ods(lt122_file, sheet = 1, skip = 3)
cat("LT122 raw dimensions:", nrow(lt122_raw), "x", ncol(lt122_raw), "\n")

# ============================================================
# 4. SAVE RAW DATA
# ============================================================
saveRDS(ps1_raw, "data/ps1_raw.rds")
saveRDS(lt122_raw, "data/lt122_raw.rds")
saveRDS(treatment_df, "data/treatment_assignment.rds")

cat("\nData fetch complete. Saved to data/\n")
cat("  ps1_raw.rds:", nrow(ps1_raw), "rows\n")
cat("  lt122_raw.rds:", nrow(lt122_raw), "rows\n")
cat("  treatment_assignment.rds:", nrow(treatment_df), "LPAs\n")
