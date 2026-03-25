# 01_fetch_data.R — Load MaStR solar PV data from downloaded Zenodo export
# Source: open-MaStR, DOI: 10.5281/zenodo.14783581 (snapshot 2025-02-09)

source("00_packages.R")

cat("=== Loading MaStR Solar PV Data ===\n")

RAW_FILE <- "../data/bnetza_open_mastr_2025-02-09/bnetza_mastr_solar_raw.csv"
if (!file.exists(RAW_FILE)) {
  stop("FATAL: MaStR solar CSV not found at ", RAW_FILE,
       "\nDownload from Zenodo DOI: 10.5281/zenodo.14783581 and extract.")
}

# Read only the columns we need (3.7GB file — select columns for efficiency)
cat("Reading CSV (selecting key columns)...\n")
solar <- fread(
  RAW_FILE,
  select = c(
    "Nettonennleistung",             # Net rated capacity (kW)
    "Bruttoleistung",                # Gross capacity (kW)
    "Inbetriebnahmedatum",           # Commissioning date
    "Bundesland",                    # Federal state
    "Lage",                          # Installation type (rooftop/ground-mount)
    "AnzahlModule",                  # Number of modules
    "EinheitBetriebsstatus",         # Operating status
    "ZugeordneteWirkleistungWechselrichter"  # Inverter capacity
  ),
  encoding = "UTF-8",
  showProgress = TRUE
)

cat(sprintf("Raw records loaded: %s\n", format(nrow(solar), big.mark = ",")))

# ---------------------------------------------------------------
# Basic validation — NO simulated data, NO silent fallbacks
# ---------------------------------------------------------------
stopifnot(nrow(solar) > 1000000)  # Expect millions of records
stopifnot("Nettonennleistung" %in% names(solar))
stopifnot("Inbetriebnahmedatum" %in% names(solar))

# Parse commissioning date
solar[, comm_date := as.Date(Inbetriebnahmedatum)]
solar[, comm_year := year(comm_date)]

# Filter to operating units with valid capacity
solar <- solar[EinheitBetriebsstatus == "In Betrieb"]
solar <- solar[!is.na(Nettonennleistung) & Nettonennleistung > 0]
solar <- solar[!is.na(comm_date)]
solar <- solar[comm_year >= 2000 & comm_year <= 2025]

cat(sprintf("After filtering to operating units with valid capacity: %s\n",
            format(nrow(solar), big.mark = ",")))

# Create clean capacity variable in kWp
solar[, capacity_kw := Nettonennleistung]

# Classify installation type
solar[, install_type := fcase(
  grepl("Hausdach|Gebäude|Fassade", Lage, ignore.case = TRUE), "rooftop",
  grepl("Freifläche|Freifla", Lage, ignore.case = TRUE), "ground_mount",
  default = "other"
)]

# Summary statistics
cat("\n=== Data Summary ===\n")
cat(sprintf("Total installations: %s\n", format(nrow(solar), big.mark = ",")))
cat(sprintf("Capacity range: %.3f - %.1f kW\n",
            min(solar$capacity_kw), max(solar$capacity_kw)))
cat(sprintf("Year range: %d - %d\n",
            min(solar$comm_year), max(solar$comm_year)))
cat(sprintf("Bundesländer: %d\n", uniqueN(solar$Bundesland)))

cat("\nInstallation type breakdown:\n")
print(solar[, .N, by = install_type][order(-N)])

cat("\nInstallations by year (recent):\n")
print(solar[comm_year >= 2015, .N, by = comm_year][order(comm_year)])

# Save processed data
OUT_FILE <- "../data/solar_clean.csv"
fwrite(solar[, .(capacity_kw, comm_date, comm_year, Bundesland, install_type,
                  AnzahlModule, Bruttoleistung,
                  ZugeordneteWirkleistungWechselrichter)],
       OUT_FILE)
cat(sprintf("\nSaved clean data to %s (%s rows)\n", OUT_FILE,
            format(nrow(solar), big.mark = ",")))
